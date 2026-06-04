package com.discord.bot.nitrado.controller;

import com.discord.bot.nitrado.dto.ActionResponse;
import com.discord.bot.nitrado.dto.BannedPlayerDto;
import com.discord.bot.nitrado.dto.GameServerDto;
import com.discord.bot.nitrado.dto.LogResponse;
import com.discord.bot.nitrado.dto.ServerAction;
import com.discord.bot.nitrado.service.NitradoApiClient;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * REST controller for game server operations.
 * Exposes endpoints for listing servers, checking status, performing actions,
 * retrieving logs, and managing the ban list.
 */
@RestController
@RequestMapping("/api/servers")
public class ServerController {

    private final NitradoApiClient nitradoClient;

    public ServerController(NitradoApiClient nitradoClient) {
        this.nitradoClient = nitradoClient;
    }

    /**
     * Returns the list of DayZ game servers.
     *
     * @return list of game servers
     */
    @GetMapping
    public List<GameServerDto> getServers() {
        return nitradoClient.getServers();
    }

    /**
     * Returns the detailed status of a specific game server.
     *
     * @param serviceId the Nitrado service ID
     * @return the server status
     */
    @GetMapping("/{serviceId}/status")
    public GameServerDto getServerStatus(@PathVariable int serviceId) {
        return nitradoClient.getServerStatus(serviceId);
    }

    /**
     * Executes a control action (start, stop, restart) on a game server.
     *
     * @param serviceId the Nitrado service ID
     * @param action    the action to perform (start, stop, restart)
     * @return confirmation response
     */
    @PostMapping("/{serviceId}/actions/{action}")
    public ActionResponse serverAction(@PathVariable int serviceId, @PathVariable String action) {
        ServerAction serverAction = ServerAction.fromString(action);
        nitradoClient.serverAction(serviceId, serverAction);
        return new ActionResponse("success", "Acción '" + action + "' ejecutada correctamente");
    }

    /**
     * Returns the server log content.
     *
     * @param serviceId the Nitrado service ID
     * @return the log content
     */
    @GetMapping("/{serviceId}/logs")
    public LogResponse getServerLogs(@PathVariable int serviceId) {
        String content = nitradoClient.getServerLogs(serviceId);
        return new LogResponse(content);
    }

    /**
     * Returns the list of banned players for a game server.
     * Alternative mapping under /api/servers/{serviceId}/banlist (Req 8.1).
     *
     * @param serviceId the Nitrado service ID
     * @return list of banned players
     */
    @GetMapping("/{serviceId}/banlist")
    public List<BannedPlayerDto> getBanList(@PathVariable int serviceId) {
        return nitradoClient.getBanList(serviceId);
    }

    /**
     * Unbans a player from a game server.
     * Alternative mapping under /api/servers/{serviceId}/banlist/{playerId} (Req 9.1).
     *
     * @param serviceId the Nitrado service ID
     * @param playerId  the ID of the player to unban
     * @return confirmation response
     */
    @DeleteMapping("/{serviceId}/banlist/{playerId}")
    public ActionResponse unbanPlayer(@PathVariable int serviceId, @PathVariable String playerId) {
        nitradoClient.unbanPlayer(serviceId, playerId);
        return new ActionResponse("success", "Jugador desbaneado correctamente");
    }
}
