package com.discord.bot.nitrado.controller;

import com.discord.bot.nitrado.dto.ActionResponse;
import com.discord.bot.nitrado.dto.BanRequest;
import com.discord.bot.nitrado.dto.PlayerDto;
import com.discord.bot.nitrado.service.NitradoApiClient;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * REST controller for player operations on a game server.
 * Exposes endpoints for listing players, kicking, and banning.
 */
@RestController
@RequestMapping("/api/servers/{serviceId}/players")
public class PlayerController {

    private final NitradoApiClient nitradoClient;

    public PlayerController(NitradoApiClient nitradoClient) {
        this.nitradoClient = nitradoClient;
    }

    /**
     * Returns the list of players currently connected to a game server.
     *
     * @param serviceId the Nitrado service ID
     * @return list of connected players
     */
    @GetMapping
    public List<PlayerDto> getPlayers(@PathVariable int serviceId) {
        return nitradoClient.getPlayers(serviceId);
    }

    /**
     * Kicks a player from a game server.
     *
     * @param serviceId the Nitrado service ID
     * @param playerId  the ID of the player to kick
     * @return confirmation response
     */
    @PostMapping("/{playerId}/kick")
    public ActionResponse kickPlayer(@PathVariable int serviceId, @PathVariable String playerId) {
        nitradoClient.kickPlayer(serviceId, playerId);
        return new ActionResponse("success", "Jugador expulsado correctamente");
    }

    /**
     * Bans a player from a game server with an optional reason.
     *
     * @param serviceId the Nitrado service ID
     * @param playerId  the ID of the player to ban
     * @param request   optional ban request containing the reason, may be null
     * @return confirmation response
     */
    @PostMapping("/{playerId}/ban")
    public ActionResponse banPlayer(
            @PathVariable int serviceId,
            @PathVariable String playerId,
            @RequestBody(required = false) BanRequest request) {
        String reason = (request != null) ? request.reason() : null;
        nitradoClient.banPlayer(serviceId, playerId, reason);
        return new ActionResponse("success", "Jugador baneado correctamente");
    }
}
