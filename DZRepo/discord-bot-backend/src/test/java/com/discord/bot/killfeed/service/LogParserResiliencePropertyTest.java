package com.discord.bot.killfeed.service;

import com.discord.bot.killfeed.model.KillEvent;
import net.jqwik.api.*;

import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Feature: kill-feed-discord, Property 3: For any log with malformed lines mixed
 * with valid ones, the parser extracts the valid ones without throwing exceptions.
 *
 * **Validates: Requirements 3.4**
 */
class LogParserResiliencePropertyTest {

    private final LogParser parser = new LogParser();

    /**
     * Property 3: For any log content containing valid kill lines mixed with
     * malformed lines (missing fields, broken format, random garbage), the
     * LogParser SHALL extract all valid kill lines correctly and skip the
     * malformed ones without throwing any exceptions.
     *
     * Strategy: Generate a known set of valid kill lines and malformed lines,
     * combine them, parse, and verify that:
     * 1. No exception is thrown
     * 2. The number of extracted events equals the number of valid kill lines
     * 3. All extracted events have non-null required fields
     *
     * **Validates: Requirements 3.4**
     */
    @Property(tries = 100)
    void malformedLinesMixedWithValid_extractsValidWithoutExceptions(
            @ForAll("validKillLines") List<String> validLines,
            @ForAll("malformedLines") List<String> malformedLines) {

        // Interleave valid and malformed lines
        String logContent = Stream.concat(
                malformedLines.stream(),
                validLines.stream()
        ).collect(Collectors.joining("\n"));

        // Should never throw
        List<KillEvent> events = assertDoesNotThrow(
                () -> parser.parseKillEvents(logContent),
                "Parser should not throw on malformed input"
        );

        // Should extract exactly the valid lines
        assertEquals(validLines.size(), events.size(),
                "Parser should extract exactly the valid kill lines");

        // All extracted events should have non-null required fields
        for (KillEvent event : events) {
            assertNotNull(event.killerName(), "Killer name should not be null");
            assertNotNull(event.victimName(), "Victim name should not be null");
            assertNotNull(event.weapon(), "Weapon should not be null");
            assertNotNull(event.timestamp(), "Timestamp should not be null");
            assertTrue(event.distance() >= 0, "Distance should be non-negative");
        }
    }

    /**
     * Generates 0-5 valid kill lines in ADM format.
     */
    @Provide
    Arbitrary<List<String>> validKillLines() {
        Arbitrary<String> killLine = Combinators.combine(
                timestamps(),
                playerNames(),
                playerNames(),
                weapons(),
                coordinates(),
                coordinates(),
                distances()
        ).as((ts, victim, killer, weapon, victimCoords, killerCoords, dist) ->
                String.format(Locale.US,
                        "%s | Player \"%s\" (id=%s pos=<%.1f, %.1f, %.1f>) " +
                        "killed by Player \"%s\" (id=%s pos=<%.1f, %.1f, %.1f>) " +
                        "with %s from %.1f meters",
                        ts, victim, "id" + Math.abs(victim.hashCode()),
                        victimCoords[0], victimCoords[1], victimCoords[2],
                        killer, "id" + Math.abs(killer.hashCode()),
                        killerCoords[0], killerCoords[1], killerCoords[2],
                        weapon, dist
                )
        );

        return killLine.list().ofMinSize(0).ofMaxSize(5);
    }

    /**
     * Generates 0-5 malformed lines that should NOT be parsed as kill events.
     * Includes various types of malformation:
     * - Random garbage text
     * - Partial kill lines with missing fields
     * - Lines with broken coordinate format
     * - Empty/whitespace lines
     * - Lines that look like kills but have wrong structure
     */
    @Provide
    Arbitrary<List<String>> malformedLines() {
        Arbitrary<String> malformed = Arbitraries.oneOf(
                // Random garbage
                Arbitraries.strings()
                        .withCharRange('a', 'z')
                        .withCharRange('0', '9')
                        .withChars(' ', '|', '<', '>')
                        .ofMinLength(1)
                        .ofMaxLength(100),
                // Partial kill line — missing "meters" at end
                Combinators.combine(timestamps(), playerNames())
                        .as((ts, name) -> String.format(
                                "%s | Player \"%s\" (id=abc pos=<100.0, 200.0, 50.0>) killed by Player",
                                ts, name)),
                // Broken coordinates
                Combinators.combine(timestamps(), playerNames())
                        .as((ts, name) -> String.format(
                                "%s | Player \"%s\" (id=abc pos=<broken>) killed by Player \"K\" (id=def pos=<100.0, 200.0, 50.0>) with M4 from 10.0 meters",
                                ts, name)),
                // Empty / whitespace
                Arbitraries.of("", "   ", "\t"),
                // Line with "killed by" but wrong overall structure
                Arbitraries.of(
                        "killed by Player \"Someone\"",
                        "12:00:00 | killed by something",
                        "12:00:00 | Player killed by Player with weapon"
                )
        );

        return malformed.list().ofMinSize(0).ofMaxSize(5);
    }

    @Provide
    Arbitrary<String> timestamps() {
        return Combinators.combine(
                Arbitraries.integers().between(0, 23),
                Arbitraries.integers().between(0, 59),
                Arbitraries.integers().between(0, 59)
        ).as((h, m, s) -> String.format("%02d:%02d:%02d", h, m, s));
    }

    @Provide
    Arbitrary<String> playerNames() {
        return Arbitraries.strings()
                .withCharRange('a', 'z')
                .withCharRange('A', 'Z')
                .withCharRange('0', '9')
                .ofMinLength(1)
                .ofMaxLength(15);
    }

    @Provide
    Arbitrary<String> weapons() {
        return Arbitraries.of(
                "M4-A1", "AK-74", "IJ-70", "Mosin9130", "KA-M",
                "SVD", "Fists", "BK-18", "Vaiga", "LAR"
        );
    }

    @Provide
    Arbitrary<double[]> coordinates() {
        return Combinators.combine(
                Arbitraries.doubles().between(0.0, 15000.0).ofScale(1),
                Arbitraries.doubles().between(0.0, 15000.0).ofScale(1),
                Arbitraries.doubles().between(0.0, 500.0).ofScale(1)
        ).as((x, y, z) -> new double[]{x, y, z});
    }

    @Provide
    Arbitrary<Double> distances() {
        return Arbitraries.doubles().between(0.1, 2000.0).ofScale(1);
    }
}
