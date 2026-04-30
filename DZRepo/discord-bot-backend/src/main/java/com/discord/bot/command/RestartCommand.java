package com.discord.bot.command;

import com.discord.bot.nitrado.dto.ServerAction;
import com.discord.bot.nitrado.service.NitradoApiClient;

import org.springframework.stereotype.Component;

/**
 * Slash command that restarts a DayZ server hosted on Nitrado.
 * Restricted to Discord administrators only.
 */
@Component
public class RestartCommand extends AbstractServerCommand {

    public RestartCommand(NitradoApiClient nitradoApiClient) {
        super(nitradoApiClient);
    }

    @Override
    public String getName() {
        return "restart";
    }

    @Override
    public String getDescription() {
        return "Reinicia el servidor DayZ (solo administradores)";
    }

    @Override
    protected ServerAction getAction() {
        return ServerAction.RESTART;
    }

    @Override
    protected String getSuccessMessage(String serverName) {
        return "El servidor '" + serverName + "' se está reiniciando.";
    }
}
