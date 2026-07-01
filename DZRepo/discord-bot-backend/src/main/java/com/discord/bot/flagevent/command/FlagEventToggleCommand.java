package com.discord.bot.flagevent.command;

import com.discord.bot.BotInitializer;
import com.discord.bot.command.SlashCommand;
import com.discord.bot.flagevent.config.FlagEventProperties;
import com.discord.bot.flagevent.model.FlagLocation;
import com.discord.bot.flagevent.service.FlagEventService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.commands.build.SubcommandData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.util.Optional;

/**
 * Slash command {@code /flag-event} with subcommands {@code enable}, {@code disable}, and {@code status}.
 * Allows administrators to toggle the flag event system on/off at runtime without restarting.
 * Sends a confirmation embed to the configured notification channel when enabled/disabled.
 */
@Component
public class FlagEventToggleCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(FlagEventToggleCommand.class);

    private static final Color COLOR_ENABLED = new Color(0x2ECC71);  // Green
    private static final Color COLOR_DISABLED = new Color(0xE74C3C); // Red

    private final FlagEventService flagEventService;
    private final FlagEventProperties properties;
    private final BotInitializer botInitializer;

    public FlagEventToggleCommand(FlagEventService flagEventService,
                                  FlagEventProperties properties,
                                  BotInitializer botInitializer) {
        this.flagEventService = flagEventService;
        this.properties = properties;
        this.botInitializer = botInitializer;
    }

    @Override
    public String getName() {
        return "flag-event";
    }

    @Override
    public String getDescription() {
        return "Activar o desactivar el evento de banderas";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addSubcommands(
                        new SubcommandData("enable", "Activar el evento de banderas"),
                        new SubcommandData("disable", "Desactivar el evento de banderas"),
                        new SubcommandData("status", "Ver si el evento está activo o inactivo")
                );
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String subcommand = event.getSubcommandName();
        if (subcommand == null) {
            event.reply("❌ Subcomando no reconocido.").setEphemeral(true).queue();
            return;
        }

        String guildId = properties.getGuildId();

        switch (subcommand) {
            case "enable" -> handleEnable(event, guildId);
            case "disable" -> handleDisable(event, guildId);
            case "status" -> handleStatus(event, guildId);
            default -> event.reply("❌ Subcomando no reconocido: " + subcommand)
                    .setEphemeral(true).queue();
        }
    }

    private void handleEnable(SlashCommandInteractionEvent event, String guildId) {
        boolean success = flagEventService.setEnabled(guildId, true);
        if (!success) {
            event.reply("❌ No se puede activar: primero configura la ubicación con `/flag-location set`.")
                    .setEphemeral(true).queue();
            return;
        }

        event.reply("✅ Evento de banderas **activado**. El sistema ahora está monitoreando los logs.")
                .setEphemeral(true).queue();

        // Send confirmation embed to the configured channel
        sendChannelEmbed(guildId, true);
    }

    private void handleDisable(SlashCommandInteractionEvent event, String guildId) {
        boolean success = flagEventService.setEnabled(guildId, false);
        if (!success) {
            event.reply("ℹ️ No hay evento configurado para desactivar.")
                    .setEphemeral(true).queue();
            return;
        }

        event.reply("⏸️ Evento de banderas **desactivado**. El sistema dejó de monitorear los logs.")
                .setEphemeral(true).queue();

        // Send confirmation embed to the configured channel
        sendChannelEmbed(guildId, false);
    }

    private void handleStatus(SlashCommandInteractionEvent event, String guildId) {
        boolean enabled = flagEventService.isEnabled(guildId);
        Optional<FlagLocation> locationOpt = flagEventService.getFlagLocation(guildId);

        if (locationOpt.isEmpty()) {
            event.reply("🔴 El evento de banderas no está configurado.")
                    .setEphemeral(true).queue();
            return;
        }

        FlagLocation location = locationOpt.get();
        String channelInfo = (location.getNotificationChannelId() != null && !location.getNotificationChannelId().isBlank())
                ? "<#" + location.getNotificationChannelId() + ">"
                : "No configurado";

        EmbedBuilder embed = new EmbedBuilder()
                .setColor(enabled ? COLOR_ENABLED : COLOR_DISABLED)
                .setTitle("🚩 Estado del Evento de Banderas")
                .addField("Estado", enabled ? "🟢 Activo" : "🔴 Inactivo", true)
                .addField("Canal", channelInfo, true)
                .addField("Ubicación", String.format("X=%.2f, Z=%.2f", location.getCoordX(), location.getCoordZ()), true)
                .addField("Tolerancia", String.format("%.0f metros", location.getTolerance()), true);

        event.replyEmbeds(embed.build()).setEphemeral(true).queue();
    }

    /**
     * Sends a public embed to the configured notification channel confirming
     * that the flag event system was enabled or disabled.
     */
    private void sendChannelEmbed(String guildId, boolean enabled) {
        Optional<FlagLocation> locationOpt = flagEventService.getFlagLocation(guildId);
        if (locationOpt.isEmpty()) {
            return;
        }

        FlagLocation location = locationOpt.get();
        String channelId = location.getNotificationChannelId();

        if (channelId == null || channelId.isBlank()) {
            log.warn("[FlagEvent] Cannot send confirmation embed: no notification channel configured.");
            return;
        }

        JDA jda = botInitializer.getJda();
        if (jda == null) {
            return;
        }

        TextChannel channel = jda.getTextChannelById(channelId);
        if (channel == null) {
            log.warn("[FlagEvent] Cannot send confirmation embed: channel {} not found.", channelId);
            return;
        }

        EmbedBuilder embed = new EmbedBuilder();

        if (enabled) {
            embed.setColor(COLOR_ENABLED)
                    .setTitle("🚩 Evento de Control de Bandera — ACTIVADO")
                    .setDescription("El sistema de monitoreo de banderas está **activo**. " +
                            "Se notificará en este canal cada vez que alguien ize o baje una bandera en la zona configurada.")
                    .addField("📍 Ubicación monitoreada", String.format("X=%.2f, Z=%.2f", location.getCoordX(), location.getCoordZ()), true)
                    .addField("📏 Tolerancia", String.format("%.0f metros", location.getTolerance()), true)
                    .addField("📢 Canal de notificaciones", "<#" + channelId + ">", true);
        } else {
            embed.setColor(COLOR_DISABLED)
                    .setTitle("🏁 Evento de Control de Bandera — DESACTIVADO")
                    .setDescription("El sistema de monitoreo de banderas ha sido **desactivado**. " +
                            "No se enviarán más notificaciones hasta que un administrador lo reactive.");
        }

        channel.sendMessageEmbeds(embed.build()).queue(
                msg -> log.info("[FlagEvent] Confirmation embed sent to channel {}", channelId),
                err -> log.warn("[FlagEvent] Failed to send confirmation embed: {}", err.getMessage())
        );
    }
}
