package com.discord.bot.flagevent.service;

import com.discord.bot.BotInitializer;
import com.discord.bot.flagevent.model.FlagEvent;
import com.discord.bot.flagevent.model.LeaderboardEntry;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.entities.MessageEmbed;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

/**
 * Implementation of {@link FlagNotificationService} that sends Discord embed notifications
 * for flag raise and lower events, including the top 5 leaderboard and dominant flag info.
 */
@Service
public class FlagNotificationServiceImpl implements FlagNotificationService {

    private static final Logger log = LoggerFactory.getLogger(FlagNotificationServiceImpl.class);

    private static final Color COLOR_RAISE = new Color(0x2ECC71); // Green
    private static final Color COLOR_LOWER = new Color(0xE74C3C); // Red
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm:ss");

    private final BotInitializer botInitializer;
    private final FlagEventService flagEventService;

    public FlagNotificationServiceImpl(BotInitializer botInitializer,
                                       @Lazy FlagEventService flagEventService) {
        this.botInitializer = botInitializer;
        this.flagEventService = flagEventService;
    }

    @Override
    public void sendRaiseNotification(FlagEvent event, String channelId) {
        if (channelId == null || channelId.isBlank()) {
            log.warn("[FlagNotification] No notification channel configured. Skipping raise notification.");
            return;
        }

        TextChannel channel = getTextChannel(channelId);
        if (channel == null) {
            return;
        }

        String guildId = channel.getGuild().getId();

        // Build leaderboard and dominant flag sections
        String leaderboardSection = buildLeaderboardSection(guildId);
        String dominantFlagSection = buildDominantFlagSection(guildId);

        EmbedBuilder embed = new EmbedBuilder()
                .setColor(COLOR_RAISE)
                .setTitle("🚩 Flag Raised!")
                .addField("Jugador", event.playerName(), true)
                .addField("Bandera", event.flagName(), true)
                .addField("Hora", event.timestamp().format(TIME_FORMATTER), true)
                .addField("📊 Top 5 Leaderboard", leaderboardSection, false)
                .addField("🏆 Bandera Dominante", dominantFlagSection, false);

        channel.sendMessageEmbeds(embed.build()).queue(
                msg -> log.info("[FlagNotification] Raise notification sent for player '{}' in channel {}",
                        event.playerName(), channelId),
                err -> log.warn("[FlagNotification] Failed to send raise notification to channel {}: {}",
                        channelId, err.getMessage())
        );
    }

    @Override
    public void sendLowerNotification(FlagEvent event, long elapsedSeconds, String channelId) {
        if (channelId == null || channelId.isBlank()) {
            log.warn("[FlagNotification] No notification channel configured. Skipping lower notification.");
            return;
        }

        TextChannel channel = getTextChannel(channelId);
        if (channel == null) {
            return;
        }

        String guildId = channel.getGuild().getId();

        // Build leaderboard and dominant flag sections
        String leaderboardSection = buildLeaderboardSection(guildId);
        String dominantFlagSection = buildDominantFlagSection(guildId);

        String elapsedFormatted = FlagEventService.formatTime(elapsedSeconds);

        EmbedBuilder embed = new EmbedBuilder()
                .setColor(COLOR_LOWER)
                .setTitle("🏳️ Flag Lowered!")
                .addField("Jugador", event.playerName(), true)
                .addField("Bandera", event.flagName(), true)
                .addField("Tiempo Activa", elapsedFormatted, true)
                .addField("📊 Top 5 Leaderboard", leaderboardSection, false)
                .addField("🏆 Bandera Dominante", dominantFlagSection, false);

        channel.sendMessageEmbeds(embed.build()).queue(
                msg -> log.info("[FlagNotification] Lower notification sent for player '{}' in channel {}",
                        event.playerName(), channelId),
                err -> log.warn("[FlagNotification] Failed to send lower notification to channel {}: {}",
                        channelId, err.getMessage())
        );
    }

    /**
     * Resolves the TextChannel from JDA. Returns null and logs a warning if not found.
     */
    private TextChannel getTextChannel(String channelId) {
        JDA jda = botInitializer.getJda();
        if (jda == null) {
            log.warn("[FlagNotification] JDA not initialized. Skipping notification.");
            return null;
        }

        TextChannel channel = jda.getTextChannelById(channelId);
        if (channel == null) {
            log.warn("[FlagNotification] Channel {} unavailable or bot lacks permissions. Discarding notification.",
                    channelId);
            return null;
        }

        return channel;
    }

    /**
     * Builds the top 5 leaderboard section for the embed.
     * Format: "1. PlayerName - FlagName - HH:MM:SS"
     */
    private String buildLeaderboardSection(String guildId) {
        List<LeaderboardEntry> entries = flagEventService.getLeaderboard(guildId, 5);

        if (entries.isEmpty()) {
            return "No hay datos registrados";
        }

        StringBuilder sb = new StringBuilder();
        for (LeaderboardEntry entry : entries) {
            sb.append(entry.rank()).append(". ")
              .append(entry.playerName()).append(" - ")
              .append(entry.flagName()).append(" - ")
              .append(entry.formattedTime())
              .append("\n");
        }

        return sb.toString().trim();
    }

    /**
     * Builds the dominant flag section for the embed.
     */
    private String buildDominantFlagSection(String guildId) {
        Optional<String> dominantFlag = flagEventService.getDominantFlag(guildId);
        return dominantFlag.orElse("Sin datos");
    }
}
