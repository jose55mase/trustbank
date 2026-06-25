package com.discord.bot.economy.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.service.PlayerStatsService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.entities.User;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.OptionMapping;
import net.dv8tion.jda.api.interactions.commands.OptionType;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.text.NumberFormat;
import java.util.Locale;
import java.util.Optional;

/**
 * Slash command {@code /estatus} that displays a player's DayZ statistics.
 *
 * <p>Shows an embed with: DayZ name, player kills, deaths, K/D ratio,
 * zombie kills, and Coins balance. Supports an optional {@code usuario}
 * option to view another user's stats.</p>
 */
@Component
public class EstatusCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(EstatusCommand.class);

    private final PlayerStatsService playerStatsService;

    public EstatusCommand(PlayerStatsService playerStatsService) {
        this.playerStatsService = playerStatsService;
    }

    @Override
    public String getName() {
        return "estatus";
    }

    @Override
    public String getDescription() {
        return "Muestra las estadísticas de tu jugador DayZ";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addOption(OptionType.USER, "usuario",
                        "Usuario del que quieres ver las estadísticas", false);
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        try {
            // Determine target user: mentioned user or command executor
            OptionMapping usuarioOption = event.getOption("usuario");
            User targetUser;
            if (usuarioOption != null) {
                targetUser = usuarioOption.getAsUser();
            } else {
                targetUser = event.getUser();
            }

            String targetDiscordId = targetUser.getId();

            Optional<PlayerProfile> optProfile = playerStatsService.getStats(targetDiscordId);

            if (optProfile.isEmpty()) {
                String message;
                if (usuarioOption != null) {
                    message = "❌ El usuario mencionado no tiene una cuenta vinculada.";
                } else {
                    message = "❌ No tienes una cuenta vinculada. Usa `/vincular` para vincular tu cuenta.";
                }
                event.reply(message).setEphemeral(true).queue();
                return;
            }

            PlayerProfile profile = optProfile.get();

            String kdRatio = PlayerStatsService.calculateKdRatio(
                    profile.getPlayerKills(), profile.getDeaths());

            NumberFormat numberFormat = NumberFormat.getIntegerInstance(Locale.US);
            String formattedBalance = numberFormat.format(profile.getBalance());

            var embed = new EmbedBuilder()
                    .setColor(new Color(0x1ABC9C))
                    .setTitle("📊 Estadísticas de " + profile.getDayzPlayerName())
                    .addField("Nombre DayZ", profile.getDayzPlayerName(), true)
                    .addField("Kills de Jugadores", String.valueOf(profile.getPlayerKills()), true)
                    .addField("Muertes", String.valueOf(profile.getDeaths()), true)
                    .addField("K/D Ratio", kdRatio, true)
                    .addField("Kills de Zombies", String.valueOf(profile.getZombieKills()), true)
                    .addField("Balance Coins", formattedBalance, true)
                    .build();

            event.replyEmbeds(embed).queue();
        } catch (Exception e) {
            log.error("Error al obtener estadísticas: {}", e.getMessage(), e);
            event.reply("❌ Ocurrió un error interno. Intenta de nuevo.")
                    .setEphemeral(true).queue();
        }
    }
}
