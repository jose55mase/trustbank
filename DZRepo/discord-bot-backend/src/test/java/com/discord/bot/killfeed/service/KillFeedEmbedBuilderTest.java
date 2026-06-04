package com.discord.bot.killfeed.service;

import com.discord.bot.killfeed.model.KillEvent;
import net.dv8tion.jda.api.entities.MessageEmbed;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.awt.Color;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link KillFeedEmbedBuilder}.
 * Validates: Requirements 4.1, 4.2, 4.3, 4.6, 7.2
 */
class KillFeedEmbedBuilderTest {

    private KillFeedEmbedBuilder builder;

    @BeforeEach
    void setUp() {
        builder = new KillFeedEmbedBuilder();
    }

    private KillEvent sampleEvent() {
        return new KillEvent(
                "KillerPlayer", "VictimPlayer", "M4-A1", 150.3,
                1100.7, 210.4, 55.2,
                1000.5, 200.3, 50.1,
                "12:34:56", 0
        );
    }

    // --- buildEmbed tests ---

    @Test
    void buildEmbed_hasRedColor() {
        MessageEmbed embed = builder.buildEmbed(sampleEvent());
        assertEquals(new Color(0xCC0000).getRGB(), embed.getColorRaw());
    }

    @Test
    void buildEmbed_titleContainsSkullIcon() {
        MessageEmbed embed = builder.buildEmbed(sampleEvent());
        assertNotNull(embed.getTitle());
        assertTrue(embed.getTitle().contains("☠"));
    }

    @Test
    void buildEmbed_containsKillerName() {
        MessageEmbed embed = builder.buildEmbed(sampleEvent());
        List<MessageEmbed.Field> fields = embed.getFields();
        assertTrue(fields.stream().anyMatch(f ->
                "Asesino".equals(f.getName()) && "KillerPlayer".equals(f.getValue())));
    }

    @Test
    void buildEmbed_containsVictimName() {
        MessageEmbed embed = builder.buildEmbed(sampleEvent());
        List<MessageEmbed.Field> fields = embed.getFields();
        assertTrue(fields.stream().anyMatch(f ->
                "Víctima".equals(f.getName()) && "VictimPlayer".equals(f.getValue())));
    }

    @Test
    void buildEmbed_containsWeapon() {
        MessageEmbed embed = builder.buildEmbed(sampleEvent());
        List<MessageEmbed.Field> fields = embed.getFields();
        assertTrue(fields.stream().anyMatch(f ->
                "Arma".equals(f.getName()) && "M4-A1".equals(f.getValue())));
    }

    @Test
    void buildEmbed_distanceFormattedInMeters() {
        MessageEmbed embed = builder.buildEmbed(sampleEvent());
        List<MessageEmbed.Field> fields = embed.getFields();
        assertTrue(fields.stream().anyMatch(f ->
                "Distancia".equals(f.getName()) && "150.3 metros".equals(f.getValue())));
    }

    @Test
    void buildEmbed_containsLocationCoordinates() {
        MessageEmbed embed = builder.buildEmbed(sampleEvent());
        List<MessageEmbed.Field> fields = embed.getFields();
        MessageEmbed.Field locationField = fields.stream()
                .filter(f -> "Ubicación".equals(f.getName()))
                .findFirst()
                .orElse(null);
        assertNotNull(locationField);
        String value = locationField.getValue();
        assertNotNull(value);
        // Killer coords
        assertTrue(value.contains("1100.7"));
        assertTrue(value.contains("210.4"));
        assertTrue(value.contains("55.2"));
        // Victim coords
        assertTrue(value.contains("1000.5"));
        assertTrue(value.contains("200.3"));
        assertTrue(value.contains("50.1"));
    }

    @Test
    void buildEmbed_footerContainsTimestamp() {
        MessageEmbed embed = builder.buildEmbed(sampleEvent());
        assertNotNull(embed.getFooter());
        assertEquals("12:34:56", embed.getFooter().getText());
    }

    // --- createDummyEvent tests ---

    @Test
    void createDummyEvent_returnsNonNull() {
        KillEvent dummy = builder.createDummyEvent();
        assertNotNull(dummy);
    }

    @Test
    void createDummyEvent_hasRealisticData() {
        KillEvent dummy = builder.createDummyEvent();
        assertNotNull(dummy.killerName());
        assertFalse(dummy.killerName().isBlank());
        assertNotNull(dummy.victimName());
        assertFalse(dummy.victimName().isBlank());
        assertNotNull(dummy.weapon());
        assertFalse(dummy.weapon().isBlank());
        assertTrue(dummy.distance() > 0);
        assertNotNull(dummy.timestamp());
        assertTrue(dummy.timestamp().matches("\\d{2}:\\d{2}:\\d{2}"));
    }

    @Test
    void createDummyEvent_embedBuildsSuccessfully() {
        KillEvent dummy = builder.createDummyEvent();
        MessageEmbed embed = builder.buildEmbed(dummy);
        assertNotNull(embed);
        assertEquals(new Color(0xCC0000).getRGB(), embed.getColorRaw());
    }
}
