package com.discord.bot.killfeed.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.killfeed.model.KillEvent;
import com.discord.bot.killfeed.model.KillFeedConfig;
import com.discord.bot.killfeed.service.KillFeedEmbedBuilder;
import com.discord.bot.killfeed.store.KillFeedConfigStore;
import com.discord.bot.nitrado.dto.GameServerDto;
import com.discord.bot.nitrado.service.NitradoApiClient;

import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.entities.Member;
import net.dv8tion.jda.api.entities.MessageEmbed;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.OptionType;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.commands.build.SubcommandData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

/**
 * Slash command {@code /killfeed} with subcommands {@code setup}, {@code remove}, and {@code test}.
 * Allows Discord administrators to configure, remove, and test the kill feed for their guild.
 */
@Component
public class KillFeedCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(KillFeedCommand.class);

    private final NitradoApiClient nitradoApiClient;
    private final KillFeedConfigStore configStore;
    private final KillFeedEmbedBuilder embedBuilder;

    public KillFeedCommand(NitradoApiClient nitradoApiClient,
                           KillFeedConfigStore configStore,
                           KillFeedEmbedBuilder embedBuilder) {
        this.nitradoApiClient = nitradoApiClient;
        this.configStore = configStore;
        this.embedBuilder = embedBuilder;
    }

    @Override
    public String getName() {
        return "killfeed";
    }

    @Override
    public String getDescription() {
        return "Configura el kill feed de DayZ para este servidor";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addSubcommands(
                        new SubcommandData("setup", "Configura el canal y servidor para el kill feed")
                                .addOption(OptionType.CHANNEL, "channel", "Canal donde se publicará el kill feed", true)
                                .addOption(OptionType.INTEGER, "service_id", "ID del servicio de Nitrado", true),
                        new SubcommandData("remove", "Elimina la configuración del kill feed"),
                        new SubcommandData("test", "Envía un embed de prueba al canal configurado")
                );
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String subcommand = event.getSubcommandName();
        if (subcommand == null) {
            event.reply("❌ Subcomando no reconocido.").setEphemeral(true).queue();
            return;
        }

        switch (subcommand) {
            case "setup" -> handleSetup(event);
            case "remove" -> handleRemove(event);
            case "test" -> handleTest(event);
            default -> event.reply("❌ Subcomando no reconocido: " + subcommand).setEphemeral(true).queue();
        }
    }

    private void handleSetup(SlashCommandInteractionEvent event) {
        if (!checkAdminPermission(event)) return;

        String guildId = event.getGuild().getId();
        String channelId = event.getOption("channel").getAsChannel().getId();
        int serviceId = event.getOption("service_id").getAsInt();

        // Validate serviceId against Nitrado API
        try {
            List<GameServerDto> servers = nitradoApiClient.getServers();
            boolean validService = servers.stream().anyMatch(s -> s.id() == serviceId);

            if (!validService) {
                event.reply("❌ El ID de servicio `" + serviceId + "` no corresponde a ningún servidor DayZ en Nitrado.")
                        .setEphemeral(true).queue();
                return;
            }
        } catch (Exception e) {
            log.error("Error validating serviceId {} against Nitrado API: {}", serviceId, e.getMessage(), e);
            event.reply("❌ No se pudo validar el ID de servicio contra la API de Nitrado. Intenta de nuevo más tarde.")
                    .setEphemeral(true).queue();
            return;
        }

        KillFeedConfig config = new KillFeedConfig(guildId, channelId, serviceId);
        configStore.saveConfig(config);

        event.reply("✅ Kill feed configurado correctamente. Canal: <#" + channelId + ">, Servicio ID: `" + serviceId + "`.")
                .queue();
    }

    private void handleRemove(SlashCommandInteractionEvent event) {
        if (!checkAdminPermission(event)) return;

        String guildId = event.getGuild().getId();
        Optional<KillFeedConfig> existing = configStore.getConfig(guildId);

        if (existing.isEmpty()) {
            event.reply("ℹ️ No hay configuración activa de kill feed para este servidor.")
                    .setEphemeral(true).queue();
            return;
        }

        configStore.removeConfig(guildId);
        event.reply("✅ Configuración de kill feed eliminada correctamente.").queue();
    }

    private void handleTest(SlashCommandInteractionEvent event) {
        if (!checkAdminPermission(event)) return;

        String guildId = event.getGuild().getId();
        Optional<KillFeedConfig> configOpt = configStore.getConfig(guildId);

        if (configOpt.isEmpty()) {
            event.reply("❌ No hay configuración de kill feed. Usa `/killfeed setup` primero.")
                    .setEphemeral(true).queue();
            return;
        }

        KillFeedConfig config = configOpt.get();
        KillEvent dummyEvent = embedBuilder.createDummyEvent();
        MessageEmbed embed = embedBuilder.buildEmbed(dummyEvent);

        TextChannel channel = event.getJDA().getTextChannelById(config.channelId());
        if (channel == null) {
            event.reply("❌ No se encontró el canal configurado. Verifica la configuración con `/killfeed setup`.")
                    .setEphemeral(true).queue();
            return;
        }

        channel.sendMessageEmbeds(embed).queue();
        event.reply("✅ Embed de prueba enviado al canal <#" + config.channelId() + ">.").queue();
    }

    /**
     * Checks if the member has administrator permissions.
     * Replies with an ephemeral error message if not.
     *
     * @param event the slash command interaction event
     * @return true if the member has admin permissions, false otherwise
     */
    private boolean checkAdminPermission(SlashCommandInteractionEvent event) {
        Member member = event.getMember();
        if (member == null || !member.hasPermission(Permission.ADMINISTRATOR)) {
            event.reply("❌ Se requieren permisos de administrador.")
                    .setEphemeral(true).queue();
            return false;
        }
        return true;
    }
}
