package com.discord.bot.killfeed.service;

import com.discord.bot.killfeed.model.KillEvent;
import net.jqwik.api.*;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Feature: kill-feed-discord, Property 1: For any valid KillEvent, formatting as text
 * and parsing back produces an equivalent event.
 *
 * **Validates: Requirements 3.2, 3.3, 3.6**
 */
class LogParserRoundTripPropertyTest {

    private final LogParser parser = new LogParser();

    /**
     * Property 1: Round-trip — for any valid KillEvent with arbitrary player names,
     * weapon, distance, coordinates and timestamp, formatting the event as ADM log text
     * and then parsing it back SHALL produce a KillEvent equivalent to the original.
     *
     * We compare all semantic fields (names, weapon, distance within tolerance,
     * coordinates within tolerance, timestamp). The lineIndex is set to 0 for the
     * re-parsed event since it depends on the parse call, not the original data.
     *
     * **Validates: Requirements 3.2, 3.3, 3.6**
     */
    @Property(tries = 200)
    void roundTrip_formatThenParse_producesEquivalentEvent(
            @ForAll("validKillEvents") KillEvent original) {

        String formatted = parser.formatKillEvent(original);
        Optional<KillEvent> reparsed = parser.parseLine(formatted, original.lineIndex());

        assertTrue(reparsed.isPresent(), "Formatted kill event should be parseable");

        KillEvent result = reparsed.get();
        assertEquals(original.killerName(), result.killerName());
        assertEquals(original.victimName(), result.victimName());
        assertEquals(original.weapon(), result.weapon());
        assertEquals(original.distance(), result.distance(), 0.1,
                "Distance should match within tolerance");
        assertEquals(original.killerX(), result.killerX(), 0.1);
        assertEquals(original.killerY(), result.killerY(), 0.1);
        assertEquals(original.killerZ(), result.killerZ(), 0.1);
        assertEquals(original.victimX(), result.victimX(), 0.1);
        assertEquals(original.victimY(), result.victimY(), 0.1);
        assertEquals(original.victimZ(), result.victimZ(), 0.1);
        assertEquals(original.timestamp(), result.timestamp());
        assertEquals(original.lineIndex(), result.lineIndex());
    }

    /**
     * Generates valid KillEvent instances with constrained random data.
     * Player names are alphanumeric with spaces (no quotes to avoid breaking the format).
     * Coordinates are realistic DayZ map values. Timestamps are valid HH:mm:ss.
     *
     * Uses a two-step combine to stay within jqwik's 8-parameter limit.
     */
    @Provide
    Arbitrary<KillEvent> validKillEvents() {
        Arbitrary<String> playerName = Arbitraries.strings()
                .withCharRange('a', 'z')
                .withCharRange('A', 'Z')
                .withCharRange('0', '9')
                .withChars(' ')
                .ofMinLength(1)
                .ofMaxLength(20)
                .filter(s -> !s.isBlank())
                .map(String::trim)
                .filter(s -> !s.isEmpty());

        Arbitrary<String> weapon = Arbitraries.of(
                "M4-A1", "AK-74", "IJ-70", "Mosin9130", "KA-M",
                "SVD", "CR-527", "Blaze", "Vaiga", "Fists",
                "BK-18", "Pioneer", "Sporter22", "SK 59-66", "LAR"
        );

        Arbitrary<Double> coordinate = Arbitraries.doubles()
                .between(0.0, 15000.0)
                .ofScale(1);

        Arbitrary<Double> distance = Arbitraries.doubles()
                .between(0.1, 2000.0)
                .ofScale(1);

        Arbitrary<String> timestamp = Combinators.combine(
                Arbitraries.integers().between(0, 23),
                Arbitraries.integers().between(0, 59),
                Arbitraries.integers().between(0, 59)
        ).as((h, m, s) -> String.format("%02d:%02d:%02d", h, m, s));

        Arbitrary<Integer> lineIndex = Arbitraries.integers().between(0, 10000);

        // Combine coordinates into arrays to stay within the 8-param limit
        Arbitrary<double[]> killerCoords = Combinators.combine(coordinate, coordinate, coordinate)
                .as((x, y, z) -> new double[]{x, y, z});

        Arbitrary<double[]> victimCoords = Combinators.combine(coordinate, coordinate, coordinate)
                .as((x, y, z) -> new double[]{x, y, z});

        return Combinators.combine(
                playerName, playerName, weapon, distance,
                killerCoords, victimCoords,
                timestamp, lineIndex
        ).as((killer, victim, w, dist, kc, vc, ts, li) ->
                new KillEvent(killer, victim, w, dist,
                        kc[0], kc[1], kc[2],
                        vc[0], vc[1], vc[2],
                        ts, li)
        );
    }
}
