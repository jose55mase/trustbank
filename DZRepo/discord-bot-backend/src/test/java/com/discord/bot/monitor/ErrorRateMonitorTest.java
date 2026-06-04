package com.discord.bot.monitor;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for ErrorRateMonitor.
 * Validates: Requirements 7.4
 */
class ErrorRateMonitorTest {

    private static Clock fixedClock(Instant instant) {
        return Clock.fixed(instant, ZoneId.of("UTC"));
    }

    @Test
    void noErrorsReturnsZeroCount() {
        ErrorRateMonitor monitor = new ErrorRateMonitor(fixedClock(Instant.now()));
        assertEquals(0, monitor.getErrorsInLastMinute());
    }

    @Test
    void singleErrorRecordedAndCounted() {
        Instant now = Instant.now();
        ErrorRateMonitor monitor = new ErrorRateMonitor(fixedClock(now));

        monitor.recordError();

        assertEquals(1, monitor.getErrorsInLastMinute());
    }

    @Test
    void multipleErrorsWithinWindowAreCounted() {
        Instant now = Instant.now();
        ErrorRateMonitor monitor = new ErrorRateMonitor(fixedClock(now));

        for (int i = 0; i < 5; i++) {
            monitor.recordError();
        }

        assertEquals(5, monitor.getErrorsInLastMinute());
    }

    @Test
    void errorsOlderThan60SecondsAreNotCounted() {
        Instant start = Instant.parse("2024-01-15T10:00:00Z");

        // Record errors at start time
        MutableClock clock = new MutableClock(start);
        ErrorRateMonitor monitor = new ErrorRateMonitor(clock);

        monitor.recordError();
        monitor.recordError();
        monitor.recordError();

        // Advance clock past the 60-second window
        clock.setInstant(start.plus(Duration.ofSeconds(61)));

        assertEquals(0, monitor.getErrorsInLastMinute());
    }

    @Test
    void errorsAtExactly60SecondsAreStillCounted() {
        Instant start = Instant.parse("2024-01-15T10:00:00Z");

        MutableClock clock = new MutableClock(start);
        ErrorRateMonitor monitor = new ErrorRateMonitor(clock);

        monitor.recordError();

        // Advance clock to exactly 60 seconds
        clock.setInstant(start.plus(Duration.ofSeconds(60)));

        assertEquals(1, monitor.getErrorsInLastMinute());
    }

    @Test
    void thresholdNotExceededNoAlert() {
        Instant now = Instant.now();
        ErrorRateMonitor monitor = new ErrorRateMonitor(fixedClock(now));

        // Record exactly 10 errors (threshold is > 10, so 10 should NOT trigger)
        for (int i = 0; i < 10; i++) {
            monitor.recordError();
        }

        assertEquals(10, monitor.getErrorsInLastMinute());
        // No exception or error expected - alert is only logged, not thrown
    }

    @Test
    void thresholdExceededTriggersAlert() {
        Instant now = Instant.now();
        ErrorRateMonitor monitor = new ErrorRateMonitor(fixedClock(now));

        // Record 11 errors (exceeds threshold of 10)
        for (int i = 0; i < 11; i++) {
            monitor.recordError();
        }

        assertEquals(11, monitor.getErrorsInLastMinute());
        // Alert is logged at ERROR level - verified by property test
    }

    @Test
    void oldEntriesAreCleanedUp() {
        Instant start = Instant.parse("2024-01-15T10:00:00Z");

        MutableClock clock = new MutableClock(start);
        ErrorRateMonitor monitor = new ErrorRateMonitor(clock);

        // Record 5 errors at start
        for (int i = 0; i < 5; i++) {
            monitor.recordError();
        }

        // Advance 30 seconds and record 3 more
        clock.setInstant(start.plus(Duration.ofSeconds(30)));
        for (int i = 0; i < 3; i++) {
            monitor.recordError();
        }

        // At 30 seconds, all 8 should be counted
        assertEquals(8, monitor.getErrorsInLastMinute());

        // Advance to 61 seconds - first 5 should be expired
        clock.setInstant(start.plus(Duration.ofSeconds(61)));
        assertEquals(3, monitor.getErrorsInLastMinute());

        // Advance to 91 seconds - all should be expired
        clock.setInstant(start.plus(Duration.ofSeconds(91)));
        assertEquals(0, monitor.getErrorsInLastMinute());
    }

    @Test
    void defaultConstructorUsesSystemClock() {
        ErrorRateMonitor monitor = new ErrorRateMonitor();
        assertEquals(0, monitor.getErrorsInLastMinute());

        monitor.recordError();
        assertEquals(1, monitor.getErrorsInLastMinute());
    }

    /**
     * A mutable clock for testing time-dependent behavior.
     */
    static class MutableClock extends Clock {
        private Instant instant;
        private final ZoneId zone = ZoneId.of("UTC");

        MutableClock(Instant instant) {
            this.instant = instant;
        }

        void setInstant(Instant instant) {
            this.instant = instant;
        }

        @Override
        public ZoneId getZone() {
            return zone;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return instant;
        }
    }
}
