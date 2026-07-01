package com.discord.bot.flagevent.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.flagevent.config.FlagEventProperties;
import com.discord.bot.flagevent.model.PlayerStatus;
import com.discord.bot.flagevent.service.FlagEventService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.util.Optional;

/**
 * Slash command {@code /flag-status} for querying a player's flag event status.
 *
 * <p>Identifies the player by their Discord username (simplified mapping: Discord username = in-game name).
 * Returns total accumulated time (including active session elapsed), flag name, and whether
 * the player's flag is currently active.
 */
@Component
public class FlagStatusCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(FlagStatusCommand.class);

    private static final Color COLOR_STATUS = new Color(0x3498DB); // Blue
    private static final Color COLOR_ACTIVE = new Color(0x2ECC71); // Green

    private final FlagEventService flagEventService;
    private final FlagEventProperties flagEventProperties;

    public FlagStatusCommand(FlagEventService flagEventService, FlagEventProperties flagEventProperties) {
        this.flagEventService = flagEventService;
        this.flagEventProperties = flagEventProperties;
    }

    @Override
    public String getName() {
        return "flag-status";
    }

    @Override
    public String getDescription() {
        return "View your flag event status and accumulated time";
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String playerName = event.getUser().getName();
        String guildId = flagEventProperties.getGuildId();

        if (playerName == null || playerName.isBlank()) {
            event.reply("❌ No se pudo identificar al jugador vinculado a tu cuenta de Discord.")
                    .setEphemeral(true).queue();
            return;
        }

        Optional<PlayerStatus> statusOpt;
        try {
            statusOpt = flagEventService.getPlayerStatus(guildId, playerName);
        } catch (Exception e) {
            log.error("[FlagStatus] Error retrieving player status for '{}': {}", playerName, e.getMessage(), e);
            event.reply("❌ El estado del jugador no está disponible temporalmente.")
                    .setEphemeral(true).queue();
            return;
        }

        if (statusOpt.isEmpty()) {
            event.reply("ℹ️ No tienes historial de eventos de bandera.")
                    .setEphemeral(true).queue();
            return;
        }

        PlayerStatus status = statusOpt.get();

        String activeText = status.active() ? "✅ Sí (bandera izada)" : "❌ No";
        Color embedColor = status.active() ? COLOR_ACTIVE : COLOR_STATUS;

        EmbedBuilder embed = new EmbedBuilder()
                .setColor(embedColor)
                .setTitle("🚩 Estado de Bandera — " + status.playerName())
                .addField("Bandera", status.flagName(), true)
                .addField("Tiempo Total", status.formattedTime(), true)
                .addField("Activa", activeText, true);

        event.replyEmbeds(embed.build()).setEphemeral(true).queue();
    }
}
