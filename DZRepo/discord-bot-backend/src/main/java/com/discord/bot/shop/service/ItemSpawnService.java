package com.discord.bot.shop.service;

import com.discord.bot.nitrado.service.NitradoApiClient;
import com.discord.bot.shop.model.ShopOrder;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Service responsible for spawning purchased items on the DayZ server
 * by uploading the item data to a dedicated JSON file via Nitrado API.
 */
@Service
public class ItemSpawnService {

    private static final Logger log = LoggerFactory.getLogger(ItemSpawnService.class);

    private final NitradoApiClient nitradoClient;
    private final ObjectMapper objectMapper;

    @Value("${shop.nitrado.service-id:0}")
    private int serviceId;

    @Value("${shop.nitrado.spawn-file-path:/dayzOffline.chernarusplus/custom/shop_spawns.json}")
    private String spawnFilePath;

    public ItemSpawnService(NitradoApiClient nitradoClient) {
        this.nitradoClient = nitradoClient;
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Spawns the purchased item(s) on the DayZ server at the order's coordinates.
     * Downloads the current shop_spawns.json, appends the new item(s), and uploads it back.
     *
     * @param order the shop order containing product, quantity, and coordinates
     * @throws ItemSpawnException if the spawn operation fails
     */
    public void spawnItem(ShopOrder order) {
        String dayzClassName = order.getProduct().getDayzClassName();
        if (dayzClassName == null || dayzClassName.isBlank()) {
            throw new ItemSpawnException("El producto '" + order.getProduct().getName()
                    + "' no tiene un className de DayZ configurado.");
        }

        try {
            ObjectNode root = downloadOrCreateSpawnFile();
            ArrayNode objects = (ArrayNode) root.get("Objects");

            for (int i = 0; i < order.getQuantity(); i++) {
                ObjectNode item = buildItemObject(dayzClassName, order.getCoordX(), order.getCoordY());
                objects.add(item);
            }

            String updatedJson = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(root);
            nitradoClient.uploadFile(serviceId, spawnFilePath, updatedJson);

            log.info("Spawned {}x '{}' at ({}, {}) for order #{}",
                    order.getQuantity(), dayzClassName, order.getCoordX(), order.getCoordY(), order.getId());

        } catch (ItemSpawnException e) {
            throw e;
        } catch (Exception e) {
            log.error("Failed to spawn item for order #{}: {}", order.getId(), e.getMessage(), e);
            throw new ItemSpawnException("Error al spawnear item en el servidor: " + e.getMessage(), e);
        }
    }

    private ObjectNode downloadOrCreateSpawnFile() {
        try {
            String content = nitradoClient.downloadFile(serviceId, spawnFilePath);
            if (content != null && !content.isBlank()) {
                JsonNode node = objectMapper.readTree(content);
                if (node.isObject() && node.has("Objects")) {
                    return (ObjectNode) node;
                }
            }
        } catch (Exception e) {
            log.info("shop_spawns.json not found or empty, creating new one");
        }

        ObjectNode root = objectMapper.createObjectNode();
        root.set("Objects", objectMapper.createArrayNode());
        return root;
    }

    private ObjectNode buildItemObject(String className, double coordX, double coordY) {
        ObjectNode item = objectMapper.createObjectNode();
        item.put("name", className);

        ArrayNode pos = objectMapper.createArrayNode();
        pos.add(coordX);
        pos.add(0.0); // height — DayZ adjusts to terrain
        pos.add(coordY);
        item.set("pos", pos);

        ArrayNode ypr = objectMapper.createArrayNode();
        ypr.add(0.0);
        ypr.add(0.0);
        ypr.add(0.0);
        item.set("ypr", ypr);

        item.put("scale", 1.0);
        item.put("enableCEPersistency", 0);

        return item;
    }

    public static class ItemSpawnException extends RuntimeException {
        public ItemSpawnException(String message) { super(message); }
        public ItemSpawnException(String message, Throwable cause) { super(message, cause); }
    }
}
