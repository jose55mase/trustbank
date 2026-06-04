package com.discord.bot.shop.service;

import com.discord.bot.nitrado.service.NitradoApiClient;
import com.discord.bot.shop.model.ShopOrder;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service responsible for spawning purchased items on the DayZ server
 * by injecting events into the main events.xml and cfgeventspawns.xml files.
 *
 * <p>Strategy:
 * <ol>
 *   <li>On purchase: download original files, append shop events, upload modified files</li>
 *   <li>After restart (items spawned): upload the original files back (removes shop events)</li>
 * </ol>
 *
 * <p>Event names use the format {@code Item_ShopOrder_{id}} to match DayZ's naming convention.</p>
 */
@Service
public class ItemSpawnService {

    private static final Logger log = LoggerFactory.getLogger(ItemSpawnService.class);

    private final NitradoApiClient nitradoClient;

    @Value("${shop.nitrado.service-id:0}")
    private int serviceId;

    @Value("${shop.nitrado.events-path:/dayzOffline.chernarusplus/db/events.xml}")
    private String eventsFilePath;

    @Value("${shop.nitrado.eventspawns-path:/dayzOffline.chernarusplus/cfgeventspawns.xml}")
    private String eventSpawnsFilePath;

    /** Cached original content of events.xml (before shop modifications). */
    private String originalEventsContent;

    /** Cached original content of cfgeventspawns.xml (before shop modifications). */
    private String originalEventSpawnsContent;

    public ItemSpawnService(NitradoApiClient nitradoClient) {
        this.nitradoClient = nitradoClient;
    }

    /**
     * Downloads the original files, appends shop events for all pending orders, and uploads.
     *
     * @param pendingOrders the list of orders waiting to be delivered
     */
    public void uploadPendingOrders(List<ShopOrder> pendingOrders) {
        if (pendingOrders == null || pendingOrders.isEmpty()) {
            log.info("[ShopSpawn] No pending orders to upload.");
            return;
        }

        try {
            // Download and cache originals (only if not already cached)
            if (originalEventsContent == null) {
                originalEventsContent = nitradoClient.downloadFile(serviceId, eventsFilePath);
            }
            if (originalEventSpawnsContent == null) {
                originalEventSpawnsContent = nitradoClient.downloadFile(serviceId, eventSpawnsFilePath);
            }

            // Generate modified files with shop events appended
            String modifiedEvents = injectShopEvents(originalEventsContent, pendingOrders);
            String modifiedSpawns = injectShopSpawns(originalEventSpawnsContent, pendingOrders);

            // Upload modified files
            nitradoClient.uploadFile(serviceId, eventsFilePath, modifiedEvents);
            nitradoClient.uploadFile(serviceId, eventSpawnsFilePath, modifiedSpawns);

            log.info("[ShopSpawn] Uploaded {} shop events to server files.", pendingOrders.size());
        } catch (Exception e) {
            log.error("[ShopSpawn] Failed to upload shop events: {}", e.getMessage(), e);
            throw new ItemSpawnException("Error al subir eventos de tienda: " + e.getMessage(), e);
        }
    }

    /**
     * Restores the original files (without shop events) after server restart.
     * This prevents items from respawning on subsequent restarts.
     */
    public void restoreOriginalFiles() {
        try {
            if (originalEventsContent != null) {
                nitradoClient.uploadFile(serviceId, eventsFilePath, originalEventsContent);
                log.info("[ShopSpawn] Restored original events.xml");
            }
            if (originalEventSpawnsContent != null) {
                nitradoClient.uploadFile(serviceId, eventSpawnsFilePath, originalEventSpawnsContent);
                log.info("[ShopSpawn] Restored original cfgeventspawns.xml");
            }
            // Clear cache so next cycle downloads fresh originals
            originalEventsContent = null;
            originalEventSpawnsContent = null;
        } catch (Exception e) {
            log.error("[ShopSpawn] Failed to restore original files: {}", e.getMessage());
        }
    }

    /**
     * Injects shop event entries before the closing </events> tag.
     */
    private String injectShopEvents(String original, List<ShopOrder> orders) {
        StringBuilder shopEvents = new StringBuilder();

        for (ShopOrder order : orders) {
            String eventName = "Item_ShopOrder_" + order.getId();
            String className = order.getProduct().getDayzClassName();
            int qty = order.getQuantity();

            shopEvents.append("  <event name=\"").append(eventName).append("\">\n");
            shopEvents.append("    <nominal>").append(qty).append("</nominal>\n");
            shopEvents.append("    <min>").append(qty).append("</min>\n");
            shopEvents.append("    <max>").append(qty).append("</max>\n");
            shopEvents.append("    <lifetime>3600</lifetime>\n");
            shopEvents.append("    <restock>0</restock>\n");
            shopEvents.append("    <saferadius>0</saferadius>\n");
            shopEvents.append("    <distanceradius>0</distanceradius>\n");
            shopEvents.append("    <cleanupradius>200</cleanupradius>\n");
            shopEvents.append("    <flags deletable=\"0\" init_random=\"0\" remove_damaged=\"0\"/>\n");
            shopEvents.append("    <position>fixed</position>\n");
            shopEvents.append("    <limit>child</limit>\n");
            shopEvents.append("    <active>1</active>\n");
            shopEvents.append("    <children>\n");
            shopEvents.append("      <child lootmax=\"0\" lootmin=\"0\" max=\"")
                      .append(qty).append("\" min=\"").append(qty)
                      .append("\" type=\"").append(className).append("\"/>\n");
            shopEvents.append("    </children>\n");
            shopEvents.append("  </event>\n");
        }

        // Insert before </events>
        return original.replace("</events>", shopEvents.toString() + "</events>");
    }

    /**
     * Injects shop spawn positions before the closing </eventposdef> tag.
     */
    private String injectShopSpawns(String original, List<ShopOrder> orders) {
        StringBuilder shopSpawns = new StringBuilder();

        for (ShopOrder order : orders) {
            String eventName = "Item_ShopOrder_" + order.getId();

            shopSpawns.append("  <event name=\"").append(eventName).append("\">\n");
            shopSpawns.append("    <pos x=\"").append(order.getCoordX())
                      .append("\" z=\"").append(order.getCoordY())
                      .append("\" a=\"-1\"/>\n");
            shopSpawns.append("  </event>\n");
        }

        // Insert before </eventposdef>
        return original.replace("</eventposdef>", shopSpawns.toString() + "</eventposdef>");
    }

    /**
     * Legacy method — kept for compatibility. Orders are now batch-processed.
     */
    public void spawnItem(ShopOrder order) {
        log.info("Order #{} queued for delivery via event system.", order.getId());
    }

    public static class ItemSpawnException extends RuntimeException {
        public ItemSpawnException(String message) { super(message); }
        public ItemSpawnException(String message, Throwable cause) { super(message, cause); }
    }
}
