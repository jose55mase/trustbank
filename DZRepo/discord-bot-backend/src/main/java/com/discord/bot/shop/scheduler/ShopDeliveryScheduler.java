package com.discord.bot.shop.scheduler;

import com.discord.bot.nitrado.dto.GameServerDto;
import com.discord.bot.nitrado.service.NitradoApiClient;
import com.discord.bot.shop.model.ShopOrder;
import com.discord.bot.shop.service.ShopService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Scheduler that automatically manages shop deliveries around server restarts.
 *
 * <p>Monitors the DayZ server status every 60 seconds. When it detects the server
 * has stopped or is restarting, it uploads pending orders to the event files.
 * When the server comes back online, it confirms the deliveries and clears the files.</p>
 *
 * <p>State machine:
 * <ul>
 *   <li>ONLINE → server running, orders accumulate as PENDING</li>
 *   <li>OFFLINE detected → upload event files with pending orders (prepareDelivery)</li>
 *   <li>ONLINE detected after OFFLINE → confirm deliveries (confirmDelivery)</li>
 * </ul>
 */
@Component
public class ShopDeliveryScheduler {

    private static final Logger log = LoggerFactory.getLogger(ShopDeliveryScheduler.class);

    private final NitradoApiClient nitradoApiClient;
    private final ShopService shopService;

    @Value("${shop.nitrado.service-id:0}")
    private int serviceId;

    /** Tracks whether the server was online in the last check. */
    private Boolean lastKnownOnline = null;

    /** Whether we already uploaded files for this offline cycle. */
    private boolean filesUploaded = false;

    public ShopDeliveryScheduler(NitradoApiClient nitradoApiClient, ShopService shopService) {
        this.nitradoApiClient = nitradoApiClient;
        this.shopService = shopService;
    }

    /**
     * Checks server status every 60 seconds and manages delivery lifecycle.
     */
    @Scheduled(fixedRate = 60000)
    public void checkServerAndManageDeliveries() {
        if (serviceId <= 0) {
            return;
        }

        boolean currentlyOnline;
        try {
            GameServerDto status = nitradoApiClient.getServerStatus(serviceId);
            currentlyOnline = "started".equalsIgnoreCase(status.status());
        } catch (Exception e) {
            log.debug("Could not check server status for shop delivery: {}", e.getMessage());
            return;
        }

        // First run — just record the state
        if (lastKnownOnline == null) {
            lastKnownOnline = currentlyOnline;
            // If server is already online on first check, upload pending orders
            // so they're ready for the next restart
            if (currentlyOnline) {
                uploadPendingIfNeeded();
            }
            return;
        }

        // Server went OFFLINE (was online, now it's not)
        if (lastKnownOnline && !currentlyOnline) {
            log.info("[ShopDelivery] Server went offline. Uploading pending orders for next startup...");
            uploadPendingIfNeeded();
            lastKnownOnline = false;
        }

        // Server came back ONLINE (was offline, now it's online)
        if (!lastKnownOnline && currentlyOnline) {
            log.info("[ShopDelivery] Server is back online. Confirming deliveries...");
            confirmDeliveriesIfNeeded();
            lastKnownOnline = true;
            filesUploaded = false;
        }
    }

    private void uploadPendingIfNeeded() {
        if (filesUploaded) {
            return;
        }

        try {
            List<ShopOrder> pending = shopService.getPendingOrders();
            if (pending.isEmpty()) {
                log.debug("[ShopDelivery] No pending orders to upload.");
                return;
            }

            shopService.prepareDelivery();
            filesUploaded = true;
            log.info("[ShopDelivery] Uploaded {} pending orders to event files.", pending.size());
        } catch (Exception e) {
            log.error("[ShopDelivery] Failed to upload pending orders: {}", e.getMessage());
        }
    }

    private void confirmDeliveriesIfNeeded() {
        try {
            List<ShopOrder> pending = shopService.getPendingOrders();
            if (pending.isEmpty()) {
                log.debug("[ShopDelivery] No pending orders to confirm.");
                return;
            }

            shopService.confirmDelivery();
            log.info("[ShopDelivery] Confirmed delivery of {} orders.", pending.size());
        } catch (Exception e) {
            log.error("[ShopDelivery] Failed to confirm deliveries: {}", e.getMessage());
        }
    }
}
