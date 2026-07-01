package com.discord.bot.flagevent.service;

import com.discord.bot.flagevent.config.FlagEventProperties;
import com.discord.bot.flagevent.model.ActiveFlagSession;
import com.discord.bot.flagevent.model.FlagEvent;
import com.discord.bot.flagevent.model.PlayerFlagState;
import com.discord.bot.flagevent.repository.ActiveFlagSessionRepository;
import com.discord.bot.flagevent.repository.PlayerFlagStateRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Optional;

/**
 * Manages flag session lifecycle: creating sessions on raise events,
 * ending sessions on lower events, and accumulating elapsed time to PlayerFlagState.
 *
 * Only one active session per guild is allowed at a time. A new raise implicitly
 * ends the previous session if one exists.
 */
@Service
public class FlagSessionManager {

    private static final Logger log = LoggerFactory.getLogger(FlagSessionManager.class);
    private static final long ORPHANED_SESSION_THRESHOLD_HOURS = 24;

    private final ActiveFlagSessionRepository activeSessionRepository;
    private final PlayerFlagStateRepository playerFlagStateRepository;
    private final FlagEventProperties properties;

    public FlagSessionManager(ActiveFlagSessionRepository activeSessionRepository,
                              PlayerFlagStateRepository playerFlagStateRepository,
                              FlagEventProperties properties) {
        this.activeSessionRepository = activeSessionRepository;
        this.playerFlagStateRepository = playerFlagStateRepository;
        this.properties = properties;
    }

    /**
     * Handles a matched flag raise event. If no active session exists, creates a new one.
     * If an active session exists for a different player or flag, ends the current session,
     * accumulates elapsed time, and creates a new session.
     *
     * @param event the flag raise event
     */
    @Transactional
    public void handleRaise(FlagEvent event) {
        String guildId = properties.getGuildId();
        Optional<ActiveFlagSession> existingSession = activeSessionRepository.findByGuildId(guildId);

        if (existingSession.isPresent()) {
            ActiveFlagSession session = existingSession.get();

            // If same player and same flag, treat as duplicate raise — ignore
            if (session.getPlayerName().equals(event.playerName())
                    && session.getFlagName().equals(event.flagName())) {
                return;
            }

            // End existing session and accumulate time
            LocalDateTime eventDateTime = toLocalDateTime(event.timestamp());
            long elapsedSeconds = Duration.between(session.getStartTime(), eventDateTime).getSeconds();
            if (elapsedSeconds < 0) {
                elapsedSeconds = 0;
            }
            accumulateTime(guildId, session.getPlayerName(), session.getFlagName(), elapsedSeconds);
            activeSessionRepository.delete(session);
        }

        // Create new session
        LocalDateTime startTime = toLocalDateTime(event.timestamp());
        ActiveFlagSession newSession = new ActiveFlagSession(guildId, event.playerName(), event.flagName(), startTime);
        activeSessionRepository.save(newSession);
    }

    /**
     * Handles a matched flag lower event. Validates the event matches the active session
     * (player name + flag name). If it matches, ends the session and accumulates elapsed time.
     * If there's a mismatch, logs a WARN and ignores the event.
     *
     * @param event the flag lower event
     */
    @Transactional
    public void handleLower(FlagEvent event) {
        String guildId = properties.getGuildId();
        Optional<ActiveFlagSession> existingSession = activeSessionRepository.findByGuildId(guildId);

        if (existingSession.isEmpty()) {
            log.warn("Received lower event but no active session exists for guild {}. " +
                    "Player: {}, Flag: {}", guildId, event.playerName(), event.flagName());
            return;
        }

        ActiveFlagSession session = existingSession.get();

        // Validate that lower event matches active session
        if (!session.getPlayerName().equals(event.playerName())
                || !session.getFlagName().equals(event.flagName())) {
            log.warn("Lower event mismatch for guild {}. Active session: player='{}', flag='{}'. " +
                            "Event: player='{}', flag='{}'. Ignoring.",
                    guildId, session.getPlayerName(), session.getFlagName(),
                    event.playerName(), event.flagName());
            return;
        }

        // End session and accumulate time
        LocalDateTime eventDateTime = toLocalDateTime(event.timestamp());
        long elapsedSeconds = Duration.between(session.getStartTime(), eventDateTime).getSeconds();
        if (elapsedSeconds < 0) {
            elapsedSeconds = 0;
        }
        accumulateTime(guildId, session.getPlayerName(), session.getFlagName(), elapsedSeconds);
        activeSessionRepository.delete(session);
    }

    /**
     * Returns the currently active flag session for the configured guild, or empty if none.
     *
     * @return an Optional containing the active session, or empty
     */
    public Optional<ActiveFlagSession> getActiveSession() {
        return activeSessionRepository.findByGuildId(properties.getGuildId());
    }

    /**
     * Checks for orphaned sessions (open > 24 hours) and logs a warning.
     * This method is intended to be called during poll cycle checks.
     */
    public void checkOrphanedSession() {
        Optional<ActiveFlagSession> session = activeSessionRepository.findByGuildId(properties.getGuildId());
        if (session.isPresent()) {
            LocalDateTime startTime = session.get().getStartTime();
            Duration duration = Duration.between(startTime, LocalDateTime.now());
            if (duration.toHours() >= ORPHANED_SESSION_THRESHOLD_HOURS) {
                log.warn("Potentially orphaned session detected for guild {}. " +
                                "Player: '{}', Flag: '{}', started at: {}, open for {} hours.",
                        properties.getGuildId(),
                        session.get().getPlayerName(),
                        session.get().getFlagName(),
                        startTime,
                        duration.toHours());
            }
        }
    }

    /**
     * Converts a LocalTime to a LocalDateTime using today's date.
     */
    private LocalDateTime toLocalDateTime(LocalTime time) {
        return LocalDateTime.of(LocalDate.now(), time);
    }

    /**
     * Accumulates elapsed seconds to the player's flag state.
     * Creates a new PlayerFlagState record if one doesn't exist.
     */
    private void accumulateTime(String guildId, String playerName, String flagName, long elapsedSeconds) {
        PlayerFlagState state = playerFlagStateRepository
                .findByGuildIdAndPlayerNameAndFlagName(guildId, playerName, flagName)
                .orElse(new PlayerFlagState(guildId, playerName, flagName, 0));

        state.setAccumulatedSeconds(state.getAccumulatedSeconds() + elapsedSeconds);
        playerFlagStateRepository.save(state);
    }
}
