package com.discord.bot.economy.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.economy.exception.PlayerNotLinkedException;
import com.discord.bot.economy.service.PlayerLinkService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;

/**
 * Slash command {@code /desvincular} that removes the link between a Discord account
 * and its DayZ player name.
 */
@Component
public class DesvincularCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(DesvincularCommand.class);

    private final PlayerLinkService playerLinkService;

    public DesvincularCommand(PlayerLinkService playerLinkService) {
        this.playerLinkService = playerLinkService;
    }

    @Override
    public String getName() {
        return "desvincular";
    }

    @Override
    public String getDescription() {
        return "Desvincula tu cuenta de Discord de tu nombre de jugador DayZ";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription());
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String discordId = event.getUser().getId();

        try {
            playerLinkService.unlinkPlayer(discordId);

            var embed = new EmbedBuilder()
                    .setColor(new Color(0xE74C3C))
                    .setTitle("✅ Cuenta desvinculada")
                    .setDescription("Tu cuenta de Discord ha sido desvinculada de tu nombre de jugador DayZ.")
                    .build();

            event.replyEmbeds(embed).queue();
        } catch (PlayerNotLinkedException e) {
            event.reply("❌ No tienes una cuenta vinculada. Debes vincular tu cuenta primero usando `/vincular`.")
                    .setEphemeral(true).queue();
        } catch (Exception e) {
            log.error("Error al desvincular cuenta para Discord ID {}: {}", discordId, e.getMessage(), e);
            event.reply("❌ Ocurrió un error interno. Intenta de nuevo.")
                    .setEphemeral(true).queue();
        }
    }
}
