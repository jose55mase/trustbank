package com.discord.bot.connection;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for ReconnectionBackoff.
 * Validates: Requirements 2.2, 2.4
 */
class ReconnectionBackoffTest {

    @Test
    void defaultConstructorSetsExpectedDefaults() {
        ReconnectionBackoff backoff = new ReconnectionBackoff();

        assertEquals(1000L, backoff.getBaseDelayMs());
        assertEquals(60000L, backoff.getMaxDelayMs());
        assertEquals(5, backoff.getMaxAttempts());
        assertEquals(0, backoff.getConsecutiveFailures());
    }

    @Test
    void calculateDelayFirstAttemptReturnsBaseDelay() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        // min(1000 * 2^0, 60000) = 1000
        assertEquals(1000L, backoff.calculateDelay(1));
    }

    @Test
    void calculateDelaySecondAttemptDoublesBaseDelay() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        // min(1000 * 2^1, 60000) = 2000
        assertEquals(2000L, backoff.calculateDelay(2));
    }

    @Test
    void calculateDelayThirdAttemptQuadruplesBaseDelay() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        // min(1000 * 2^2, 60000) = 4000
        assertEquals(4000L, backoff.calculateDelay(3));
    }

    @Test
    void calculateDelayIsCappedAtMaxDelay() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        // min(1000 * 2^6, 60000) = min(64000, 60000) = 60000
        assertEquals(60000L, backoff.calculateDelay(7));
    }

    @Test
    void calculateDelayLargeAttemptReturnsCap() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        // Very large attempt should still return maxDelay
        assertEquals(60000L, backoff.calculateDelay(20));
    }

    @Test
    void calculateDelayHandlesOverflow() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        // Attempt 63+ would overflow long; should return maxDelay
        assertEquals(60000L, backoff.calculateDelay(63));
    }

    @Test
    void calculateDelayThrowsForZeroAttempt() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        assertThrows(IllegalArgumentException.class, () -> backoff.calculateDelay(0));
    }

    @Test
    void calculateDelayThrowsForNegativeAttempt() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        assertThrows(IllegalArgumentException.class, () -> backoff.calculateDelay(-1));
    }

    @Test
    void calculateDelayValuesAreStrictlyIncreasingUntilCap() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        long previous = 0;
        for (int attempt = 1; attempt <= 20; attempt++) {
            long delay = backoff.calculateDelay(attempt);
            assertTrue(delay >= previous,
                    "Delay should be non-decreasing: attempt " + attempt +
                    " delay " + delay + " < previous " + previous);
            if (delay < backoff.getMaxDelayMs()) {
                assertTrue(delay > previous,
                        "Delay should be strictly increasing before cap: attempt " + attempt);
            }
            previous = delay;
        }
    }

    @Test
    void recordFailedAttemptIncrementsCounter() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        assertEquals(0, backoff.getConsecutiveFailures());

        backoff.recordFailedAttempt();
        assertEquals(1, backoff.getConsecutiveFailures());

        backoff.recordFailedAttempt();
        assertEquals(2, backoff.getConsecutiveFailures());
    }

    @Test
    void resetAttemptsClearsCounter() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        backoff.recordFailedAttempt();
        backoff.recordFailedAttempt();
        backoff.recordFailedAttempt();
        assertEquals(3, backoff.getConsecutiveFailures());

        backoff.resetAttempts();
        assertEquals(0, backoff.getConsecutiveFailures());
    }

    @Test
    void fiveConsecutiveFailuresLogsCriticalError() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        // Record 5 failures - the 5th should trigger critical error log
        for (int i = 0; i < 5; i++) {
            backoff.recordFailedAttempt();
        }

        assertEquals(5, backoff.getConsecutiveFailures());
    }

    @Test
    void resetAfterCriticalErrorAllowsNewAttempts() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        // Reach critical threshold
        for (int i = 0; i < 5; i++) {
            backoff.recordFailedAttempt();
        }
        assertEquals(5, backoff.getConsecutiveFailures());

        // Reset and verify counter is cleared
        backoff.resetAttempts();
        assertEquals(0, backoff.getConsecutiveFailures());

        // Can record new failures
        backoff.recordFailedAttempt();
        assertEquals(1, backoff.getConsecutiveFailures());
    }

    @Test
    void customParametersAreRespected() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(500L, 30000L, 3);

        assertEquals(500L, backoff.getBaseDelayMs());
        assertEquals(30000L, backoff.getMaxDelayMs());
        assertEquals(3, backoff.getMaxAttempts());

        // min(500 * 2^0, 30000) = 500
        assertEquals(500L, backoff.calculateDelay(1));
        // min(500 * 2^1, 30000) = 1000
        assertEquals(1000L, backoff.calculateDelay(2));
    }

    @Test
    void calculateDelayWithSpecificExamples() {
        ReconnectionBackoff backoff = new ReconnectionBackoff(1000L, 60000L, 5);

        // Verify the full sequence: 1000, 2000, 4000, 8000, 16000, 32000, 60000, 60000...
        assertEquals(1000L, backoff.calculateDelay(1));
        assertEquals(2000L, backoff.calculateDelay(2));
        assertEquals(4000L, backoff.calculateDelay(3));
        assertEquals(8000L, backoff.calculateDelay(4));
        assertEquals(16000L, backoff.calculateDelay(5));
        assertEquals(32000L, backoff.calculateDelay(6));
        assertEquals(60000L, backoff.calculateDelay(7));  // capped
        assertEquals(60000L, backoff.calculateDelay(8));  // still capped
    }
}
