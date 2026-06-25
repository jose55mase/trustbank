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
        log.info("[OnlineReward] Tick — serviceId={}, guildId='{}'", serviceId, guildId);

        if (serviceId <= 0) {
            log.info("[OnlineReward] SKIPPED: serviceId is {} (not configured)", serviceId);
            return;
        }

        if (guildId == null || guildId.isBlank()) {
            log.info("[OnlineReward] SKIPPED: guildId is empty or null");
            return;
        }

        // Read config from DB
        EconomyConfig config = economyService.getConfig(guildId);
        if (!config.isEnabled()) {
            log.info("[OnlineReward] SKIPPED: economy disabled for guild '{}'", guildId);
            return;
        }

        int coinsPerCycle = config.getOnlineRewardCoins();
        int intervalMinutes = config.getOnlineRewardIntervalMinutes();
        log.info("[OnlineReward] Config: coins={}, interval={}min, enabled={}", coinsPerCycle, intervalMinutes, config.isEnabled());

        if (coinsPerCycle <= 0 || intervalMinutes <= 0) {
            log.info("[OnlineReward] SKIPPED: coinsPerCycle={}, intervalMinutes={}", coinsPerCycle, intervalMinutes);
            return;
        }

        // Check if enough time has passed since last reward
        long now = System.currentTimeMillis();
        long intervalMs = intervalMinutes * 60_000L;
        long elapsed = now - lastRewardTime;
        if (elapsed < intervalMs) {
            log.info("[OnlineReward] NOT YET: {}ms elapsed, need {}ms ({}min)", elapsed, intervalMs, intervalMinutes);
            return;
        }
        lastRewardTime = now;

        log.info("[OnlineReward] === REWARD CYCLE START === Querying players from serviceId={}", serviceId);

        try {
            List<PlayerDto> onlinePlayers = nitradoApiClient.getPlayers(serviceId);

            if (onlinePlayers == null || onlinePlayers.isEmpty()) {
                log.info("[OnlineReward] No players returned from API.");
                return;
            }

            log.info("[OnlineReward] Found {} players from API", onlinePlayers.size());

            int rewarded = 0;

            for (PlayerDto player : onlinePlayers) {
                log.info("[OnlineReward] Player: name='{}', online={}", player.name(), player.online());

                if (!player.online()) {
                    log.info("[OnlineReward]   -> Skipped (not online)");
                    continue;
                }

                // Look up linked profile by DayZ player name
                Optional<PlayerProfile> profileOpt = playerLinkService.findByDayzName(player.name());
                if (profileOpt.isEmpty()) {
                    log.info("[OnlineReward]   -> Skipped (not linked)");
                    continue; // Player not linked, skip
                }

                PlayerProfile profile = profileOpt.get();
                log.info("[OnlineReward]   -> LINKED! discordId={}, balance={}", profile.getDiscordId(), profile.getBalance());

                try {
                    economyService.creditCoins(
                            profile,
                            coinsPerCycle,
                            TransactionType.ONLINE_REWARD,
                            "Recompensa por estar conectado"
                    );
                    rewarded++;
                    log.info("[OnlineReward]   -> REWARDED {} coins. New balance={}", coinsPerCycle, profile.getBalance());
                } catch (Exception e) {
                    log.warn("[OnlineReward]   -> FAILED to reward: {}", e.getMessage());
                }
            }

            log.info("[OnlineReward] === CYCLE DONE === Rewarded {}/{} players with {} coins each.",
                    rewarded, onlinePlayers.size(), coinsPerCycle);

        } catch (Exception e) {
            log.warn("[OnlineReward] Error checking online players: {}", e.getMessage(), e);
        }
    }
}
