package com.discord.bot.command;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;

import org.springframework.stereotype.Component;

import java.awt.Color;

/**
 * Slash command {@code /help} that displays all available commands grouped by category.
 */
@Component
public class HelpCommand implements SlashCommand {

    @Override
    public String getName() {
        return "help";
    }

    @Override
    public String getDescription() {
        return "Muestra todos los comandos disponibles del bot";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription());
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        EmbedBuilder embed = new EmbedBuilder()
                .setColor(Color.decode("#DD0000"))
                .setTitle("📖 Comandos disponibles")
                .setDescription("Aquí están todos los comandos que puedes usar en este servidor.")

                // 🖥️ Servidor
                .addField("🖥️ Servidor", """
                        `/ping` — Verifica que el bot está activo
                        `/status` — Estado actual del servidor DayZ
                        `/restart` — Reinicia el servidor *(admin)*
                        `/stop` — Detiene el servidor *(admin)*
                        """, false)

                // 💀 Kill Feed
                .addField("💀 Kill Feed", """
                        `/killfeed setup channel: service_id:` — Configura el canal del kill feed *(admin)*
                        `/killfeed remove` — Elimina la configuración del kill feed *(admin)*
                        `/killfeed test` — Envía un embed de prueba al canal configurado *(admin)*
                        """, false)

                // 🔔 Notificaciones
                .addField("🔔 Notificaciones", """
                        `/notification setup channel:` — Configura el canal de notificaciones para jugadores no vinculados *(admin)*
                        `/notification remove` — Elimina la configuración de notificaciones *(admin)*
                        `/notification test` — Envía un embed de prueba al canal configurado *(admin)*
                        """, false)

                // 💰 Economía
                .addField("💰 Economía", """
                        `/vincular nombre:` — Vincula tu cuenta de Discord con tu nombre en DayZ
                        `/desvincular` — Desvincula tu cuenta de Discord
                        `/balance` — Consulta tu saldo actual
                        `/transferir jugador: cantidad:` — Transfiere monedas a otro jugador
                        `/transacciones` — Historial de tus transacciones
                        `/top` — Ranking de jugadores con más monedas
                        `/estatus` — Muestra tu perfil y estadísticas
                        `/economia` — Información general de la economía *(admin)*
                        """, false)

                // 🛠️ Administración
                .addField("🛠️ Administración", """
                        `/cleanup list` — Lista todos los comandos registrados en Discord *(admin)*
                        `/cleanup delete name:` — Elimina un comando específico *(admin)*
                        `/cleanup deleteall` — Elimina TODOS los comandos registrados *(admin)*
                        """, false)

                .setFooter("Los comandos marcados con *(admin)* requieren permisos de administrador");

        event.replyEmbeds(embed.build()).setEphemeral(true).queue();
    }
}
