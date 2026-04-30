package com.discord.bot.command;

import com.discord.bot.nitrado.dto.GameServerDto;
import com.discord.bot.nitrado.dto.ServerAction;
import com.discord.bot.nitrado.exception.NitradoApiException;
import com.discord.bot.nitrado.exception.NitradoAuthException;
import com.discord.bot.nitrado.exception.NitradoConnectionException;
import com.discord.bot.nitrado.exception.NitradoNotFoundException;
import com.discord.bot.nitrado.service.NitradoApiClient;

import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.entities.Member;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Abstract base class for server control commands (restart, stop).
 * Encapsulates shared logic: permission verification, deferred replies,
 * server selection, action execution, and error handling.
 */
public abstract class AbstractServerCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(AbstractServerCommand.class);

    protected final NitradoApiClient nitradoApiClient;

    protected AbstractServerCommand(NitradoApiClient nitradoApiClient) {
        this.nitradoApiClient = nitradoApiClient;
    }

    /**
     * Returns the server action to execute (e.g., RESTART or STOP).
     */
    protected abstract ServerAction getAction();

    /**
     * Returns the success message to display after the action completes.
     *
     * @param serverName the name of the server the action was performed on
     * @return a user-facing success message
     */
    protected abstract String getSuccessMessage(String serverName);

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        // 1. Permission verification (Req 3.2): check member is not null (guild context)
        Member member = event.getMember();
        if (member == null) {
            event.reply("❌ Este comando solo está disponible en servidores de Discord.")
                    .setEphemeral(true).queue();
            return;
        }

        // 2. Permission verification (Req 3.1): check administrator permission
        if (!member.hasPermission(Permission.ADMINISTRATOR)) {
            event.reply("❌ No tienes permisos para ejecutar este comando. Se requiere rol de administrador.")
                    .setEphemeral(true).queue();
            return;
        }

        // 3. Deferred reply before Nitrado calls (Req 6.1)
        event.deferReply().queue();

        try {
            // 4. Get servers from Nitrado (Req 4.1)
            List<GameServerDto> servers = nitradoApiClient.getServers();

            if (servers.isEmpty()) {
                // 0 servers (Req 4.4)
                event.getHook().editOriginal("❌ No se encontraron servidores DayZ disponibles.").queue();
            } else if (servers.size() == 1) {
                // 1 server: direct execution (Req 4.2)
                GameServerDto server = servers.get(0);
                nitradoApiClient.serverAction(server.id(), getAction());
                event.getHook().editOriginal("✅ " + getSuccessMessage(server.name())).queue();
            } else {
                // 2+ servers: informational list (Req 4.3)
                StringBuilder sb = new StringBuilder();
                sb.append("Hay varios servidores disponibles. Por favor, especifica cuál deseas controlar:\n");
                for (int i = 0; i < servers.size(); i++) {
                    GameServerDto s = servers.get(i);
                    String statusEmoji = "started".equalsIgnoreCase(s.status()) ? "🟢" : "🔴";
                    sb.append(i + 1).append(". ")
                            .append(statusEmoji).append(" ")
                            .append(s.name())
                            .append(" (ID: ").append(s.id()).append(") - ")
                            .append(s.status()).append("\n");
                }
                event.getHook().editOriginal(sb.toString().trim()).queue();
            }
        } catch (NitradoConnectionException e) {
            // Req 5.1
            log.error("Error de conexión con Nitrado: {}", e.getMessage(), e);
            event.getHook().editOriginal("❌ No se pudo contactar con el servicio de Nitrado. Intenta de nuevo más tarde.").queue();
        } catch (NitradoAuthException e) {
            // Req 5.2
            log.error("Error de autenticación con Nitrado: {}", e.getMessage(), e);
            event.getHook().editOriginal("❌ Error de autenticación con la API de Nitrado. Contacta al administrador del bot.").queue();
        } catch (NitradoNotFoundException e) {
            // Req 5.3
            log.error("Servidor no encontrado en Nitrado: {}", e.getMessage(), e);
            event.getHook().editOriginal("❌ El servidor especificado no fue encontrado en Nitrado.").queue();
        } catch (NitradoApiException e) {
            // Req 5.4
            log.error("Error de API Nitrado (status={}): {}", e.getStatusCode(), e.getMessage(), e);
            event.getHook().editOriginal("❌ Ocurrió un error inesperado. Intenta de nuevo más tarde.").queue();
        } catch (Exception e) {
            // Req 5.4 - generic fallback
            log.error("Error inesperado ejecutando comando: {}", e.getMessage(), e);
            event.getHook().editOriginal("❌ Ocurrió un error inesperado. Intenta de nuevo más tarde.").queue();
        }
    }
}
