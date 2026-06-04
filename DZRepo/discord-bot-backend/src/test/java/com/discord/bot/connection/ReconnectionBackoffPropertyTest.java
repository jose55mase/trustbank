package com.discord.bot.connection;

import net.jqwik.api.*;
import net.jqwik.api.constraints.IntRange;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Property-based tests for ReconnectionBackoff exponential backoff calculation.
 * Feature: discord-bot-backend, Property 2: Cálculo de backoff exponencial
 *
 * Validates: Requirements 2.2
 */
class ReconnectionBackoffPropertyTest {

    private static final long BASE_DELAY_MS = 1000L;
    private static final long MAX_DELAY_MS = 60000L;

    /**
     * Property 2: For any reconnection attempt n (n >= 1), the calculated delay
     * SHALL follow min(baseDelay * 2^(n-1), maxDelay), producing strictly increasing
     * values until reaching the cap.
     *
     * Sub-property 1: delay == min(1000 * 2^(n-1), 60000)
     *
     * Validates: Requirements 2.2
     */
    @Property(tries = 100)
    void delayFollowsExponentialBackoffFormula(@ForAll @IntRange(min = 1, max = 20) int attempt) {
        // Feature: discord-bot-backend, Property 2: Cálculo de backoff exponencial
        ReconnectionBackoff backoff = new ReconnectionBackoff(BASE_DELAY_MS, MAX_DELAY_MS, 5);

        long actualDelay = backoff.calculateDelay(attempt);
        long expectedDelay = Math.min(BASE_DELAY_MS * (1L << (attempt - 1)), MAX_DELAY_MS);

        assertThat(actualDelay)
                .as("Delay for attempt %d should be min(%d * 2^%d, %d) = %d",
                        attempt, BASE_DELAY_MS, attempt - 1, MAX_DELAY_MS, expectedDelay)
                .isEqualTo(expectedDelay);
    }

    /**
     * Property 2: For n > 1, delay(n) >= delay(n-1) (non-decreasing).
     *
     * Validates: Requirements 2.2
     */
    @Property(tries = 100)
    void delaysAreNonDecreasing(@ForAll @IntRange(min = 2, max = 20) int attempt) {
        // Feature: discord-bot-backend, Property 2: Cálculo de backoff exponencial
        ReconnectionBackoff backoff = new ReconnectionBackoff(BASE_DELAY_MS, MAX_DELAY_MS, 5);

        long currentDelay = backoff.calculateDelay(attempt);
        long previousDelay = backoff.calculateDelay(attempt - 1);

        assertThat(currentDelay)
                .as("Delay for attempt %d (%d) should be >= delay for attempt %d (%d)",
                        attempt, currentDelay, attempt - 1, previousDelay)
                .isGreaterThanOrEqualTo(previousDelay);
    }

    /**
     * Property 2: For n where delay < maxDelay, delay(n) > delay(n-1) (strictly increasing before cap).
     *
     * Validates: Requirements 2.2
     */
    @Property(tries = 100)
    void delaysAreStrictlyIncreasingBeforeCap(@ForAll @IntRange(min = 2, max = 20) int attempt) {
        // Feature: discord-bot-backend, Property 2: Cálculo de backoff exponencial
        ReconnectionBackoff backoff = new ReconnectionBackoff(BASE_DELAY_MS, MAX_DELAY_MS, 5);

        long currentDelay = backoff.calculateDelay(attempt);
        long previousDelay = backoff.calculateDelay(attempt - 1);

        if (currentDelay < MAX_DELAY_MS) {
            assertThat(currentDelay)
                    .as("Delay for attempt %d (%d) should be strictly greater than delay for attempt %d (%d) before reaching cap",
                            attempt, currentDelay, attempt - 1, previousDelay)
                    .isGreaterThan(previousDelay);
        }
    }
}
