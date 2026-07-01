package com.discord.bot.flagevent.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.flagevent.config.FlagEventProperties;
import com.discord.bot.flagevent.model.LeaderboardEntry;
import com.discord.bot.flagevent.service.FlagEventService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.entities.MessageEmbed;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.util.List;
import java.util.Optional;

/**
 * Slash command {@code /flag-leaderboard}.
 *
 * <p>Displays a Discord embed with the top 10 players ranked by total
 * accumulated flag time. Includes active session elapsed time in
 * calculations and shows the dominant flag.</p>
 */
@Component
public class FlagLeaderboardCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(FlagLeaderboardCommand.class);

    private static final String[] POSITION_EMOJIS = {"🥇", "🥈", "🥉"};

    private final FlagEventService flagEventService;
    private final FlagEventProperties properties;

    public FlagLeaderboardCommand(FlagEventService flagEventService,
                                  FlagEventProperties properties) {
        this.flagEventService = flagEventService;
        this.properties = properties;
    }

    @Override
    public String getName() {
        return "flag-leaderboard";
    }

    @Override
    public String getDescription() {
        return "Muestra el leaderboard de tiempo acumulado con bandera izada";
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String guildId = properties.getGuildId();

        try {
            List<LeaderboardEntry> entries = flagEventService.getLeaderboard(guildId, 10);

            if (entries.isEmpty()) {
                event.reply("📭 No flag events recorded.")
                        .setEphemeral(true).queue();
                return;
            }

            MessageEmbed embed = buildLeaderboardEmbed(entries, guildId);
            event.replyEmbeds(embed).queue();

        } catch (Exception e) {
            log.error("Error retrieving flag leaderboard for guild {}: {}",
                    guildId, e.getMessage(), e);
            event.reply("❌ Leaderboard temporarily unavailable.")
                    .setEphemeral(true).queue();
        }
    }

    private MessageEmbed buildLeaderboardEmbed(List<LeaderboardEntry> entries, String guildId) {
        StringBuilder sb = new StringBuilder();

        for (LeaderboardEntry entry : entries) {
            sb.append(formatPosition(entry.rank()))
                    .append(" **").append(entry.playerName()).append("** — ")
                    .append(entry.flagName()).append(" — ")
                    .append(entry.formattedTime()).append("\n");
        }

        // Append dominant flag info
        Optional<String> dominantFlag = flagEventService.getDominantFlag(guildId);
        if (dominantFlag.isPresent()) {
            sb.append("\n🏴 **Dominant flag:** ").append(dominantFlag.get());
        }

        return new EmbedBuilder()
                .setColor(new Color(0xE67E22))
                .setTitle("🚩 Flag Leaderboard — Top 10")
                .setDescription(sb.toString())
                .build();
    }

    /**
     * Formats a leaderboard position with emoji medals for top 3
     * and plain numbers for positions 4–10.
     */
    private String formatPosition(int position) {
        if (position >= 1 && position <= POSITION_EMOJIS.length) {
            return POSITION_EMOJIS[position - 1];
        }
        return "**" + position + ".**";
    }
}
