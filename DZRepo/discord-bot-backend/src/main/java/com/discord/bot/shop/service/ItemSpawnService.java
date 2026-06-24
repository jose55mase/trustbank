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

    @Value("${shop.nitrado.gameplay-path:/dayzOffline.chernarusplus/cfggameplay.json}")
    private String gameplayFilePath;

    @Value("${shop.nitrado.custom-folder:/dayzOffline.chernarusplus/custom}")
    private String customFolderPath;

    public ItemSpawnService(NitradoApiClient nitradoClient) {
        this.nitradoClient = nitradoClient;
        this.objectMapper = new ObjectMapper().enable(SerializationFeature.INDENT_OUTPUT);
    }

    /**
     * Generates the custom JSON file name for a shop order.
     *
     * @param order the shop order
     * @return the file name (without path prefix), e.g. "shop_xXTORRESXx9224_42.json"
     */
    public String generateFileName(ShopOrder order) {
        String safeName = order.getDayzPlayerName().replaceAll("[^a-zA-Z0-9_]", "");
        return "shop_" + safeName + "_" + order.getId() + ".json";
    }

    /**
     * Uploads a custom object spawner JSON for the given orders and registers it
     * in cfggameplay.json's objectSpawnersArr.
     *
     * <p>All pending orders are consolidated into a single file per order to allow
     * individual cleanup after delivery.
     *
     * @param order the shop order to prepare for delivery
     */
    public void uploadOrderFile(ShopOrder order) {
        if (order == null) {
            return;
        }

        try {
            // Step 1: Generate the custom JSON content
            String jsonContent = buildCustomJson(order);
            String fileName = generateFileName(order);
            String filePath = customFolderPath + "/" + fileName;

            // Step 2: Upload the custom JSON file
            nitradoClient.uploadFile(serviceId, filePath, jsonContent);
            log.info("[ShopSpawn] Uploaded custom file: {}", filePath);

            // Step 3: Register in cfggameplay.json
            registerInGameplay("custom/" + fileName);
            log.info("[ShopSpawn] Registered {} in cfggameplay.json objectSpawnersArr", fileName);

        } catch (Exception e) {
            log.error("[ShopSpawn] Failed to upload order #{}: {}", order.getId(), e.getMessage(), e);
            throw new ItemSpawnException("Error al preparar pedido: " + e.getMessage(), e);
        }
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
     * Cleans up all delivered orders.
     *
     * @param deliveredOrders the list of orders that have been delivered
     */
    public void cleanupDeliveredOrders(List<ShopOrder> deliveredOrders) {
        if (deliveredOrders == null || deliveredOrders.isEmpty()) {
            return;
        }

        for (ShopOrder order : deliveredOrders) {
            cleanupOrder(order);
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
            // Offset each item slightly so they don't stack on top of each other
            obj.put("pos", List.of(x + (i * 0.5), y, z + (i * 0.5)));
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
     * Downloads cfggameplay.json, adds the custom file path to objectSpawnersArr
     * (if not already present), and re-uploads the modified file.
     *
     * @param relativePath the path to add (e.g. "custom/shop_player_42.json")
     */
    @SuppressWarnings("unchecked")
    private void registerInGameplay(String relativePath) {
        String content = nitradoClient.downloadFile(serviceId, gameplayFilePath);
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
            }

            // Check if already registered
            if (spawners.contains(relativePath)) {
                log.debug("[ShopSpawn] Path already registered in objectSpawnersArr: {}", relativePath);
                return;
            }

            spawners.add(relativePath);
            worldsData.put("objectSpawnersArr", spawners);

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
}
