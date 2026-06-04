package com.discord.bot.economy.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.service.PlayerLinkService;
import com.discord.bot.economy.service.PlayerStatsService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.entities.MessageEmbed;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.commands.build.SubcommandData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.text.NumberFormat;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/**
 * Slash command {@code /top} with subcommands {@code kills}, {@code zombies},
 * {@code ricos}, and {@code kd}.
 *
 * <p>Displays leaderboard embeds showing the top 10 players for each category.
 * If the command executor is not in the top 10, their position is shown at
 * the bottom of the embed.</p>
 */
@Component
public class TopCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(TopCommand.class);

    private static final String[] POSITION_EMOJIS = {"🥇", "🥈", "🥉"};

    private final PlayerStatsService playerStatsService;
    private final PlayerLinkService playerLinkService;

    public TopCommand(PlayerStatsService playerStatsService,
                      PlayerLinkService playerLinkService) {
        this.playerStatsService = playerStatsService;
        this.playerLinkService = playerLinkService;
    }

    @Override
    public String getName() {
        return "top";
    }

    @Override
    public String getDescription() {
        return "Muestra las tablas de clasificación del servidor";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addSubcommands(
                        new SubcommandData("kills", "Top 10 jugadores con más kills"),
                        new SubcommandData("zombies", "Top 10 jugadores con más kills de zombies"),
                        new SubcommandData("ricos", "Top 10 jugadores con más TNT Coins"),
                        new SubcommandData("kd", "Top 10 jugadores con mejor ratio K/D")
                );
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String subcommand = event.getSubcommandName();
        if (subcommand == null) {
            event.reply("❌ Subcomando no reconocido.").setEphemeral(true).queue();
            return;
        }

        try {
            String discordId = event.getUser().getId();

            MessageEmbed embed = switch (subcommand) {
                case "kills" -> buildKillsEmbed(discordId);
                case "zombies" -> buildZombiesEmbed(discordId);
                case "ricos" -> buildRicosEmbed(discordId);
                case "kd" -> buildKdEmbed(discordId);
                default -> null;
            };

            if (embed == null) {
                event.reply("❌ Subcomando no reconocido: " + subcommand)
                        .setEphemeral(true).queue();
                return;
            }

            event.replyEmbeds(embed).queue();
        } catch (Exception e) {
            log.error("Error al generar leaderboard '{}': {}", subcommand, e.getMessage(), e);
            event.reply("❌ Ocurrió un error interno. Intenta de nuevo.")
                    .setEphemeral(true).queue();
        }
    }

    private MessageEmbed buildKillsEmbed(String discordId) {
        List<PlayerProfile> topPlayers = playerStatsService.getTopKills();

        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < topPlayers.size(); i++) {
            PlayerProfile p = topPlayers.get(i);
            sb.append(formatPosition(i + 1))
                    .append(" **").append(p.getDayzPlayerName()).append("** — ")
                    .append(p.getPlayerKills()).append(" kills\n");
        }

        appendUserPosition(sb, topPlayers, discordId, profile ->
                profile.getPlayerKills() + " kills");

        return new EmbedBuilder()
                .setColor(new Color(0xE74C3C))
                .setTitle("⚔️ Top Kills de Jugadores")
                .setDescription(sb.toString())
                .build();
    }

    private MessageEmbed buildZombiesEmbed(String discordId) {
        List<PlayerProfile> topPlayers = playerStatsService.getTopZombieKills();

        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < topPlayers.size(); i++) {
            PlayerProfile p = topPlayers.get(i);
            sb.append(formatPosition(i + 1))
                    .append(" **").append(p.getDayzPlayerName()).append("** — ")
                    .append(p.getZombieKills()).append(" zombie kills\n");
        }

        appendUserPosition(sb, topPlayers, discordId, profile ->
                profile.getZombieKills() + " zombie kills");

        return new EmbedBuilder()
                .setColor(new Color(0x2ECC71))
                .setTitle("🧟 Top Kills de Zombies")
                .setDescription(sb.toString())
                .build();
    }

    private MessageEmbed buildRicosEmbed(String discordId) {
        List<PlayerProfile> topPlayers = playerStatsService.getTopBalance();
        NumberFormat numberFormat = NumberFormat.getIntegerInstance(Locale.US);

        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < topPlayers.size(); i++) {
            PlayerProfile p = topPlayers.get(i);
            sb.append(formatPosition(i + 1))
                    .append(" **").append(p.getDayzPlayerName()).append("** — ")
                    .append(numberFormat.format(p.getBalance())).append(" TNT Coins\n");
        }

        appendUserPosition(sb, topPlayers, discordId, profile ->
                numberFormat.format(profile.getBalance()) + " TNT Coins");

        return new EmbedBuilder()
                .setColor(new Color(0xF1C40F))
                .setTitle("💰 Top Jugadores Más Ricos")
                .setDescription(sb.toString())
                .build();
    }

    private MessageEmbed buildKdEmbed(String discordId) {
        List<PlayerProfile> topPlayers = playerStatsService.getTopKd();

        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < topPlayers.size(); i++) {
            PlayerProfile p = topPlayers.get(i);
            String kd = PlayerStatsService.calculateKdRatio(p.getPlayerKills(), p.getDeaths());
            sb.append(formatPosition(i + 1))
                    .append(" **").append(p.getDayzPlayerName()).append("** — ")
                    .append(kd).append(" K/D\n");
        }

        appendUserPosition(sb, topPlayers, discordId, profile -> {
            String kd = PlayerStatsService.calculateKdRatio(
                    profile.getPlayerKills(), profile.getDeaths());
            return kd + " K/D";
        });

        return new EmbedBuilder()
                .setColor(new Color(0x9B59B6))
                .setTitle("📈 Top Ratio K/D")
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

    /**
     * Appends the command executor's position to the leaderboard if they
     * are not already in the top list. Shows "Tu posición: no clasificado"
     * if the user is not linked.
     */
    private void appendUserPosition(StringBuilder sb,
                                    List<PlayerProfile> topPlayers,
                                    String discordId,
                                    StatFormatter formatter) {
        boolean userInTop = topPlayers.stream()
                .anyMatch(p -> p.getDiscordId().equals(discordId));

        if (userInTop) {
            return;
        }

        Optional<PlayerProfile> userProfile = playerLinkService.findByDiscordId(discordId);

        if (userProfile.isEmpty()) {
            sb.append("\n---\nTu posición: no clasificado");
            return;
        }

        PlayerProfile profile = userProfile.get();
        sb.append("\n---\n")
                .append("Tu posición: **").append(profile.getDayzPlayerName()).append("** — ")
                .append(formatter.format(profile));
    }

    /**
     * Functional interface for formatting a player's stat value in the leaderboard.
     */
    @FunctionalInterface
    private interface StatFormatter {
        String format(PlayerProfile profile);
    }
}
