package com.discord.bot.economy.scheduler;

import com.discord.bot.economy.model.ZombieKillEvent;
import com.discord.bot.economy.parser.ZombieKillParser;
import com.discord.bot.economy.service.ZombieKillRewardService;
import com.discord.bot.nitrado.exception.NitradoApiException;
import com.discord.bot.nitrado.exception.NitradoConnectionException;
import com.discord.bot.nitrado.service.NitradoApiClient;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Scheduled task that periodically downloads DayZ server logs from Nitrado,
 * parses zombie kill events, filters duplicates, and delegates reward processing.
 *
 * <p>Runs every 5 minutes (300,000 ms). Maintains in-memory state of the last
 * processed event (timestamp + lineIndex) to avoid processing duplicates across
 * polling cycles.</p>
 *
 * <p>All Nitrado communication errors are caught and logged without re-throwing,
 * ensuring the scheduler continues operating on the next cycle.</p>
 */
@Component
public class ZombieKillScheduler {

    private static final Logger log = LoggerFactory.getLogger(ZombieKillScheduler.class);

    private final NitradoApiClient nitradoApiClient;
    private final ZombieKillParser zombieKillParser;
    private final ZombieKillRewardService zombieKillRewardService;

    private final int serviceId;
    private final String guildId;

    /** Timestamp of the last processed event (HH:mm:ss format). */
    private String lastProcessedTimestamp;

    /** Line index of the last processed event within the log file. */
    private int lastProcessedLineIndex = -1;

    public ZombieKillScheduler(NitradoApiClient nitradoApiClient,
                               ZombieKillParser zombieKillParser,
                               ZombieKillRewardService zombieKillRewardService,
                               @Value("${economy.nitrado.service-id:0}") int serviceId,
                               @Value("${economy.guild-id:}") String guildId) {
        this.nitradoApiClient = nitradoApiClient;
        this.zombieKillParser = zombieKillParser;
        this.zombieKillRewardService = zombieKillRewardService;
        this.serviceId = serviceId;
        this.guildId = guildId;
    }

    /**
     * Executes the zombie kill poll cycle every 5 minutes.
     *
     * <ol>
     *   <li>Downloads server logs via Nitrado API.</li>
     *   <li>Skips the cycle if log content is null or empty.</li>
     *   <li>Parses zombie kill events from the log content.</li>
     *   <li>Filters out previously processed events using timestamp + lineIndex state.</li>
     *   <li>Sorts new events in chronological order.</li>
     *   <li>Delegates processing to {@link ZombieKillRewardService}.</li>
     *   <li>Updates the last processed state.</li>
     * </ol>
     */
    @Scheduled(fixedRate = 300000)
    public void scheduledZombieKillPoll() {
        if (serviceId <= 0) {
            log.debug("Zombie kill scheduler skipped: no service ID configured.");
            return;
        }

        try {
            String logContent = nitradoApiClient.getServerLogs(serviceId);

            if (logContent == null || logContent.isBlank()) {
                log.debug("Zombie kill scheduler: log content is empty, skipping cycle.");
                return;
            }

            List<ZombieKillEvent> allEvents = zombieKillParser.parseZombieKills(logContent);

            if (allEvents.isEmpty()) {
                log.debug("Zombie kill scheduler: no zombie kill events found in log.");
                return;
            }

            List<ZombieKillEvent> newEvents = filterNewEvents(allEvents);

            if (newEvents.isEmpty()) {
                log.debug("Zombie kill scheduler: no new zombie kill events to process.");
                return;
            }

            // Sort new events in chronological order (timestamp, then lineIndex)
            newEvents.sort(Comparator.comparing(ZombieKillEvent::timestamp)
                    .thenComparingInt(ZombieKillEvent::lineIndex));

            log.info("Zombie kill scheduler: processing {} new events (total parsed: {}).",
                    newEvents.size(), allEvents.size());

            zombieKillRewardService.processZombieKills(newEvents, guildId);

            // Update last processed state to the last event in the sorted list
            ZombieKillEvent lastEvent = newEvents.get(newEvents.size() - 1);
            lastProcessedTimestamp = lastEvent.timestamp();
            lastProcessedLineIndex = lastEvent.lineIndex();

            log.debug("Zombie kill scheduler: updated last processed state to timestamp='{}', lineIndex={}.",
                    lastProcessedTimestamp, lastProcessedLineIndex);

        } catch (NitradoApiException | NitradoConnectionException e) {
            log.warn("Error descargando logs para zombie kills: {}", e.getMessage());
        } catch (Exception e) {
            log.error("Error inesperado en zombie kill scheduler: {}", e.getMessage(), e);
        }
    }

    /**
     * Filters events to keep only those that are newer than the last processed event.
     * An event is considered new if its timestamp is greater than the last processed timestamp,
     * or if the timestamps are equal and its lineIndex is greater than the last processed lineIndex.
     *
     * @param allEvents all parsed events from the current log
     * @return a mutable list of new (unprocessed) events
     */
    private List<ZombieKillEvent> filterNewEvents(List<ZombieKillEvent> allEvents) {
        if (lastProcessedTimestamp == null) {
            // First cycle: all events are new
            return new ArrayList<>(allEvents);
        }

        return allEvents.stream()
                .filter(event -> {
                    int cmp = event.timestamp().compareTo(lastProcessedTimestamp);
                    if (cmp > 0) {
                        return true;
                    }
                    return cmp == 0 && event.lineIndex() > lastProcessedLineIndex;
                })
                .collect(Collectors.toCollection(ArrayList::new));
    }

    // ── Package-private accessors for testing ──

    String getLastProcessedTimestamp() {
        return lastProcessedTimestamp;
    }

    int getLastProcessedLineIndex() {
        return lastProcessedLineIndex;
    }

    void setLastProcessedTimestamp(String timestamp) {
        this.lastProcessedTimestamp = timestamp;
    }

    void setLastProcessedLineIndex(int lineIndex) {
        this.lastProcessedLineIndex = lineIndex;
    }
}
