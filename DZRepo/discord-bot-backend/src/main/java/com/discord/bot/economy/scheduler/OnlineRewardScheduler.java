package com.discord.bot.economy.scheduler;

import com.discord.bot.economy.model.EconomyConfig;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.model.TransactionType;
import com.discord.bot.economy.service.EconomyService;
import com.discord.bot.economy.service.PlayerLinkService;
import com.discord.bot.nitrado.service.NitradoApiClient;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Scheduler that rewards linked players with coins for being connected to the server.
 *
 * <p>Uses server logs to determine who is currently online (tracks connections
 * and disconnections). This works for both PC and Xbox/PS servers since the
 * ADM log format is consistent.</p>
 */
@Component
public class OnlineRewardScheduler {

    private static final Logger log = LoggerFactory.getLogger(OnlineRewardScheduler.class);

    /** Matches: HH:mm:ss | Player "NAME" (id=... pos=<...>) is connected */
    private static final Pattern CONNECT_PATTERN = Pattern.compile(
            "\\| Player \"(.+?)\" \\(id=.+?\\) is connected$"
    );

    /** Matches: HH:mm:ss | Player "NAME" (id=... pos=<...>) has been disconnected */
    private static final Pattern DISCONNECT_PATTERN = Pattern.compile(
            "\\| Player \"(.+?)\" .*has been disconnected$"
    );

    private final NitradoApiClient nitradoApiClient;
    private final PlayerLinkService playerLinkService;
    private final EconomyService economyService;

    @Value("${economy.nitrado.service-id:0}")
    private int serviceId;

    @Value("${economy.guild-id:}")
    private String guildId;

    /** Tracks the last time rewards were given */
    private long lastRewardTime = 0;

    public OnlineRewardScheduler(NitradoApiClient nitradoApiClient,
                                 PlayerLinkService playerLinkService,
                                 EconomyService economyService) {
        this.nitradoApiClient = nitradoApiClient;
        this.playerLinkService = playerLinkService;
        this.economyService = economyService;
    }

    @Scheduled(fixedRate = 60000, initialDelay = 60000)
    public void rewardOnlinePlayers() {
        log.info("[OnlineReward] Tick — serviceId={}, guildId='{}'", serviceId, guildId);

        if (serviceId <= 0) {
            log.info("[OnlineReward] SKIPPED: serviceId is {} (not configured)", serviceId);
            return;
        }

        if (guildId == null || guildId.isBlank()) {
            log.info("[OnlineReward] SKIPPED: guildId is empty");
            return;
        }

        // Read config from DB
        EconomyConfig config = economyService.getConfig(guildId);
        if (!config.isEnabled()) {
            log.info("[OnlineReward] SKIPPED: economy disabled");
            return;
        }

        int coinsPerCycle = config.getOnlineRewardCoins();
        int intervalMinutes = config.getOnlineRewardIntervalMinutes();
        log.info("[OnlineReward] Config: coins={}, interval={}min", coinsPerCycle, intervalMinutes);

        if (coinsPerCycle <= 0 || intervalMinutes <= 0) {
            log.info("[OnlineReward] SKIPPED: coins or interval is 0");
            return;
        }

        // Check if enough time has passed
        long now = System.currentTimeMillis();
        long intervalMs = intervalMinutes * 60_000L;
        long elapsed = now - lastRewardTime;
        if (elapsed < intervalMs) {
            log.info("[OnlineReward] NOT YET: {}s elapsed, need {}s", elapsed / 1000, intervalMs / 1000);
            return;
        }
        lastRewardTime = now;

        log.info("[OnlineReward] === REWARD CYCLE START ===");

        try {
            // Get current log and parse who is online
            String logContent = nitradoApiClient.getServerLogs(serviceId);
            if (logContent == null || logContent.isBlank()) {
                log.info("[OnlineReward] Log content is empty.");
                return;
            }

            Set<String> onlinePlayers = parseOnlinePlayers(logContent);
            log.info("[OnlineReward] Players currently online (from logs): {}", onlinePlayers);

            if (onlinePlayers.isEmpty()) {
                log.info("[OnlineReward] No players online.");
                return;
            }

            int rewarded = 0;

            for (String playerName : onlinePlayers) {
                Optional<PlayerProfile> profileOpt = playerLinkService.findByDayzName(playerName);
                if (profileOpt.isEmpty()) {
                    log.info("[OnlineReward]   '{}' -> not linked, skip", playerName);
                    continue;
                }

                PlayerProfile profile = profileOpt.get();
                log.info("[OnlineReward]   '{}' -> LINKED (balance={})", playerName, profile.getBalance());

                try {
                    economyService.creditCoins(
                            profile,
                            coinsPerCycle,
                            TransactionType.ONLINE_REWARD,
                            "Recompensa por estar conectado"
                    );
                    rewarded++;
                    log.info("[OnlineReward]   '{}' -> +{} coins (new balance={})",
                            playerName, coinsPerCycle, profile.getBalance());
                } catch (Exception e) {
                    log.warn("[OnlineReward]   '{}' -> FAILED: {}", playerName, e.getMessage());
                }
            }

            log.info("[OnlineReward] === CYCLE DONE === Rewarded {}/{} players",
                    rewarded, onlinePlayers.size());

        } catch (Exception e) {
            log.warn("[OnlineReward] Error: {}", e.getMessage(), e);
        }
    }

    /**
     * Parses the server log to determine which players are currently online.
     * Tracks connect/disconnect events — a player is online if they connected
     * and haven't disconnected since.
     *
     * @param logContent the raw ADM log content
     * @return set of player names currently online
     */
    private Set<String> parseOnlinePlayers(String logContent) {
        Set<String> online = new HashSet<>();
        String[] lines = logContent.split("\\r?\\n");

        for (String line : lines) {
            if (line.isBlank()) continue;

            Matcher connectMatcher = CONNECT_PATTERN.matcher(line);
            if (connectMatcher.find()) {
                online.add(connectMatcher.group(1));
                continue;
            }

            Matcher disconnectMatcher = DISCONNECT_PATTERN.matcher(line);
            if (disconnectMatcher.find()) {
                online.remove(disconnectMatcher.group(1));
            }
        }

        return online;
    }
}
