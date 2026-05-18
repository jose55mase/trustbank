package com.discord.bot.killfeed.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.killfeed.model.NotificationConfig;
import com.discord.bot.killfeed.service.ConnectionNotificationService;
import com.discord.bot.killfeed.store.KillFeedConfigStore;
import com.discord.bot.killfeed.store.NotificationConfigStore;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.entities.Member;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.OptionType;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.commands.build.SubcommandData;

import org.springframework.stereotype.Component;

import java.awt.Color;
import java.util.Optional;

/**
 * Slash command {@code /notification} for managing the unlinked player notification channel.
 *
 * <p>Subcommands:
 * <ul>
 *   <li>{@code setup} — configures the notification channel for a guild</li>
 *   <li>{@code remove} — removes the notification configuration</li>
 *   <li>{@code test} — sends a test embed to the configured channel</li>
 * </ul>
 */
@Component
public class NotificationCommand implements SlashCommand {

    private final NotificationConfigStore notificationConfigStore;
    private final KillFeedConfigStore killFeedConfigStore;
    private final ConnectionNotificationService connectionNotificationService;

    public NotificationCommand(NotificationConfigStore notificationConfigStore,
                               KillFeedConfigStore killFeedConfigStore,
                               ConnectionNotificationService connectionNotificationService) {
        this.notificationConfigStore = notificationConfigStore;
        this.killFeedConfigStore = killFeedConfigStore;
        this.connectionNotificationService = connectionNotificationService;
    }

    @Override
    public String getName() {
        return "notification";
    }

    @Override
    public String getDescription() {
        return "Configura las notificaciones de jugadores no vinculados";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addSubcommands(
                        new SubcommandData("setup", "Configura el canal de notificaciones")
                                .addOption(OptionType.CHANNEL, "channel", "Canal donde se enviarán las notificaciones", true),
                        new SubcommandData("remove", "Elimina la configuración de notificaciones"),
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

        if (killFeedConfigStore.getConfig(guildId).isEmpty()) {
            event.reply("❌ Primero configura el kill feed con `/killfeed setup`.").setEphemeral(true).queue();
            return;
        }

        int serviceId = killFeedConfigStore.getConfig(guildId).get().serviceId();
        notificationConfigStore.saveConfig(new NotificationConfig(guildId, channelId, serviceId));
        event.reply("✅ Canal de notificaciones configurado: <#" + channelId + ">.").queue();
    }

    private void handleRemove(SlashCommandInteractionEvent event) {
        if (!checkAdminPermission(event)) return;
        String guildId = event.getGuild().getId();

        if (notificationConfigStore.getConfig(guildId).isEmpty()) {
            event.reply("ℹ️ No hay configuración activa de notificaciones.").setEphemeral(true).queue();
            return;
        }

        notificationConfigStore.removeConfig(guildId);
        connectionNotificationService.clearCache(guildId);
        event.reply("✅ Configuración de notificaciones eliminada.").queue();
    }

    private void handleTest(SlashCommandInteractionEvent event) {
        if (!checkAdminPermission(event)) return;
        String guildId = event.getGuild().getId();

        Optional<NotificationConfig> configOpt = notificationConfigStore.getConfig(guildId);
        if (configOpt.isEmpty()) {
            event.reply("❌ No hay configuración de notificaciones. Usa `/notification setup` primero.").setEphemeral(true).queue();
            return;
        }

        TextChannel channel = event.getJDA().getTextChannelById(configOpt.get().channelId());
        if (channel == null) {
            event.reply("❌ No se encontró el canal configurado.").setEphemeral(true).queue();
            return;
        }

        channel.sendMessageEmbeds(
                new EmbedBuilder()
                        .setColor(Color.ORANGE)
                        .setTitle("⚠️ Jugador no vinculado")
                        .setDescription("El jugador **TestPlayer** se ha conectado al servidor pero no está vinculado.")
                        .addField("¿Cómo vincularte?", "Usa el comando `/vincular` para vincular tu cuenta de Discord con tu nombre de DayZ.", false)
                        .addField("Nombre en DayZ", "`TestPlayer`", true)
                        .setFooter("Usa /vincular para registrarte")
                        .build()
        ).queue();

        event.reply("✅ Embed de prueba enviado a <#" + configOpt.get().channelId() + ">.").queue();
    }

    private boolean checkAdminPermission(SlashCommandInteractionEvent event) {
        Member member = event.getMember();
        if (member == null || !member.hasPermission(Permission.ADMINISTRATOR)) {
            event.reply("❌ Se requieren permisos de administrador.").setEphemeral(true).queue();
            return false;
        }
        return true;
    }
}
