package com.discord.bot.shop.service;

import com.discord.bot.nitrado.service.NitradoApiClient;
import com.discord.bot.shop.model.ShopOrder;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Service responsible for spawning purchased items on the DayZ server
 * using the custom object spawner system (cfggameplay.json + custom/*.json).
 *
 * <p>New strategy:
 * <ol>
 *   <li>On purchase: create a JSON file in custom/ with the items, then register
 *       the file path in cfggameplay.json's objectSpawnersArr.</li>
 *   <li>After restart (items spawned): remove the path from objectSpawnersArr
 *       and delete the custom JSON file.</li>
 * </ol>
 *
 * <p>File naming: {@code custom/shop_{playerName}_{orderId}.json}</p>
 */
@Service
public class ItemSpawnService {

    private static final Logger log = LoggerFactory.getLogger(ItemSpawnService.class);

    private final NitradoApiClient nitradoClient;
    private final ObjectMapper objectMapper;

    @Value("${shop.nitrado.service-id:0}")
    private int serviceId;

    @Value("${shop.nitrado.gameplay-path:/dayzOffline.enoch/cfggameplay.json}")
    private String gameplayFilePath;

    @Value("${shop.nitrado.custom-folder:/dayzOffline.enoch/custom}")
    private String customFolderPath;

    public ItemSpawnService(NitradoApiClient nitradoClient) {
        this.nitradoClient = nitradoClient;
        this.objectMapper = new ObjectMapper().enable(SerializationFeature.INDENT_OUTPUT);
    }

    /**
     * Generates the custom JSON file name for a shopping session.
     * Uses a session ID to group multiple products in the same file.
     *
     * @param playerName the player's DayZ name
     * @param sessionId  unique session identifier
     * @return the file name, e.g. "shop_Macedonia6692_s3.json"
     */
    public String generateFileName(String playerName, long sessionId) {
        String safeName = playerName.replaceAll("[^a-zA-Z0-9_]", "");
        return "shop_" + safeName + "_s" + sessionId + ".json";
    }

    /**
     * Generates the custom JSON file name for a shop order (legacy, for cleanup).
     */
    public String generateFileName(ShopOrder order) {
        String safeName = order.getDayzPlayerName().replaceAll("[^a-zA-Z0-9_]", "");
        return "shop_" + safeName + "_s" + order.getSessionId() + ".json";
    }

    /**
     * Adds items from an order to an existing session file, or creates a new one.
     * If the file already exists on the server, downloads it, appends the new objects, and re-uploads.
     * If it doesn't exist, creates a new file and registers it in cfggameplay.json.
     *
     * @param order     the shop order with items to add
     * @param sessionId the session ID that groups orders into one file
     * @param isNewSession true if this is the first order in the session (create new file)
     */
    public void addToSessionFile(ShopOrder order, long sessionId, boolean isNewSession) {
        if (order == null) {
            return;
        }

        String fileName = generateFileName(order.getDayzPlayerName(), sessionId);
        String filePath = customFolderPath + "/" + fileName;

        try {
            log.info("[ShopSpawn] === ADD TO SESSION s{} (order #{}) ===", sessionId, order.getId());
            log.info("[ShopSpawn] filePath = {}", filePath);
            log.info("[ShopSpawn] isNewSession = {}", isNewSession);

            String jsonContent;

            if (isNewSession) {
                // Create new file with this order's items
                jsonContent = buildCustomJson(order);
            } else {
                // Download existing file and append new items
                try {
                    String existing = nitradoClient.downloadFile(serviceId, filePath);
                    jsonContent = appendToCustomJson(existing, order);
                    log.info("[ShopSpawn] Appended to existing file ({} bytes)", existing.length());
                } catch (Exception downloadEx) {
                    // File doesn't exist yet (maybe cleanup happened), create new
                    log.warn("[ShopSpawn] Could not download existing file, creating new: {}", downloadEx.getMessage());
                    jsonContent = buildCustomJson(order);
                    isNewSession = true;
                }
            }

            log.info("[ShopSpawn] JSON content:\n{}", jsonContent);

            // Upload the file (create or overwrite)
            nitradoClient.uploadFile(serviceId, filePath, jsonContent);
            log.info("[ShopSpawn] Uploaded file: {}", filePath);

            // Register in cfggameplay.json only if it's a new session file
            if (isNewSession) {
                registerInGameplay("custom/" + fileName);
                log.info("[ShopSpawn] Registered {} in cfggameplay.json", fileName);
            }

        } catch (Exception e) {
            log.error("[ShopSpawn] Failed to add order #{} to session s{}: {}", order.getId(), sessionId, e.getMessage(), e);
            throw new ItemSpawnException("Error al preparar pedido: " + e.getMessage(), e);
        }
    }

    /**
     * @deprecated Use {@link #addToSessionFile} instead.
     */
    public void uploadOrderFile(ShopOrder order) {
        addToSessionFile(order, order.getId(), true);
    }

    /**
     * Uploads custom files for all pending orders and registers them in cfggameplay.json.
     *
     * @param pendingOrders the list of orders waiting to be delivered
     */
    public void uploadPendingOrders(List<ShopOrder> pendingOrders) {
        if (pendingOrders == null || pendingOrders.isEmpty()) {
            log.info("[ShopSpawn] No pending orders to upload.");
            return;
        }

        for (ShopOrder order : pendingOrders) {
            try {
                uploadOrderFile(order);
            } catch (Exception e) {
                log.warn("[ShopSpawn] Failed to upload order #{}, will retry: {}", order.getId(), e.getMessage());
            }
        }
    }

    /**
     * Cleans up after delivery: removes the custom JSON file and its entry
     * from cfggameplay.json's objectSpawnersArr.
     *
     * @param order the delivered order to clean up
     */
    public void cleanupOrder(ShopOrder order) {
        if (order == null) {
            return;
        }

        String fileName = generateFileName(order);
        String filePath = customFolderPath + "/" + fileName;

        try {
            // Remove from cfggameplay.json
            unregisterFromGameplay("custom/" + fileName);
            log.info("[ShopSpawn] Unregistered {} from cfggameplay.json", fileName);
        } catch (Exception e) {
            log.warn("[ShopSpawn] Failed to unregister {} from cfggameplay.json: {}", fileName, e.getMessage());
        }

        try {
            // Delete the custom file
            nitradoClient.deleteFile(serviceId, filePath);
            log.info("[ShopSpawn] Deleted custom file: {}", filePath);
        } catch (Exception e) {
            log.warn("[ShopSpawn] Failed to delete file {}: {}", filePath, e.getMessage());
        }
    }

    /**
     * Cleans up all delivered orders, grouped by session.
     * Multiple orders in the same session share one file, so we only
     * delete and unregister once per unique session.
     *
     * @param deliveredOrders the list of orders that have been delivered
     */
    public void cleanupDeliveredOrders(List<ShopOrder> deliveredOrders) {
        if (deliveredOrders == null || deliveredOrders.isEmpty()) {
            return;
        }

        // Group by session to avoid deleting the same file multiple times
        java.util.Set<String> cleanedFiles = new java.util.HashSet<>();

        for (ShopOrder order : deliveredOrders) {
            if (order == null) continue;
            String fileName = generateFileName(order);
            if (cleanedFiles.contains(fileName)) {
                continue; // Already cleaned this session's file
            }
            cleanedFiles.add(fileName);
            cleanupFile(fileName);
        }
    }

    /**
     * Removes a single session file from the server and cfggameplay.json.
     */
    private void cleanupFile(String fileName) {
        String filePath = customFolderPath + "/" + fileName;

        log.info("[ShopSpawn] === CLEANUP FILE '{}' ===", fileName);
        log.info("[ShopSpawn] Full path to delete: {}", filePath);
        log.info("[ShopSpawn] Using serviceId: {}", serviceId);

        try {
            unregisterFromGameplay("custom/" + fileName);
            log.info("[ShopSpawn] ✅ Unregistered {} from cfggameplay.json", fileName);
        } catch (Exception e) {
            log.warn("[ShopSpawn] ⚠️ Failed to unregister {} from cfggameplay.json: {}", fileName, e.getMessage());
        }

        try {
            log.info("[ShopSpawn] Calling nitradoClient.deleteFile({}, '{}')", serviceId, filePath);
            boolean deleted = nitradoClient.deleteFile(serviceId, filePath);
            if (deleted) {
                log.info("[ShopSpawn] ✅ Deleted custom file: {}", filePath);
            } else {
                log.error("[ShopSpawn] ❌ Failed to delete custom file: {} — Check NitradoClient logs above", filePath);
            }
        } catch (Exception e) {
            log.error("[ShopSpawn] ❌ Exception deleting file {}: {}", filePath, e.getMessage(), e);
        }
    }

    /**
     * Builds the custom object spawner JSON content for an order.
     * All items in the order are placed at the same position (the player's location).
     *
     * <p>Format:
     * <pre>
     * {
     *   "Objects": [
     *     {
     *       "name": "DayzClassName",
     *       "pos": [X, Y, Z],
     *       "ypr": [0.0, 0.0, 0.0],
     *       "scale": 1.0,
     *       "enableCEPersistency": 0
     *     }
     *   ]
     * }
     * </pre>
     */
    private String buildCustomJson(ShopOrder order) throws JsonProcessingException {
        List<Map<String, Object>> objects = new ArrayList<>();

        String className = order.getProduct().getDayzClassName();
        int quantity = order.getQuantity();

        // coordX = X, coordY = Y (altitude), coordZ = Z
        double x = order.getCoordX();
        double y = order.getCoordY();
        double z = order.getCoordZ();

        // Create one entry per item quantity (each slightly offset to avoid stacking issues)
        for (int i = 0; i < quantity; i++) {
            Map<String, Object> obj = new LinkedHashMap<>();
            obj.put("name", className);
            // All items spawn at same spot, offset 10 units from player position
            obj.put("pos", List.of(x + 10.0, y, z + 10.0));
            obj.put("ypr", List.of(0.0, 0.0, 0.0));
            obj.put("scale", 1.0);
            obj.put("enableCEPersistency", 0);
            objects.add(obj);
        }

        Map<String, Object> root = new LinkedHashMap<>();
        root.put("Objects", objects);

        return objectMapper.writeValueAsString(root);
    }

    /**
     * Appends new items from an order to an existing custom JSON content.
     * Downloads the existing Objects array and adds the new items to it.
     */
    @SuppressWarnings("unchecked")
    private String appendToCustomJson(String existingContent, ShopOrder order) throws JsonProcessingException {
        Map<String, Object> root = objectMapper.readValue(existingContent, new TypeReference<>() {});

        List<Map<String, Object>> objects = (List<Map<String, Object>>) root.get("Objects");
        if (objects == null) {
            objects = new ArrayList<>();
        } else {
            objects = new ArrayList<>(objects); // mutable copy
        }

        String className = order.getProduct().getDayzClassName();
        int quantity = order.getQuantity();
        double x = order.getCoordX();
        double y = order.getCoordY();
        double z = order.getCoordZ();

        // Offset based on how many objects already exist
        int existingCount = objects.size();
        for (int i = 0; i < quantity; i++) {
            Map<String, Object> obj = new LinkedHashMap<>();
            obj.put("name", className);
            obj.put("pos", List.of(x + 10.0, y, z + 10.0));
            obj.put("ypr", List.of(0.0, 0.0, 0.0));
            obj.put("scale", 1.0);
            obj.put("enableCEPersistency", 0);
            objects.add(obj);
        }

        root.put("Objects", objects);
        return objectMapper.writeValueAsString(root);
    }

    /**
     * Downloads cfggameplay.json, adds the custom file path to objectSpawnersArr
     * (if not already present), and re-uploads the modified file.
     *
     * @param relativePath the path to add (e.g. "custom/shop_player_42.json")
     */
    @SuppressWarnings("unchecked")
    private void registerInGameplay(String relativePath) {
        String content = nitradoClient.downloadFile(serviceId, gameplayFilePath);
        log.info("[ShopSpawn] Downloaded cfggameplay.json ({} bytes)", content != null ? content.length() : 0);
        try {
            Map<String, Object> gameplay = objectMapper.readValue(content, new TypeReference<>() {});

            Map<String, Object> worldsData = (Map<String, Object>) gameplay.get("WorldsData");
            if (worldsData == null) {
                worldsData = new LinkedHashMap<>();
                gameplay.put("WorldsData", worldsData);
            }

            List<String> spawners = (List<String>) worldsData.get("objectSpawnersArr");
            if (spawners == null) {
                spawners = new ArrayList<>();
                worldsData.put("objectSpawnersArr", spawners);
            } else {
                // Make mutable copy if it's an unmodifiable list from Jackson
                spawners = new ArrayList<>(spawners);
                worldsData.put("objectSpawnersArr", spawners);
            }

            // Check if already registered
            if (spawners.contains(relativePath)) {
                log.debug("[ShopSpawn] Path already registered in objectSpawnersArr: {}", relativePath);
                return;
            }

            spawners.add(relativePath);
            log.info("[ShopSpawn] objectSpawnersArr now has {} entries, added: {}", spawners.size(), relativePath);

            String updatedContent = objectMapper.writeValueAsString(gameplay);
            nitradoClient.uploadFile(serviceId, gameplayFilePath, updatedContent);

        } catch (JsonProcessingException e) {
            throw new ItemSpawnException("Error al parsear cfggameplay.json: " + e.getMessage(), e);
        }
    }

    /**
     * Downloads cfggameplay.json, removes the custom file path from objectSpawnersArr,
     * and re-uploads the modified file.
     *
     * @param relativePath the path to remove (e.g. "custom/shop_player_42.json")
     */
    @SuppressWarnings("unchecked")
    private void unregisterFromGameplay(String relativePath) {
        String content = nitradoClient.downloadFile(serviceId, gameplayFilePath);
        try {
            Map<String, Object> gameplay = objectMapper.readValue(content, new TypeReference<>() {});

            Map<String, Object> worldsData = (Map<String, Object>) gameplay.get("WorldsData");
            if (worldsData == null) {
                return;
            }

            List<String> spawners = (List<String>) worldsData.get("objectSpawnersArr");
            if (spawners == null || !spawners.contains(relativePath)) {
                return;
            }

            spawners.remove(relativePath);
            worldsData.put("objectSpawnersArr", spawners);

            String updatedContent = objectMapper.writeValueAsString(gameplay);
            nitradoClient.uploadFile(serviceId, gameplayFilePath, updatedContent);

        } catch (JsonProcessingException e) {
            throw new ItemSpawnException("Error al parsear cfggameplay.json: " + e.getMessage(), e);
        }
    }

    /**
     * Legacy compatibility method.
     */
    public void spawnItem(ShopOrder order) {
        log.info("Order #{} queued for delivery via custom spawner system.", order.getId());
    }

    /**
     * Legacy compatibility — no longer needed with the new system.
     */
    public void restoreOriginalFiles() {
        log.info("[ShopSpawn] restoreOriginalFiles() called — no-op with new custom spawner system.");
    }

    public static class ItemSpawnException extends RuntimeException {
        public ItemSpawnException(String message) { super(message); }
        public ItemSpawnException(String message, Throwable cause) { super(message, cause); }
    }

    /**
     * Scans the custom folder on Nitrado for any shop_*.json files and removes them,
     * also cleaning their entries from cfggameplay.json.
     *
     * @return the number of files cleaned
     */
    public int cleanOrphanedFiles() {
        log.info("[ShopSpawn] === ORPHAN FILE CLEANUP ===");
        log.info("[ShopSpawn] Scanning folder: {} (serviceId={})", customFolderPath, serviceId);
        
        try {
            var files = nitradoClient.listFiles(serviceId, customFolderPath);
            log.info("[ShopSpawn] Found {} total files in custom folder", files.size());
            
            int cleaned = 0;

            for (var file : files) {
                if (file.name() != null && file.name().startsWith("shop_") && file.name().endsWith(".json")) {
                    log.info("[ShopSpawn] Found shop file to clean: {}", file.name());

                    // Remove from cfggameplay.json
                    try {
                        unregisterFromGameplay("custom/" + file.name());
                        log.info("[ShopSpawn] ✅ Unregistered from cfggameplay: {}", file.name());
                    } catch (Exception e) {
                        log.warn("[ShopSpawn] ⚠️ Could not unregister {}: {}", file.name(), e.getMessage());
                    }

                    // Delete file
                    try {
                        String filePath = customFolderPath + "/" + file.name();
                        boolean deleted = nitradoClient.deleteFile(serviceId, filePath);
                        if (deleted) {
                            log.info("[ShopSpawn] ✅ Deleted orphaned file: {}", file.name());
                            cleaned++;
                        } else {
                            log.error("[ShopSpawn] ❌ Failed to delete orphaned file: {}", file.name());
                        }
                    } catch (Exception e) {
                        log.error("[ShopSpawn] ❌ Exception deleting {}: {}", file.name(), e.getMessage());
                    }
                }
            }

            log.info("[ShopSpawn] === ORPHAN CLEANUP COMPLETE: {}/{} files removed ===", cleaned, files.size());
            return cleaned;
        } catch (Exception e) {
            log.error("[ShopSpawn] ❌ Error scanning for orphaned files: {}", e.getMessage(), e);
            return 0;
        }
    }
}
