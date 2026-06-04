package com.discord.bot.killfeed.service;

import com.discord.bot.killfeed.model.KillEvent;
import net.dv8tion.jda.api.entities.MessageEmbed;
import net.jqwik.api.*;

import java.util.List;
import java.util.Locale;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Feature: kill-feed-discord, Property 7: For any KillEvent, the built embed contains
 * killer name, victim name, weapon, distance in meters and coordinates.
 *
 * **Validates: Requirements 4.1, 4.6**
 */
class KillFeedEmbedBuilderPropertyTest {

    private final KillFeedEmbedBuilder builder = new KillFeedEmbedBuilder();

    /**
     * Property 7: For any KillEvent with arbitrary data, the MessageEmbed built by
     * KillFeedEmbedBuilder SHALL contain the killer name, victim name, weapon,
     * distance formatted in meters, and coordinates of both killer and victim.
     *
     * **Validates: Requirements 4.1, 4.6**
     */
    @Property(tries = 100)
    void embedContainsAllRequiredFields(
            @ForAll("validKillEvents") KillEvent event) {

        MessageEmbed embed = builder.buildEmbed(event);
        List<MessageEmbed.Field> fields = embed.getFields();

        // Killer name present
        assertTrue(fields.stream().anyMatch(f ->
                        "Asesino".equals(f.getName()) && event.killerName().equals(f.getValue())),
                "Embed must contain killer name in 'Asesino' field");

        // Victim name present
        assertTrue(fields.stream().anyMatch(f ->
                        "Víctima".equals(f.getName()) && event.victimName().equals(f.getValue())),
                "Embed must contain victim name in 'Víctima' field");

        // Weapon present
        assertTrue(fields.stream().anyMatch(f ->
                        "Arma".equals(f.getName()) && event.weapon().equals(f.getValue())),
                "Embed must contain weapon in 'Arma' field");

        // Distance formatted in meters
        MessageEmbed.Field distField = fields.stream()
                .filter(f -> "Distancia".equals(f.getName()))
                .findFirst()
                .orElse(null);
        assertNotNull(distField, "Embed must contain 'Distancia' field");
        assertNotNull(distField.getValue());
        assertTrue(distField.getValue().endsWith("metros"),
                "Distance must be formatted in metros");

        // Location coordinates present
        MessageEmbed.Field locField = fields.stream()
                .filter(f -> "Ubicación".equals(f.getName()))
                .findFirst()
                .orElse(null);
        assertNotNull(locField, "Embed must contain 'Ubicación' field");
        String locValue = locField.getValue();
        assertNotNull(locValue);
        // Verify killer coordinates appear in location (use Locale.US to match buildEmbed formatting)
        assertTrue(locValue.contains(String.format(Locale.US, "%.1f", event.killerX())),
                "Location must contain killer X coordinate");
        assertTrue(locValue.contains(String.format(Locale.US, "%.1f", event.killerY())),
                "Location must contain killer Y coordinate");
        assertTrue(locValue.contains(String.format(Locale.US, "%.1f", event.killerZ())),
                "Location must contain killer Z coordinate");
        // Verify victim coordinates appear in location
        assertTrue(locValue.contains(String.format(Locale.US, "%.1f", event.victimX())),
                "Location must contain victim X coordinate");
        assertTrue(locValue.contains(String.format(Locale.US, "%.1f", event.victimY())),
                "Location must contain victim Y coordinate");
        assertTrue(locValue.contains(String.format(Locale.US, "%.1f", event.victimZ())),
                "Location must contain victim Z coordinate");
    }

    /**
     * Generates valid KillEvent instances with constrained random data.
     * Player names are alphanumeric (no quotes). Coordinates are realistic DayZ values.
     * Timestamps are valid HH:mm:ss.
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
