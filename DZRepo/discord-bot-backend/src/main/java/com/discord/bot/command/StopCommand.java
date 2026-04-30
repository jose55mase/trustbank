package com.discord.bot.command;

import com.discord.bot.nitrado.dto.ServerAction;
import com.discord.bot.nitrado.service.NitradoApiClient;

import org.springframework.stereotype.Component;

/**
 * Slash command that stops a DayZ server hosted on Nitrado.
 * Restricted to Discord administrators only.
 */
@Component
public class StopCommand extends AbstractServerCommand {

    public StopCommand(NitradoApiClient nitradoApiClient) {
        super(nitradoApiClient);
    }

    @Override
    public String getName() {
        return "stop";
    }

    @Override
    public String getDescription() {
        return "Detiene el servidor DayZ (solo administradores)";
    }

    @Override
    protected ServerAction getAction() {
        return ServerAction.STOP;
    }

    @Override
    protected String getSuccessMessage(String serverName) {
        return "El servidor '" + serverName + "' se está deteniendo.";
    }
}
