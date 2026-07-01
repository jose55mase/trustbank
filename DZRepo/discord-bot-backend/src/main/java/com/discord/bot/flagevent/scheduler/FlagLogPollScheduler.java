package com.discord.bot.flagevent.scheduler;

import com.discord.bot.flagevent.config.FlagEventProperties;
import com.discord.bot.flagevent.model.FlagPollingState;
import com.discord.bot.flagevent.repository.FlagPollingStateRepository;
import com.discord.bot.flagevent.service.FlagEventService;
import com.discord.bot.flagevent.service.FlagSessionManager;
import com.discord.bot.nitrado.exception.NitradoConnectionException;
import com.discord.bot.nitrado.exception.NitradoNotFoundException;
import com.discord.bot.nitrado.service.NitradoApiClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;
import java.time.format.DateTimeParseException;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Scheduled component that polls the DayZ server ADM log for new flag events.
 *
 * <p>On each tick:
 * <ol>
 *   <li>Downloads the server log via {@link NitradoApiClient#getServerLogs(int)}</li>
 *   <li>Loads the {@link FlagPollingState} from the database</li>
 *   <li>Detects server restarts (line count shrinkage or timestamp regression)</li>
 *   <li>Extracts only new lines since the last poll</li>
 *   <li>Passes new lines to {@link FlagEventService#processNewLines(List)}</li>
 *   <li>Updates the polling state with the new line index and timestamp</li>
 * </ol>
 *
 * <p>If the log is unavailable or a connection error occurs, the scheduler logs a
 * warning and retries on the next cycle without modifying stored state.
 */
@Component
public class FlagLogPollScheduler {

    private static final Logger log = LoggerFactory.getLogger(FlagLogPollScheduler.class);

    /** Pattern to extract the timestamp (HH:mm:ss) from the beginning of a log line. */
    private static final Pattern TIMESTAMP_PATTERN = Pattern.compile("^(\\d{2}:\\d{2}:\\d{2})");

    private final NitradoApiClient nitradoApiClient;
    private final FlagPollingStateRepository pollingStateRepository;
    private final FlagEventService flagEventService;
    private final FlagSessionManager flagSessionManager;
    private final FlagEventProperties properties;

    public FlagLogPollScheduler(NitradoApiClient nitradoApiClient,
                                FlagPollingStateRepository pollingStateRepository,
                                FlagEventService flagEventService,
                                FlagSessionManager flagSessionManager,
                                FlagEventProperties properties) {
        this.nitradoApiClient = nitradoApiClient;
        this.pollingStateRepository = pollingStateRepository;
        this.flagEventService = flagEventService;
        this.flagSessionManager = flagSessionManager;
        this.properties = properties;
    }

    /**
     * Main polling method, executed at a fixed delay configured by
     * {@code flagevent.poll-interval-seconds} (default 30 seconds).
     */
    @Scheduled(fixedDelayString = "#{${flagevent.poll-interval-seconds:30} * 1000}")
    @Transactional
    public void pollServerLogs() {
        int serviceId = properties.getNitradoServiceId();
        String guildId = properties.getGuildId();

        if (serviceId <= 0) {
            log.debug("[FlagPoll] Skipped: nitradoServiceId not configured ({})", serviceId);
            return;
        }

        if (guildId == null || guildId.isBlank()) {
            log.debug("[FlagPoll] Skipped: guildId not configured");
            return;
        }

        // Check if the flag event system is enabled
        if (!flagEventService.isEnabled(guildId)) {
            log.debug("[FlagPoll] Skipped: flag event system is disabled for guild '{}'", guildId);
            return;
        }

        // Check for orphaned sessions each tick
        flagSessionManager.checkOrphanedSession();

        // Download log content
        String logContent;
        try {
            logContent = nitradoApiClient.getServerLogs(serviceId);
        } catch (NitradoNotFoundException e) {
            log.warn("[FlagPoll] Log file unavailable for serviceId={}: {}", serviceId, e.getMessage());
            return;
        } catch (NitradoConnectionException e) {
            log.warn("[FlagPoll] Connection error downloading logs for serviceId={}: {}", serviceId, e.getMessage());
            return;
        } catch (Exception e) {
            log.warn("[FlagPoll] Unexpected error downloading logs for serviceId={}: {}", serviceId, e.getMessage());
            return;
        }

        // Handle empty/null log content
        if (logContent == null || logContent.isBlank()) {
            log.warn("[FlagPoll] Log content is empty or null for serviceId={}", serviceId);
            return;
        }

        // Split log into lines
        String[] allLinesArray = logContent.split("\\r?\\n");
        List<String> allLines = Arrays.asList(allLinesArray);

        if (allLines.isEmpty()) {
            log.warn("[FlagPoll] Log file has no lines for serviceId={}", serviceId);
            return;
        }

        // Load polling state from DB
        Optional<FlagPollingState> stateOpt = pollingStateRepository.findByGuildId(guildId);

        List<String> newLines;

        if (stateOpt.isEmpty()) {
            // First run: process entire file from beginning
            log.info("[FlagPoll] No polling state found for guild '{}'. Processing entire log ({} lines).",
                    guildId, allLines.size());
            newLines = allLines;
        } else {
            FlagPollingState state = stateOpt.get();
            int lastLineIndex = state.getLastLineIndex();
            String lastTimestamp = state.getLastTimestamp();

            // Detect server restart
            if (isServerRestarted(lastLineIndex, lastTimestamp, allLines)) {
                log.info("[FlagPoll] Server restart detected for guild '{}'. Resetting state and processing entire log ({} lines).",
                        guildId, allLines.size());
                newLines = allLines;
            } else {
                // Extract new lines from lastLineIndex + 1 to end
                int startIndex = lastLineIndex + 1;
                if (startIndex >= allLines.size()) {
                    // No new lines since last poll
                    log.debug("[FlagPoll] No new lines for guild '{}'. Last index: {}, current size: {}",
                            guildId, lastLineIndex, allLines.size());
                    return;
                }
                newLines = allLines.subList(startIndex, allLines.size());
            }
        }

        // Process new lines
        if (!newLines.isEmpty()) {
            log.info("[FlagPoll] Processing {} new lines for guild '{}'", newLines.size(), guildId);
            flagEventService.processNewLines(newLines);
        }

        // Update polling state
        int newLastLineIndex = allLines.size() - 1;
        String newLastTimestamp = extractTimestamp(allLines.get(newLastLineIndex));

        if (stateOpt.isPresent()) {
            FlagPollingState state = stateOpt.get();
            state.setLastLineIndex(newLastLineIndex);
            state.setLastTimestamp(newLastTimestamp);
            pollingStateRepository.save(state);
        } else {
            FlagPollingState newState = new FlagPollingState(guildId, newLastLineIndex, newLastTimestamp);
            pollingStateRepository.save(newState);
        }

        log.debug("[FlagPoll] Updated polling state for guild '{}': lastLineIndex={}, lastTimestamp='{}'",
                guildId, newLastLineIndex, newLastTimestamp);
    }

    /**
     * Detects a server restart by checking two conditions:
     * <ol>
     *   <li>The stored lastLineIndex exceeds the current line count</li>
     *   <li>The stored lastTimestamp is later than the first line's timestamp</li>
     * </ol>
     *
     * @param lastLineIndex  the previously stored line index
     * @param lastTimestamp  the previously stored timestamp (HH:mm:ss)
     * @param allLines       the current log file lines
     * @return true if a server restart is detected
     */
    boolean isServerRestarted(int lastLineIndex, String lastTimestamp, List<String> allLines) {
        // Condition 1: stored index exceeds current file length
        if (lastLineIndex >= allLines.size()) {
            return true;
        }

        // Condition 2: stored timestamp is later than first line's timestamp
        if (lastTimestamp != null && !lastTimestamp.isBlank()) {
            String firstLineTimestamp = extractTimestamp(allLines.get(0));
            if (firstLineTimestamp != null && !firstLineTimestamp.isBlank()) {
                try {
                    LocalTime storedTime = LocalTime.parse(lastTimestamp);
                    LocalTime firstLineTime = LocalTime.parse(firstLineTimestamp);
                    if (storedTime.isAfter(firstLineTime)) {
                        return true;
                    }
                } catch (DateTimeParseException e) {
                    log.warn("[FlagPoll] Could not parse timestamps for restart detection. " +
                            "Stored: '{}', FirstLine: '{}'", lastTimestamp, firstLineTimestamp);
                }
            }
        }

        return false;
    }

    /**
     * Extracts the HH:mm:ss timestamp from the beginning of a log line.
     *
     * @param line the log line
     * @return the timestamp string, or empty string if not found
     */
    String extractTimestamp(String line) {
        if (line == null || line.isBlank()) {
            return "";
        }
        Matcher matcher = TIMESTAMP_PATTERN.matcher(line.trim());
        if (matcher.find()) {
            return matcher.group(1);
        }
        return "";
    }
}
