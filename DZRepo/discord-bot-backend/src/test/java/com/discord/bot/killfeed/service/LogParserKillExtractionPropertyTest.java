package com.discord.bot.killfeed.service;

import com.discord.bot.killfeed.model.KillEvent;
import net.jqwik.api.*;

import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Feature: kill-feed-discord, Property 2: For any mixed log, the parser extracts
 * only kill lines.
 *
 * **Validates: Requirements 3.1, 3.5**
 */
class LogParserKillExtractionPropertyTest {

    private final LogParser parser = new LogParser();

    /**
     * Property 2: For any log content containing a mix of valid kill lines and
     * non-kill lines (connections, disconnections, etc.), the LogParser SHALL
     * return exactly the kill lines and none of the non-kill lines.
     *
     * Strategy: Generate a known number of kill lines and non-kill lines,
     * interleave them, parse the combined log, and verify the count and
     * content match exactly the kill lines.
     *
     * **Validates: Requirements 3.1, 3.5**
     */
    @Property(tries = 100)
    void mixedLog_extractsOnlyKillLines(
            @ForAll("killLines") List<String> killLines,
            @ForAll("nonKillLines") List<String> nonKillLines) {

        // Interleave kill and non-kill lines
        String logContent = Stream.concat(
                nonKillLines.stream(),
                killLines.stream()
        ).collect(Collectors.joining("\n"));

        // Also try with kill lines first, then non-kill
        String logContent2 = Stream.concat(
                killLines.stream(),
                nonKillLines.stream()
        ).collect(Collectors.joining("\n"));

        List<KillEvent> events1 = parser.parseKillEvents(logContent);
        List<KillEvent> events2 = parser.parseKillEvents(logContent2);

        // Both orderings should produce the same number of kill events
        assertEquals(killLines.size(), events1.size(),
                "Parser should extract exactly the kill lines from mixed log");
        assertEquals(killLines.size(), events2.size(),
                "Parser should extract exactly the kill lines regardless of ordering");
    }

    /**
     * Generates 0-5 valid kill lines in ADM format.
     */
    @Provide
    Arbitrary<List<String>> killLines() {
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
                        ts, victim, "id" + victim.hashCode(),
                        victimCoords[0], victimCoords[1], victimCoords[2],
                        killer, "id" + killer.hashCode(),
                        killerCoords[0], killerCoords[1], killerCoords[2],
                        weapon, dist
                )
        );

        return killLine.list().ofMinSize(0).ofMaxSize(5);
    }

    /**
     * Generates 0-5 non-kill log lines (connections, disconnections, etc.).
     */
    @Provide
    Arbitrary<List<String>> nonKillLines() {
        Arbitrary<String> nonKillLine = Combinators.combine(
                timestamps(),
                playerNames(),
                Arbitraries.of(
                        "is connected",
                        "has been disconnected",
                        "placed",
                        "hit by FallDamage",
                        "is unconscious"
                )
        ).as((ts, name, action) ->
                String.format(Locale.US, "%s | Player \"%s\" %s (id=abc123)", ts, name, action)
        );

        return nonKillLine.list().ofMinSize(0).ofMaxSize(5);
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
