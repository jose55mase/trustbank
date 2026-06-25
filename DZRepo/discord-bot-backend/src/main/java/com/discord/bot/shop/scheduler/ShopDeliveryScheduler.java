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
 * Scheduler that monitors server status and cleans up shop event files
 * after the server has restarted and loaded the items.
 *
 * <p>Event files are uploaded immediately when orders are placed.
 * This scheduler only handles cleanup: when the server comes back online
 * after being offline, it marks orders as DELIVERED and clears the event files
 * so items don't respawn on the next restart.</p>
 */
@Component
public class ShopDeliveryScheduler {

    private static final Logger log = LoggerFactory.getLogger(ShopDeliveryScheduler.class);

    private final NitradoApiClient nitradoApiClient;
    private final ShopService shopService;

    @Value("${economy.nitrado.service-id:${shop.nitrado.service-id:0}}")
    private int serviceId;

    /** Tracks whether the server was online in the last check. */
    private Boolean lastKnownOnline = null;

    public ShopDeliveryScheduler(NitradoApiClient nitradoApiClient, ShopService shopService) {
        this.nitradoApiClient = nitradoApiClient;
        this.shopService = shopService;
    }

    /**
     * Checks server status every 60 seconds.
     * When server transitions from offline → online, confirms deliveries and clears files.
     */
    @Scheduled(fixedRate = 60000)
    public void checkServerAndCleanup() {
        if (serviceId <= 0) {
            log.info("[ShopDelivery] SKIPPED: serviceId={} (not configured)", serviceId);
            return;
        }

        boolean currentlyOnline;
        try {
            GameServerDto status = nitradoApiClient.getServerStatus(serviceId);
            currentlyOnline = "started".equalsIgnoreCase(status.status());
            log.debug("[ShopDelivery] Server status: '{}', online={}", status.status(), currentlyOnline);
        } catch (Exception e) {
            log.debug("[ShopDelivery] Could not check server status: {}", e.getMessage());
            return;
        }

        // First run — check if there are pending orders that should have been delivered
        if (lastKnownOnline == null) {
            lastKnownOnline = currentlyOnline;
            if (currentlyOnline) {
                // Bot just started and server is online — check for stale pending orders
                List<ShopOrder> pending = shopService.getPendingOrders();
                if (!pending.isEmpty()) {
                    log.info("[ShopDelivery] Bot startup: server online with {} pending orders. Cleaning up...", pending.size());
                    confirmAndCleanup();
                }
            }
            return;
        }

        // Server came back ONLINE after being offline
        if (!lastKnownOnline && currentlyOnline) {
            log.info("[ShopDelivery] Server transitioned OFFLINE → ONLINE. Cleaning up...");
            confirmAndCleanup();
        }

        lastKnownOnline = currentlyOnline;
    }

    /**
     * Marks pending orders as DELIVERED and cleans up custom spawn files.
     * Called when the server comes back online (items have already spawned).
     */
    private void confirmAndCleanup() {
        try {
            List<ShopOrder> pending = shopService.getPendingOrders();
            if (pending.isEmpty()) {
                log.info("[ShopDelivery] No pending orders to confirm.");
                return;
            }

            log.info("[ShopDelivery] Found {} pending orders to clean up:", pending.size());
            for (ShopOrder order : pending) {
                log.info("[ShopDelivery]   Order #{} — player='{}', sessionId={}",
                        order.getId(), order.getDayzPlayerName(), order.getSessionId());
            }

            shopService.confirmDelivery();
            log.info("[ShopDelivery] ✅ Confirmed {} orders and cleaned up custom spawn files.", pending.size());
        } catch (Exception e) {
            log.error("[ShopDelivery] ❌ Failed to confirm deliveries: {}", e.getMessage(), e);
        }
    }
}
