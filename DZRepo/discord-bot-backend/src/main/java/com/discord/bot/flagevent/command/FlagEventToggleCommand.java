package com.discord.bot.flagevent.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.flagevent.config.FlagEventProperties;
import com.discord.bot.flagevent.service.FlagEventService;

import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.commands.build.SubcommandData;

import org.springframework.stereotype.Component;

/**
 * Slash command {@code /flag-event} with subcommands {@code enable}, {@code disable}, and {@code status}.
 * Allows administrators to toggle the flag event system on/off at runtime without restarting.
 */
@Component
public class FlagEventToggleCommand implements SlashCommand {

    private final FlagEventService flagEventService;
    private final FlagEventProperties properties;

    public FlagEventToggleCommand(FlagEventService flagEventService, FlagEventProperties properties) {
        this.flagEventService = flagEventService;
        this.properties = properties;
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
        if (success) {
            event.reply("✅ Evento de banderas **activado**. El sistema ahora está monitoreando los logs.")
                    .setEphemeral(true).queue();
        } else {
            event.reply("❌ No se puede activar: primero configura la ubicación con `/flag-location set`.")
                    .setEphemeral(true).queue();
        }
    }

    private void handleDisable(SlashCommandInteractionEvent event, String guildId) {
        boolean success = flagEventService.setEnabled(guildId, false);
        if (success) {
            event.reply("⏸️ Evento de banderas **desactivado**. El sistema dejó de monitorear los logs.")
                    .setEphemeral(true).queue();
        } else {
            event.reply("ℹ️ No hay evento configurado para desactivar.")
                    .setEphemeral(true).queue();
        }
    }

    private void handleStatus(SlashCommandInteractionEvent event, String guildId) {
        boolean enabled = flagEventService.isEnabled(guildId);
        if (enabled) {
            event.reply("🟢 El evento de banderas está **activo**.")
                    .setEphemeral(true).queue();
        } else {
            event.reply("🔴 El evento de banderas está **inactivo**.")
                    .setEphemeral(true).queue();
        }
    }
}
