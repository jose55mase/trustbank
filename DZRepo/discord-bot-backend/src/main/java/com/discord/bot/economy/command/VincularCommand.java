package com.discord.bot.economy.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.economy.exception.DayzNameAlreadyLinkedException;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.service.PlayerLinkService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.OptionType;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;

/**
 * Slash command {@code /vincular} that links a Discord account to a DayZ player name.
 *
 * <p>Allows players to associate their Discord identity with their in-game name
 * so the economy and stats systems can track their activity.</p>
 */
@Component
public class VincularCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(VincularCommand.class);

    private final PlayerLinkService playerLinkService;

    public VincularCommand(PlayerLinkService playerLinkService) {
        this.playerLinkService = playerLinkService;
    }

    @Override
    public String getName() {
        return "vincular";
    }

    @Override
    public String getDescription() {
        return "Vincula tu cuenta de Discord con tu nombre de jugador DayZ";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addOption(OptionType.STRING, "nombre", "Tu nombre de jugador en DayZ", true);
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String nombre = event.getOption("nombre").getAsString();
        String discordId = event.getUser().getId();

        try {
            PlayerProfile profile = playerLinkService.linkPlayer(discordId, nombre);

            var embed = new EmbedBuilder()
                    .setColor(new Color(0x2ECC71))
                    .setTitle("✅ Cuenta vinculada")
                    .setDescription("Tu cuenta de Discord ha sido vinculada exitosamente.")
                    .addField("Nombre DayZ", profile.getDayzPlayerName(), false)
                    .build();

            event.replyEmbeds(embed).queue();
        } catch (DayzNameAlreadyLinkedException e) {
            event.reply("❌ El nombre **" + e.getDayzName() + "** ya está vinculado a otra cuenta de Discord.")
                    .setEphemeral(true).queue();
        } catch (Exception e) {
            log.error("Error al vincular cuenta para Discord ID {}: {}", discordId, e.getMessage(), e);
            event.reply("❌ Ocurrió un error interno. Intenta de nuevo.")
                    .setEphemeral(true).queue();
        }
    }
}
