package com.discord.bot.gamelogs.service;

import com.discord.bot.gamelogs.exception.NitradoGatewayException;
import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import com.discord.bot.gamelogs.parser.GameLogParser;
import com.discord.bot.nitrado.service.NitradoApiClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service responsible for fetching, parsing, filtering, and sorting game log events
 * from the Nitrado server logs.
 */
@Service
public class GameLogService {

    private static final Logger log = LoggerFactory.getLogger(GameLogService.class);

    private final NitradoApiClient nitradoApiClient;
    private final GameLogParser gameLogParser;

    public GameLogService(NitradoApiClient nitradoApiClient, GameLogParser gameLogParser) {
        this.nitradoApiClient = nitradoApiClient;
        this.gameLogParser = gameLogParser;
    }

    /**
     * Retrieves game events from the server logs, applying optional filters and sorting.
     *
     * @param serviceId the Nitrado service ID
     * @param category  optional category filter (case-insensitive enum name match)
     * @param search    optional search term (case-insensitive, matches message or playerName)
     * @return filtered and sorted list of game log events (most recent first)
     * @throws NitradoGatewayException if the Nitrado API fails
     */
    public List<GameLogEvent> getGameEvents(int serviceId, String category, String search) {
        String logContent;
        try {
            logContent = nitradoApiClient.getServerLogs(serviceId);
        } catch (Exception e) {
            log.error("Error fetching server logs from Nitrado (serviceId={}): {}", serviceId, e.getMessage(), e);
            throw new NitradoGatewayException(
                    "Error al obtener logs del servidor Nitrado (serviceId=" + serviceId + "): " + e.getMessage(), e);
        }

        List<GameLogEvent> events = gameLogParser.parseAll(logContent);

        // Filter by category if provided
        if (category != null && !category.isBlank()) {
            GameLogCategory matchedCategory = parseCategorySafe(category);
            if (matchedCategory != null) {
                events = events.stream()
                        .filter(event -> event.category() == matchedCategory)
                        .collect(Collectors.toList());
            }
            // If category doesn't match any valid enum value, return all events (don't throw)
        }

        // Filter by search term if provided (case-insensitive on message and playerName)
        if (search != null && !search.isBlank()) {
            String searchLower = search.toLowerCase();
            events = events.stream()
                    .filter(event -> {
                        String message = event.message() != null ? event.message().toLowerCase() : "";
                        String playerName = event.playerName() != null ? event.playerName().toLowerCase() : "";
                        return message.contains(searchLower) || playerName.contains(searchLower);
                    })
                    .collect(Collectors.toList());
        }

        // Sort descending by timestamp, then by lineIndex descending for same timestamps
        events.sort(Comparator.comparing(GameLogEvent::timestamp).reversed()
                .thenComparing(Comparator.comparingInt(GameLogEvent::lineIndex).reversed()));

        return events;
    }

    /**
     * Safely parses a category string to a {@link GameLogCategory} enum value.
     *
     * @param category the category string to parse
     * @return the matching enum value, or null if no match
     */
    private GameLogCategory parseCategorySafe(String category) {
        try {
            return GameLogCategory.valueOf(category.toUpperCase());
        } catch (IllegalArgumentException e) {
            log.debug("Invalid category filter '{}', returning all events", category);
            return null;
        }
    }
}
