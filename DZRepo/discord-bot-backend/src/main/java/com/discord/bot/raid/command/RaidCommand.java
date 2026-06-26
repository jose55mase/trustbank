package com.discord.bot.raid.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.raid.dto.RaidScheduleUpdateDto;
import com.discord.bot.raid.model.RaidSchedule;
import com.discord.bot.raid.service.RaidScheduleService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.entities.Member;
import net.dv8tion.jda.api.entities.channel.Channel;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.OptionMapping;
import net.dv8tion.jda.api.interactions.commands.OptionType;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.commands.build.SubcommandData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

/**
 * Slash command {@code /raid} for managing raid schedules.
 * 
 * <p>Provides subcommands for configuring raid time windows, setting the status channel,
 * and viewing current configuration. Only administrators can use this command.</p>
 * 
 * <p>Usage examples:</p>
 * <ul>
 *   <li>{@code /raid configurar canal:#raid-status inicio:18:00 fin:22:00} - Sets up raid schedule</li>
 *   <li>{@code /raid estado} - Shows current raid configuration</li>
 *   <li>{@code /raid activar} - Enables the raid schedule system</li>
 *   <li>{@code /raid desactivar} - Disables the raid schedule system</li>
 * </ul>
 */
@Component
public class RaidCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(RaidCommand.class);
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm");

    private final RaidScheduleService raidScheduleService;

    public RaidCommand(RaidScheduleService raidScheduleService) {
        this.raidScheduleService = raidScheduleService;
    }

    @Override
    public String getName() {
        return "raid";
    }

    @Override
    public String getDescription() {
        return "Configura el sistema de horarios de raid";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addSubcommands(
                        new SubcommandData("configurar", "Configura el canal y horarios de raid")
                                .addOption(OptionType.CHANNEL, "canal", "Canal para mostrar el estado del raid", true)
                                .addOption(OptionType.STRING, "inicio", "Hora de inicio del raid (formato HH:mm, ej: 18:00)", true)
                                .addOption(OptionType.STRING, "fin", "Hora de fin del raid (formato HH:mm, ej: 22:00)", true),
                        new SubcommandData("estado", "Muestra la configuración actual del raid"),
                        new SubcommandData("activar", "Activa el sistema de horarios de raid"),
                        new SubcommandData("desactivar", "Desactiva el sistema de horarios de raid"),
                        new SubcommandData("actualizar", "Fuerza una actualización del estado del raid")
                );
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        if (!checkAdminPermission(event)) {
            return;
        }

        String guildId = event.getGuild().getId();
        String subcommand = event.getSubcommandName();

        if (subcommand == null) {
            event.reply("❌ Subcomando no reconocido.").setEphemeral(true).queue();
            return;
        }

        try {
            switch (subcommand) {
                case "configurar" -> handleConfigurar(event, guildId);
                case "estado" -> handleEstado(event, guildId);
                case "activar" -> handleActivar(event, guildId, true);
                case "desactivar" -> handleActivar(event, guildId, false);
                case "actualizar" -> handleActualizar(event, guildId);
                default -> event.reply("❌ Subcomando no reconocido: " + subcommand)
                        .setEphemeral(true).queue();
            }
        } catch (Exception e) {
            log.error("Error executing /raid {}: {}", subcommand, e.getMessage(), e);
            event.reply("❌ Ocurrió un error interno. Intenta de nuevo.")
                    .setEphemeral(true).queue();
        }
    }

    private void handleConfigurar(SlashCommandInteractionEvent event, String guildId) {
        Channel channel = event.getOption("canal", OptionMapping::getAsChannel);
        String inicioStr = event.getOption("inicio", OptionMapping::getAsString);
        String finStr = event.getOption("fin", OptionMapping::getAsString);

        // Parse times
        LocalTime startTime;
        LocalTime endTime;
        try {
            startTime = LocalTime.parse(inicioStr, TIME_FORMAT);
            endTime = LocalTime.parse(finStr, TIME_FORMAT);
        } catch (DateTimeParseException e) {
            event.reply("❌ Formato de hora inválido. Usa el formato HH:mm (ej: 18:00)")
                    .setEphemeral(true).queue();
            return;
        }

        // Create update DTO
        RaidScheduleUpdateDto dto = new RaidScheduleUpdateDto();
        dto.setStatusChannelId(channel.getId());
        dto.setRaidStartTime(LocalDateTime.now().with(startTime));
        dto.setRaidEndTime(LocalDateTime.now().with(endTime));
        dto.setEnabled(true);

        RaidSchedule schedule = raidScheduleService.updateSchedule(guildId, dto);

        var embed = new EmbedBuilder()
                .setColor(new Color(0x3498DB))
                .setTitle("⚔️ Raid Configurado")
                .addField("Canal de Estado", "<#" + channel.getId() + ">", false)
                .addField("Hora de Inicio", startTime.format(TIME_FORMAT), true)
                .addField("Hora de Fin", endTime.format(TIME_FORMAT), true)
                .addField("Estado Actual", schedule.isRaidActive() ? "🟢 ACTIVO" : "🔴 INACTIVO", false)
                .setFooter("El nombre del canal se actualizará automáticamente")
                .build();

        event.replyEmbeds(embed).queue();
    }

    private void handleEstado(SlashCommandInteractionEvent event, String guildId) {
        RaidSchedule schedule = raidScheduleService.getOrCreateSchedule(guildId);

        String channelInfo = schedule.getStatusChannelId() != null 
                ? "<#" + schedule.getStatusChannelId() + ">" 
                : "No configurado";
        
        String startTimeInfo = schedule.getRaidStartTime() != null 
                ? schedule.getRaidStartTime().toLocalTime().format(TIME_FORMAT) 
                : "No configurado";
        
        String endTimeInfo = schedule.getRaidEndTime() != null 
                ? schedule.getRaidEndTime().toLocalTime().format(TIME_FORMAT) 
                : "No configurado";

        var embed = new EmbedBuilder()
                .setColor(schedule.isRaidActive() ? new Color(0x2ECC71) : new Color(0xE74C3C))
                .setTitle("⚔️ Estado del Sistema de Raid")
                .addField("Sistema", schedule.isEnabled() ? "✅ Activado" : "❌ Desactivado", false)
                .addField("Canal de Estado", channelInfo, false)
                .addField("Hora de Inicio", startTimeInfo, true)
                .addField("Hora de Fin", endTimeInfo, true)
                .addField("Estado del Raid", schedule.isRaidActive() 
                        ? "🟢 ACTIVO - Se puede raidear" 
                        : "🔴 INACTIVO - No se puede raidear", false)
                .setFooter("Usa /raid configurar para modificar la configuración")
                .build();

        event.replyEmbeds(embed).queue();
    }

    private void handleActivar(SlashCommandInteractionEvent event, String guildId, boolean enabled) {
        RaidScheduleUpdateDto dto = new RaidScheduleUpdateDto();
        dto.setEnabled(enabled);

        RaidSchedule schedule = raidScheduleService.updateSchedule(guildId, dto);

        if (enabled) {
            if (schedule.getStatusChannelId() == null) {
                event.reply("⚠️ Sistema activado, pero no hay canal configurado. " +
                           "Usa `/raid configurar` para configurar el canal y horarios.")
                        .setEphemeral(true).queue();
                return;
            }

            var embed = new EmbedBuilder()
                    .setColor(new Color(0x2ECC71))
                    .setTitle("✅ Sistema de Raid Activado")
                    .setDescription("El canal de estado se actualizará automáticamente según el horario configurado.")
                    .addField("Estado Actual", schedule.isRaidActive() ? "🟢 ACTIVO" : "🔴 INACTIVO", false)
                    .build();

            event.replyEmbeds(embed).queue();
        } else {
            var embed = new EmbedBuilder()
                    .setColor(new Color(0xE74C3C))
                    .setTitle("❌ Sistema de Raid Desactivado")
                    .setDescription("El canal de estado ya no se actualizará automáticamente.")
                    .build();

            event.replyEmbeds(embed).queue();
        }
    }

    private void handleActualizar(SlashCommandInteractionEvent event, String guildId) {
        raidScheduleService.forceUpdateStatus(guildId);

        RaidSchedule schedule = raidScheduleService.getOrCreateSchedule(guildId);

        var embed = new EmbedBuilder()
                .setColor(new Color(0x3498DB))
                .setTitle("🔄 Actualización Forzada")
                .addField("Estado Actual", schedule.isRaidActive() ? "🟢 ACTIVO" : "🔴 INACTIVO", false)
                .setDescription("El canal de estado ha sido actualizado.")
                .build();

        event.replyEmbeds(embed).queue();
    }

    /**
     * Checks if the member has administrator permissions.
     *
     * @param event the slash command interaction event
     * @return true if the member has admin permissions
     */
    private boolean checkAdminPermission(SlashCommandInteractionEvent event) {
        Member member = event.getMember();
        if (member == null || !member.hasPermission(Permission.ADMINISTRATOR)) {
            event.reply("❌ Se requieren permisos de administrador para usar este comando.")
                    .setEphemeral(true).queue();
            return false;
        }
        return true;
    }
}
