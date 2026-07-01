package com.discord.bot.flagevent.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.flagevent.config.FlagEventProperties;
import com.discord.bot.flagevent.service.FlagEventService;

import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.OptionMapping;
import net.dv8tion.jda.api.interactions.commands.OptionType;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.commands.build.SubcommandData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.regex.Pattern;

/**
 * Slash command {@code /flag-channel} with subcommand {@code set}.
 * Allows administrators to configure the Discord channel for flag event notifications.
 */
@Component
public class FlagChannelCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(FlagChannelCommand.class);

    /**
     * Pattern to validate a Discord channel ID: numeric, 17-20 digits.
     */
    private static final Pattern CHANNEL_ID_PATTERN = Pattern.compile("^\\d{17,20}$");

    private final FlagEventService flagEventService;
    private final FlagEventProperties properties;

    public FlagChannelCommand(FlagEventService flagEventService, FlagEventProperties properties) {
        this.flagEventService = flagEventService;
        this.properties = properties;
    }

    @Override
    public String getName() {
        return "flag-channel";
    }

    @Override
    public String getDescription() {
        return "Configura el canal de notificaciones para eventos de bandera";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addSubcommands(
                        new SubcommandData("set", "Establece el canal de notificaciones de banderas")
                                .addOption(OptionType.STRING, "channel", "ID del canal de Discord (17-20 dígitos)", true)
                );
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String subcommand = event.getSubcommandName();
        if (subcommand == null) {
            event.reply("❌ Subcomando no reconocido.").setEphemeral(true).queue();
            return;
        }

        if ("set".equals(subcommand)) {
            handleSet(event);
        } else {
            event.reply("❌ Subcomando no reconocido: " + subcommand).setEphemeral(true).queue();
        }
    }

    private void handleSet(SlashCommandInteractionEvent event) {
        OptionMapping channelOption = event.getOption("channel");
        if (channelOption == null) {
            event.reply("❌ Debes proporcionar un ID de canal.").setEphemeral(true).queue();
            return;
        }

        String channelId = channelOption.getAsString().trim();

        // Validate channel ID format: must be numeric and 17-20 digits
        if (!CHANNEL_ID_PATTERN.matcher(channelId).matches()) {
            event.reply("❌ ID de canal inválido. Debe ser un valor numérico de 17 a 20 dígitos.")
                    .setEphemeral(true).queue();
            return;
        }

        String guildId = properties.getGuildId();
        flagEventService.setChannel(guildId, channelId);

        log.info("Flag notification channel set to {} for guild {}", channelId, guildId);
        event.reply("✅ Canal de notificaciones de banderas configurado: <#" + channelId + ">")
                .setEphemeral(true).queue();
    }
}
