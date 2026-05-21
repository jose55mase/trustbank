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
 * using the event system (events.xml + cfgeventspawns.xml).
 *
 * <p>Instead of using custom JSON files, this service generates two XML files:
 * <ul>
 *   <li>{@code db/shop_events.xml} — defines what items to spawn</li>
 *   <li>{@code shop_eventspawns.xml} — defines where to spawn them (with auto terrain height)</li>
 * </ul>
 *
 * <p>The DayZ server reads these files on startup and spawns items at the specified
 * coordinates with automatic terrain height adjustment (a="-1").
 * After delivery, the files are cleared so items don't respawn on next restart.</p>
 */
@Service
public class ItemSpawnService {

    private static final Logger log = LoggerFactory.getLogger(ItemSpawnService.class);

    private final NitradoApiClient nitradoClient;

    @Value("${shop.nitrado.service-id:0}")
    private int serviceId;

    @Value("${shop.nitrado.events-path:/dayzOffline.chernarusplus/db/shop_events.xml}")
    private String eventsFilePath;

    @Value("${shop.nitrado.eventspawns-path:/dayzOffline.chernarusplus/shop_eventspawns.xml}")
    private String eventSpawnsFilePath;

    public ItemSpawnService(NitradoApiClient nitradoClient) {
        this.nitradoClient = nitradoClient;
    }

    /**
     * Uploads the shop event files with all pending orders so they spawn on next server restart.
     *
     * @param pendingOrders the list of orders waiting to be delivered
     * @throws ItemSpawnException if the upload fails
     */
    public void uploadPendingOrders(List<ShopOrder> pendingOrders) {
        if (pendingOrders == null || pendingOrders.isEmpty()) {
            log.info("No pending orders to upload. Uploading empty shop event files.");
            uploadEmptyFiles();
            return;
        }

        try {
            String eventsXml = generateEventsXml(pendingOrders);
            String eventSpawnsXml = generateEventSpawnsXml(pendingOrders);

            nitradoClient.uploadFile(serviceId, eventsFilePath, eventsXml);
            nitradoClient.uploadFile(serviceId, eventSpawnsFilePath, eventSpawnsXml);

            log.info("Uploaded shop event files with {} pending orders.", pendingOrders.size());
        } catch (Exception e) {
            log.error("Failed to upload shop event files: {}", e.getMessage(), e);
            throw new ItemSpawnException("Error al subir archivos de eventos de tienda: " + e.getMessage(), e);
        }
    }

    /**
     * Uploads empty event files to clear all shop spawns (call after items are delivered).
     */
    public void uploadEmptyFiles() {
        try {
            String emptyEvents = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<events>\n</events>\n";
            String emptySpawns = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<eventposdef>\n</eventposdef>\n";

            nitradoClient.uploadFile(serviceId, eventsFilePath, emptyEvents);
            nitradoClient.uploadFile(serviceId, eventSpawnsFilePath, emptySpawns);

            log.info("Uploaded empty shop event files (cleared spawns).");
        } catch (Exception e) {
            log.warn("Failed to upload empty shop event files: {}", e.getMessage());
        }
    }

    /**
     * Legacy method kept for compatibility — now just marks the order for batch processing.
     * The actual spawn happens when uploadPendingOrders is called before a server restart.
     */
    public void spawnItem(ShopOrder order) {
        // Items are now spawned via the event system on server restart.
        // This method is a no-op; the order stays PENDING until batch upload + restart.
        log.info("Order #{} queued for delivery via event system (will spawn on next restart).",
                order.getId());
    }

    /**
     * Generates the shop_events.xml content with one event per order.
     * Each event spawns the item with lifetime=3600 (1 hour), no restock, fixed position.
     */
    private String generateEventsXml(List<ShopOrder> orders) {
        StringBuilder sb = new StringBuilder();
        sb.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n");
        sb.append("<events>\n");

        for (ShopOrder order : orders) {
            String eventName = "ShopOrder_" + order.getId();
            String className = order.getProduct().getDayzClassName();
            int qty = order.getQuantity();

            sb.append("  <event name=\"").append(eventName).append("\">\n");
            sb.append("    <nominal>").append(qty).append("</nominal>\n");
            sb.append("    <min>").append(qty).append("</min>\n");
            sb.append("    <max>").append(qty).append("</max>\n");
            sb.append("    <lifetime>3600</lifetime>\n");
            sb.append("    <restock>0</restock>\n");
            sb.append("    <saferadius>0</saferadius>\n");
            sb.append("    <distanceradius>0</distanceradius>\n");
            sb.append("    <cleanupradius>200</cleanupradius>\n");
            sb.append("    <flags deletable=\"0\" init_random=\"0\" remove_damaged=\"0\"/>\n");
            sb.append("    <position>fixed</position>\n");
            sb.append("    <limit>child</limit>\n");
            sb.append("    <active>1</active>\n");
            sb.append("    <children>\n");
            sb.append("      <child lootmax=\"0\" lootmin=\"0\" max=\"")
              .append(qty).append("\" min=\"").append(qty)
              .append("\" type=\"").append(className).append("\"/>\n");
            sb.append("    </children>\n");
            sb.append("  </event>\n");
        }

        sb.append("</events>\n");
        return sb.toString();
    }

    /**
     * Generates the shop_eventspawns.xml content with positions for each order.
     * Uses a="-1" so DayZ automatically adjusts height to terrain.
     */
    private String generateEventSpawnsXml(List<ShopOrder> orders) {
        StringBuilder sb = new StringBuilder();
        sb.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n");
        sb.append("<eventposdef>\n");

        for (ShopOrder order : orders) {
            String eventName = "ShopOrder_" + order.getId();

            sb.append("  <event name=\"").append(eventName).append("\">\n");
            sb.append("    <pos x=\"").append(order.getCoordX())
              .append("\" z=\"").append(order.getCoordY())
              .append("\" a=\"-1\"/>\n");
            sb.append("  </event>\n");
        }

        sb.append("</eventposdef>\n");
        return sb.toString();
    }

    public static class ItemSpawnException extends RuntimeException {
        public ItemSpawnException(String message) { super(message); }
        public ItemSpawnException(String message, Throwable cause) { super(message, cause); }
    }
}
