package com.discord.bot.monitor;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;

import net.jqwik.api.*;

import org.slf4j.LoggerFactory;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;

import static org.junit.jupiter.api.Assertions.*;

// Feature: discord-bot-backend, Property 9: Umbral de tasa de errores dispara alerta

/**
 * Property test: For any sequence of errors recorded, ErrorRateMonitor SHALL emit
 * an ERROR-level alert if and only if the error count in the 1-minute window exceeds 10.
 * If count <= 10, no alert SHALL be emitted.
 *
 * **Validates: Requirements 7.4**
 */
class ErrorRateThresholdPropertyTest {

    @Property(tries = 100)
    void errorRateAlertEmittedIfAndOnlyIfCountExceedsTen(
            @ForAll("errorCounts") int errorCount) {

        // Use a fixed clock so all errors fall within the same 1-minute window
        Instant fixedInstant = Instant.parse("2024-01-15T10:00:00Z");
        Clock fixedClock = Clock.fixed(fixedInstant, ZoneId.of("UTC"));

        ErrorRateMonitor monitor = new ErrorRateMonitor(fixedClock);

        // Set up Logback ListAppender to capture log events from ErrorRateMonitor
        Logger monitorLogger = (Logger) LoggerFactory.getLogger(ErrorRateMonitor.class);
        ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
        listAppender.start();
        monitorLogger.addAppender(listAppender);

        try {
            // Record the generated number of errors
            for (int i = 0; i < errorCount; i++) {
                monitor.recordError();
            }

            // Check for ERROR-level logs containing the alert message
            boolean hasErrorAlert = listAppender.list.stream()
                    .filter(event -> event.getLevel() == ch.qos.logback.classic.Level.ERROR)
                    .anyMatch(event -> event.getFormattedMessage().contains("Tasa de errores elevada"));

            if (errorCount > 10) {
                assertTrue(hasErrorAlert,
                        "Expected ERROR alert 'Tasa de errores elevada' when error count is "
                                + errorCount + " (> 10), but none was found");
            } else {
                assertFalse(hasErrorAlert,
                        "Expected NO ERROR alert when error count is "
                                + errorCount + " (<= 10), but one was found");
            }
        } finally {
            // Clean up: remove the appender to avoid leaking between test runs
            monitorLogger.detachAppender(listAppender);
            listAppender.stop();
        }
    }

    @Provide
    Arbitrary<Integer> errorCounts() {
        return Arbitraries.integers().between(0, 50);
    }
}
