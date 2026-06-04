package com.discord.bot.gamelogs.controller;

import com.discord.bot.gamelogs.dto.GameLogEventDto;
import com.discord.bot.gamelogs.dto.GameLogEventMapper;
import com.discord.bot.gamelogs.exception.NitradoGatewayException;
import com.discord.bot.gamelogs.model.GameLogEvent;
import com.discord.bot.gamelogs.service.GameLogService;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * REST controller for game log events.
 * Exposes an endpoint to retrieve parsed and categorized events from the DayZ server ADM log.
 */
@RestController
@RequestMapping("/api/servers")
public class GameEventsController {

    private final GameLogService gameLogService;

    public GameEventsController(GameLogService gameLogService) {
        this.gameLogService = gameLogService;
    }

    /**
     * Returns parsed game events for a specific server, optionally filtered by category and search term.
     *
     * @param serviceId the Nitrado service ID
     * @param category  optional category filter (e.g., "connection", "player_kill")
     * @param search    optional search term (case-insensitive, matches message or playerName)
     * @return list of game log event DTOs sorted by timestamp descending
     */
    @GetMapping("/{serviceId}/game-events")
    public List<GameLogEventDto> getGameEvents(
            @PathVariable int serviceId,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String search) {
        List<GameLogEvent> events = gameLogService.getGameEvents(serviceId, category, search);
        return GameLogEventMapper.toDtoList(events);
    }

    /**
     * Handles NitradoGatewayException by returning HTTP 502 with a JSON error body.
     *
     * @param e the exception thrown when Nitrado API fails
     * @return a map containing the error message
     */
    @ExceptionHandler(NitradoGatewayException.class)
    @ResponseStatus(HttpStatus.BAD_GATEWAY)
    public Map<String, String> handleNitradoGatewayException(NitradoGatewayException e) {
        return Map.of("message", e.getMessage());
    }
}
