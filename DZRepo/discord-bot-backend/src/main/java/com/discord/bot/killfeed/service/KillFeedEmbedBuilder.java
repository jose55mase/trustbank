package com.discord.bot.killfeed.service;

import com.discord.bot.killfeed.model.KillEvent;
import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.entities.MessageEmbed;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

/**
 * Builds Discord embeds from {@link KillEvent} instances.
 *
 * <p>Each embed uses a red accent color ({@code #CC0000}), a skull icon in the title,
 * and displays all relevant kill information: killer, victim, weapon, distance and
 * location coordinates.</p>
 */
@Component
public class KillFeedEmbedBuilder {

    private static final Color EMBED_COLOR = new Color(0xCC0000);
    private static final String TITLE = "☠️ Kill Feed";

    /**
     * Builds a {@link MessageEmbed} for the given kill event.
     *
     * @param event the kill event to render
     * @return a fully-populated Discord embed
     */
    public MessageEmbed buildEmbed(KillEvent event) {
        String distanceFormatted = String.format(Locale.US, "%.1f metros", event.distance());
        String location = String.format(Locale.US,
                "Killer: (%.1f, %.1f, %.1f) | Victim: (%.1f, %.1f, %.1f)",
                event.killerX(), event.killerY(), event.killerZ(),
                event.victimX(), event.victimY(), event.victimZ());

        return new EmbedBuilder()
                .setColor(EMBED_COLOR)
                .setTitle(TITLE)
                .addField("Asesino", event.killerName(), true)
                .addField("Víctima", event.victimName(), true)
                .addField("Arma", event.weapon(), false)
                .addField("Distancia", distanceFormatted, true)
                .addField("Ubicación", location, false)
                .setFooter(event.timestamp())
                .build();
    }

    /**
     * Creates a dummy {@link KillEvent} with realistic fake data for the
     * {@code /killfeed test} command.
     *
     * @return a KillEvent populated with sample data and the current time as timestamp
     */
    public KillEvent createDummyEvent() {
        String timestamp = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
        return new KillEvent(
                "SurvivorJoe",
                "BanditKing",
                "M4-A1",
                253.7,
                7523.4, 2841.6, 312.1,
                7310.2, 2790.8, 305.5,
                timestamp,
                0
        );
    }
}
