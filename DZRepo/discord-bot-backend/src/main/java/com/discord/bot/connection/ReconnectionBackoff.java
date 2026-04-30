package com.discord.bot.connection;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Implements exponential backoff logic for reconnection attempts.
 * <p>
 * Formula: min(baseDelay * 2^(n-1), maxDelay)
 * <p>
 * Tracks consecutive failed attempts and logs a critical error
 * after reaching the configured maximum attempts (default: 5).
 * <p>
 * Validates: Requirements 2.2, 2.4
 */
@Component
public class ReconnectionBackoff {

    private static final Logger logger = LoggerFactory.getLogger(ReconnectionBackoff.class);

    private final long baseDelayMs;
    private final long maxDelayMs;
    private final int maxAttempts;
    private int consecutiveFailures;

    /**
     * Creates a ReconnectionBackoff with default values:
     * baseDelayMs=1000, maxDelayMs=60000, maxAttempts=5.
     */
    public ReconnectionBackoff() {
        this(1000L, 60000L, 5);
    }

    /**
     * Creates a ReconnectionBackoff with the specified parameters.
     *
     * @param baseDelayMs base delay in milliseconds
     * @param maxDelayMs  maximum delay cap in milliseconds
     * @param maxAttempts maximum attempts before logging critical error
     */
    public ReconnectionBackoff(long baseDelayMs, long maxDelayMs, int maxAttempts) {
        this.baseDelayMs = baseDelayMs;
        this.maxDelayMs = maxDelayMs;
        this.maxAttempts = maxAttempts;
        this.consecutiveFailures = 0;
    }

    /**
     * Calculates the delay for a given attempt number using exponential backoff.
     * <p>
     * Formula: min(baseDelay * 2^(attempt-1), maxDelay)
     *
     * @param attempt the attempt number (1-based)
     * @return the delay in milliseconds
     * @throws IllegalArgumentException if attempt is less than 1
     */
    public long calculateDelay(int attempt) {
        if (attempt < 1) {
            throw new IllegalArgumentException("Attempt number must be >= 1, got: " + attempt);
        }

        // For very large exponents, the shift itself overflows or the multiplication will
        if (attempt - 1 >= Long.SIZE - 1) {
            return maxDelayMs;
        }

        long power = 1L << (attempt - 1);

        // Check if multiplication would overflow
        if (power > maxDelayMs / baseDelayMs) {
            return maxDelayMs;
        }

        long delay = baseDelayMs * power;
        return Math.min(delay, maxDelayMs);
    }

    /**
     * Records a failed reconnection attempt. Increments the consecutive failure
     * counter and logs a critical error if the count reaches maxAttempts.
     */
    public void recordFailedAttempt() {
        consecutiveFailures++;
        logger.warn("Reconnection attempt {} failed", consecutiveFailures);

        if (consecutiveFailures >= maxAttempts) {
            logger.error("CRITICAL: Reconnection failed after {} consecutive attempts", consecutiveFailures);
        }
    }

    /**
     * Resets the consecutive failure counter. Should be called on successful reconnection.
     */
    public void resetAttempts() {
        if (consecutiveFailures > 0) {
            logger.info("Reconnection successful, resetting failure counter from {}", consecutiveFailures);
        }
        consecutiveFailures = 0;
    }

    /**
     * Returns the current number of consecutive failures.
     *
     * @return the consecutive failure count
     */
    public int getConsecutiveFailures() {
        return consecutiveFailures;
    }

    /**
     * Returns the base delay in milliseconds.
     *
     * @return base delay ms
     */
    public long getBaseDelayMs() {
        return baseDelayMs;
    }

    /**
     * Returns the maximum delay in milliseconds.
     *
     * @return max delay ms
     */
    public long getMaxDelayMs() {
        return maxDelayMs;
    }

    /**
     * Returns the maximum number of attempts before critical error.
     *
     * @return max attempts
     */
    public int getMaxAttempts() {
        return maxAttempts;
    }
}
