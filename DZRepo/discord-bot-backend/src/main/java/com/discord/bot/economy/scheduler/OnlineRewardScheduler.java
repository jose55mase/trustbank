package com.discord.bot.economy.scheduler;

import com.discord.bot.economy.model.EconomyConfig;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.model.TransactionType;
import com.discord.bot.economy.service.EconomyService;
import com.discord.bot.economy.service.PlayerLinkService;
import com.discord.bot.nitrado.dto.PlayerDto;
import com.discord.bot.nitrado.service.NitradoApiClient;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

/**
 * Scheduler that rewards linked players with coins for being connected to the server.
 *
 * <p>Every configured interval (default: 5 minutes), queries Nitrado for the list
 * of online players. For each player that is linked (has a PlayerProfile),
 * credits them with the configured amount of coins.</p>
 *
 * <p>Configuration:
 * <ul>
 *   <li>{@code economy.online-reward.coins} — coins awarded per cycle (default: 5)</li>
 *   <li>{@code economy.online-reward.interval-ms} — interval between rewards in ms (default: 300000 = 5 min)</li>
 *   <li>{@code economy.nitrado.service-id} — the Nitrado service ID to query</li>
 * </ul>
 */
@Component
public class OnlineRewardScheduler {

    private static final Logger log = LoggerFactory.getLogger(OnlineRewardScheduler.class);

    private final NitradoApiClient nitradoApiClient;
    private final PlayerLinkService playerLinkService;
    private final EconomyService economyService;

    @Value("${economy.nitrado.service-id:0}")
    private int serviceId;

    /** Tracks the last time rewards were given to avoid running more frequently than configured */
    private long lastRewardTime = 0;

    @Value("${economy.guild-id:}")
    private String guildId;

    public OnlineRewardScheduler(NitradoApiClient nitradoApiClient,
                                 PlayerLinkService playerLinkService,
                                 EconomyService economyService) {
        this.nitradoApiClient = nitradoApiClient;
        this.playerLinkService = playerLinkService;
        this.economyService = economyService;
    }

    /**
     * Runs every minute. Checks if it's time to reward based on the configured interval,
     * then queries online players and rewards linked ones.
     */
    @Scheduled(fixedRate = 60000, initialDelay = 60000)
    public void rewardOnlinePlayers() {
        if (serviceId <= 0) {
            log.debug("[OnlineReward] Skipped: no service ID configured.");
            return;
        }

        if (guildId == null || guildId.isBlank()) {
            log.debug("[OnlineReward] Skipped: no guild ID configured.");
            return;
        }

        // Read config from DB
        EconomyConfig config = economyService.getConfig(guildId);
        if (!config.isEnabled()) {
            log.debug("[OnlineReward] Skipped: economy is disabled for guild '{}'.", guildId);
            return;
        }

        int coinsPerCycle = config.getOnlineRewardCoins();
        int intervalMinutes = config.getOnlineRewardIntervalMinutes();

        if (coinsPerCycle <= 0 || intervalMinutes <= 0) {
            log.debug("[OnlineReward] Skipped: reward coins or interval is 0.");
            return;
        }

        // Check if enough time has passed since last reward
        long now = System.currentTimeMillis();
        long intervalMs = intervalMinutes * 60_000L;
        if ((now - lastRewardTime) < intervalMs) {
            return; // Not time yet
        }
        lastRewardTime = now;

        try {
            List<PlayerDto> onlinePlayers = nitradoApiClient.getPlayers(serviceId);

            if (onlinePlayers == null || onlinePlayers.isEmpty()) {
                log.debug("[OnlineReward] No players online.");
                return;
            }

            int rewarded = 0;

            for (PlayerDto player : onlinePlayers) {
                if (!player.online()) {
                    continue;
                }

                // Look up linked profile by DayZ player name
                Optional<PlayerProfile> profileOpt = playerLinkService.findByDayzName(player.name());
                if (profileOpt.isEmpty()) {
                    continue; // Player not linked, skip
                }

                PlayerProfile profile = profileOpt.get();

                try {
                    economyService.creditCoins(
                            profile,
                            coinsPerCycle,
                            TransactionType.ONLINE_REWARD,
                            "Recompensa por estar conectado"
                    );
                    rewarded++;
                } catch (Exception e) {
                    log.warn("[OnlineReward] Failed to reward player '{}': {}",
                            player.name(), e.getMessage());
                }
            }

            if (rewarded > 0) {
                log.info("[OnlineReward] Rewarded {} linked players with {} coins each.",
                        rewarded, coinsPerCycle);
            }

        } catch (Exception e) {
            log.warn("[OnlineReward] Error checking online players: {}", e.getMessage());
        }
    }
}
