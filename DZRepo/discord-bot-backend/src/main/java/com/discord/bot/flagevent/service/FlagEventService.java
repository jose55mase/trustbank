package com.discord.bot.flagevent.service;

import com.discord.bot.flagevent.config.FlagEventProperties;
import com.discord.bot.flagevent.model.ActiveFlagSession;
import com.discord.bot.flagevent.model.FlagEvent;
import com.discord.bot.flagevent.model.FlagLocation;
import com.discord.bot.flagevent.model.LeaderboardEntry;
import com.discord.bot.flagevent.model.PlayerFlagState;
import com.discord.bot.flagevent.model.PlayerStatus;
import com.discord.bot.flagevent.parser.FlagLogParser;
import com.discord.bot.flagevent.repository.FlagLocationRepository;
import com.discord.bot.flagevent.repository.PlayerFlagStateRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

/**
 * Orchestrator service for the Flag Event System.
 *
 * <p>Coordinates log parsing, position matching, session management, and notifications.
 * Also provides helper methods for Discord slash commands (get/set location, channel,
 * leaderboard, and player status).
 */
@Service
public class FlagEventService {

    private static final Logger log = LoggerFactory.getLogger(FlagEventService.class);

    private final FlagLogParser flagLogParser;
    private final PositionMatcher positionMatcher;
    private final FlagSessionManager flagSessionManager;
    private final FlagLocationRepository flagLocationRepository;
    private final PlayerFlagStateRepository playerFlagStateRepository;
    private final FlagEventProperties properties;

    @Nullable
    private final FlagNotificationService flagNotificationService;

    public FlagEventService(FlagLogParser flagLogParser,
                            PositionMatcher positionMatcher,
                            FlagSessionManager flagSessionManager,
                            FlagLocationRepository flagLocationRepository,
                            PlayerFlagStateRepository playerFlagStateRepository,
                            FlagEventProperties properties,
                            @Nullable FlagNotificationService flagNotificationService) {
        this.flagLogParser = flagLogParser;
        this.positionMatcher = positionMatcher;
        this.flagSessionManager = flagSessionManager;
        this.flagLocationRepository = flagLocationRepository;
        this.playerFlagStateRepository = playerFlagStateRepository;
        this.properties = properties;
        this.flagNotificationService = flagNotificationService;
    }

    /**
     * Processes new log lines: parse → filter by position match → handle session → notify.
     *
     * <p>If no FlagLocation is configured, logs a WARN and discards all events.
     * If no notification channel is configured, logs a WARN and skips notifications.
     *
     * @param lines the new log lines to process
     */
    @Transactional
    public void processNewLines(List<String> lines) {
        String guildId = properties.getGuildId();

        // Load flag location configuration
        Optional<FlagLocation> locationOpt = flagLocationRepository.findByGuildId(guildId);
        if (locationOpt.isEmpty()) {
            log.warn("No flag location is set for guild {}. Discarding all events.", guildId);
            return;
        }

        FlagLocation location = locationOpt.get();

        // Parse lines into flag events
        List<FlagEvent> events = flagLogParser.parseLines(lines);
        if (events.isEmpty()) {
            return;
        }

        // Determine notification channel
        String channelId = location.getNotificationChannelId();
        boolean canNotify = channelId != null && !channelId.isBlank();
        if (!canNotify) {
            log.warn("No notification channel is set for guild {}. Skipping notifications.", guildId);
        }

        // Process each event that matches the configured location
        for (FlagEvent event : events) {
            if (!positionMatcher.matches(event, location)) {
                continue;
            }

            if ("raised".equals(event.action())) {
                flagSessionManager.handleRaise(event);

                if (canNotify && flagNotificationService != null) {
                    flagNotificationService.sendRaiseNotification(event, channelId);
                }
            } else if ("lowered".equals(event.action())) {
                // Calculate elapsed time before handling lower (session still exists)
                long elapsedSeconds = calculateActiveSessionElapsed();

                flagSessionManager.handleLower(event);

                if (canNotify && flagNotificationService != null) {
                    flagNotificationService.sendLowerNotification(event, elapsedSeconds, channelId);
                }
            }
        }
    }

    // ---- Command helper methods ----

    /**
     * Retrieves the configured flag location for a guild.
     *
     * @param guildId the Discord guild ID
     * @return an Optional containing the FlagLocation, or empty if not configured
     */
    public Optional<FlagLocation> getFlagLocation(String guildId) {
        return flagLocationRepository.findByGuildId(guildId);
    }

    /**
     * Sets or updates the flag location for a guild.
     *
     * @param guildId   the Discord guild ID
     * @param x         the X coordinate (0-15360)
     * @param z         the Z coordinate (0-15360)
     * @param tolerance the position tolerance in meters (1-1000)
     * @return the saved FlagLocation entity
     */
    @Transactional
    public FlagLocation setFlagLocation(String guildId, double x, double z, double tolerance) {
        FlagLocation location = flagLocationRepository.findByGuildId(guildId)
                .orElse(new FlagLocation(guildId, x, z, tolerance));

        location.setCoordX(x);
        location.setCoordZ(z);
        location.setTolerance(tolerance);

        return flagLocationRepository.save(location);
    }

    /**
     * Sets or updates the notification channel for a guild.
     *
     * @param guildId   the Discord guild ID
     * @param channelId the Discord channel ID for notifications
     */
    @Transactional
    public void setChannel(String guildId, String channelId) {
        FlagLocation location = flagLocationRepository.findByGuildId(guildId)
                .orElse(new FlagLocation(guildId, 0, 0, properties.getDefaultTolerance()));

        location.setNotificationChannelId(channelId);
        flagLocationRepository.save(location);
    }

    /**
     * Enables or disables the flag event system for a guild.
     *
     * @param guildId the Discord guild ID
     * @param enabled true to enable, false to disable
     * @return true if the state was changed, false if no location is configured
     */
    @Transactional
    public boolean setEnabled(String guildId, boolean enabled) {
        Optional<FlagLocation> locationOpt = flagLocationRepository.findByGuildId(guildId);
        if (locationOpt.isEmpty()) {
            return false;
        }
        FlagLocation location = locationOpt.get();
        location.setEnabled(enabled);
        flagLocationRepository.save(location);
        return true;
    }

    /**
     * Returns whether the flag event system is enabled for a guild.
     *
     * @param guildId the Discord guild ID
     * @return true if enabled, false otherwise
     */
    public boolean isEnabled(String guildId) {
        return flagLocationRepository.findByGuildId(guildId)
                .map(FlagLocation::isEnabled)
                .orElse(false);
    }

    /**
     * Gets the leaderboard for a guild, sorted by total accumulated time descending.
     * Includes active session elapsed time in calculations.
     *
     * @param guildId the Discord guild ID
     * @param limit   the maximum number of entries to return
     * @return a list of LeaderboardEntry records representing the leaderboard
     */
    public List<LeaderboardEntry> getLeaderboard(String guildId, int limit) {
        List<PlayerFlagState> states = playerFlagStateRepository.findByGuildId(guildId);

        // Determine active session info
        Optional<ActiveFlagSession> activeSession = flagSessionManager.getActiveSession();
        String activePlayerName = activeSession.map(ActiveFlagSession::getPlayerName).orElse(null);
        long activeElapsed = calculateActiveSessionElapsed();

        // Sort: descending by total time, ties broken alphabetically by player name
        AtomicInteger rankCounter = new AtomicInteger(1);
        return states.stream()
                .sorted(Comparator
                        .comparingLong((PlayerFlagState s) -> {
                            long total = s.getAccumulatedSeconds();
                            if (s.getPlayerName().equals(activePlayerName)) {
                                total += activeElapsed;
                            }
                            return total;
                        }).reversed()
                        .thenComparing(PlayerFlagState::getPlayerName))
                .limit(limit)
                .map(s -> {
                    long totalSeconds = s.getAccumulatedSeconds();
                    if (s.getPlayerName().equals(activePlayerName)) {
                        totalSeconds += activeElapsed;
                    }
                    return new LeaderboardEntry(
                            rankCounter.getAndIncrement(),
                            s.getPlayerName(),
                            s.getFlagName(),
                            totalSeconds,
                            formatTime(totalSeconds)
                    );
                })
                .toList();
    }

    /**
     * Gets the dominant flag for a guild — the flag with the highest total accumulated
     * time across all players. Ties are broken alphabetically by flag name.
     *
     * @param guildId the Discord guild ID
     * @return an Optional containing the dominant flag name, or empty if no data exists
     */
    public Optional<String> getDominantFlag(String guildId) {
        List<PlayerFlagState> states = playerFlagStateRepository.findByGuildId(guildId);
        if (states.isEmpty()) {
            return Optional.empty();
        }

        // Determine active session info
        Optional<ActiveFlagSession> activeSession = flagSessionManager.getActiveSession();
        long activeElapsed = calculateActiveSessionElapsed();

        // Sum accumulatedSeconds by flagName, including active session elapsed
        Map<String, Long> flagTotals = states.stream()
                .collect(Collectors.groupingBy(
                        PlayerFlagState::getFlagName,
                        Collectors.summingLong(PlayerFlagState::getAccumulatedSeconds)
                ));

        // Add active session elapsed to the appropriate flag
        if (activeSession.isPresent() && activeElapsed > 0) {
            String activeFlagName = activeSession.get().getFlagName();
            flagTotals.merge(activeFlagName, activeElapsed, Long::sum);
        }

        // Find the flag with the highest total; ties broken alphabetically
        return flagTotals.entrySet().stream()
                .max(Comparator
                        .comparingLong(Map.Entry<String, Long>::getValue)
                        .thenComparing(Map.Entry.<String, Long>comparingByKey().reversed()))
                .map(Map.Entry::getKey);
    }

    /**
     * Gets the status for a specific player in a guild, including total time
     * (with active session elapsed if applicable), flag name, and active status.
     *
     * @param guildId    the Discord guild ID
     * @param playerName the player name to query
     * @return an Optional containing the player's status, or empty if not found
     */
    public Optional<PlayerStatus> getPlayerStatus(String guildId, String playerName) {
        Optional<PlayerFlagState> stateOpt = playerFlagStateRepository.findByGuildId(guildId).stream()
                .filter(s -> s.getPlayerName().equals(playerName))
                .findFirst();

        if (stateOpt.isEmpty()) {
            return Optional.empty();
        }

        PlayerFlagState state = stateOpt.get();
        long totalSeconds = state.getAccumulatedSeconds();
        boolean active = false;

        // Check if this player has an active session
        Optional<ActiveFlagSession> activeSession = flagSessionManager.getActiveSession();
        if (activeSession.isPresent() && activeSession.get().getPlayerName().equals(playerName)) {
            totalSeconds += calculateActiveSessionElapsed();
            active = true;
        }

        return Optional.of(new PlayerStatus(
                state.getPlayerName(),
                state.getFlagName(),
                totalSeconds,
                formatTime(totalSeconds),
                active
        ));
    }

    /**
     * Formats a duration in seconds as HH:MM:SS.
     *
     * @param totalSeconds the total number of seconds to format
     * @return the formatted time string in HH:MM:SS format
     */
    public static String formatTime(long totalSeconds) {
        long hours = totalSeconds / 3600;
        long minutes = (totalSeconds % 3600) / 60;
        long seconds = totalSeconds % 60;
        return String.format("%02d:%02d:%02d", hours, minutes, seconds);
    }

    /**
     * Calculates the elapsed seconds for the current active session, if any.
     *
     * @return elapsed seconds of the active session, or 0 if no active session
     */
    private long calculateActiveSessionElapsed() {
        Optional<ActiveFlagSession> session = flagSessionManager.getActiveSession();
        if (session.isEmpty()) {
            return 0;
        }
        long elapsed = Duration.between(session.get().getStartTime(), LocalDateTime.now()).getSeconds();
        return Math.max(elapsed, 0);
    }
}
