package com.discord.bot.monitor;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentLinkedDeque;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Monitors error rates using a circular queue of timestamps.
 * Emits an ERROR-level alert when the error count exceeds 10 errors per minute.
 *
 * Validates: Requirements 7.4
 */
@Component
public class ErrorRateMonitor {

    private static final Logger logger = LoggerFactory.getLogger(ErrorRateMonitor.class);
    private static final int ERROR_THRESHOLD = 10;
    private static final Duration WINDOW = Duration.ofSeconds(60);

    private final ConcurrentLinkedDeque<Instant> errorTimestamps = new ConcurrentLinkedDeque<>();
    private final Clock clock;

    /**
     * Default constructor using system UTC clock.
     */
    public ErrorRateMonitor() {
        this(Clock.systemUTC());
    }

    /**
     * Constructor with injectable clock for testability.
     *
     * @param clock the clock to use for timestamps
     */
    public ErrorRateMonitor(Clock clock) {
        this.clock = clock;
    }

    /**
     * Records an error by adding the current timestamp to the queue.
     * After recording, checks if the error rate exceeds the threshold
     * and emits an ERROR-level alert if so.
     */
    public void recordError() {
        Instant now = clock.instant();
        errorTimestamps.addLast(now);
        cleanupOldEntries(now);

        int count = getErrorsInLastMinute();
        if (count > ERROR_THRESHOLD) {
            logger.error("Tasa de errores elevada: {} errores en el último minuto", count);
        }
    }

    /**
     * Returns the number of errors recorded in the last 60 seconds.
     * Also cleans up entries older than the window.
     *
     * @return the count of errors in the last minute
     */
    public int getErrorsInLastMinute() {
        Instant cutoff = clock.instant().minus(WINDOW);
        cleanupOldEntries(clock.instant());

        int count = 0;
        for (Instant timestamp : errorTimestamps) {
            if (!timestamp.isBefore(cutoff)) {
                count++;
            }
        }
        return count;
    }

    /**
     * Removes timestamps older than the 60-second window from the front of the deque.
     */
    private void cleanupOldEntries(Instant now) {
        Instant cutoff = now.minus(WINDOW);
        while (!errorTimestamps.isEmpty()) {
            Instant oldest = errorTimestamps.peekFirst();
            if (oldest != null && oldest.isBefore(cutoff)) {
                errorTimestamps.pollFirst();
            } else {
                break;
            }
        }
    }
}
