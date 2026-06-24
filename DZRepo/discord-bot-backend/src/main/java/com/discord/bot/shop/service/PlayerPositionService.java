package com.discord.bot.shop.service;

import com.discord.bot.nitrado.service.NitradoApiClient;
import com.discord.bot.shop.model.PlayerPosition;
import com.discord.bot.shop.parser.PlayerPositionParser;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service that retrieves player positions from DayZ server logs.
 * Used by the shop system to let players select their delivery location.
 */
@Service
public class PlayerPositionService {

    private static final Logger log = LoggerFactory.getLogger(PlayerPositionService.class);

    private final NitradoApiClient nitradoApiClient;
    private final PlayerPositionParser positionParser;

    @Value("${shop.nitrado.service-id:0}")
    private int serviceId;

    public PlayerPositionService(NitradoApiClient nitradoApiClient, PlayerPositionParser positionParser) {
        this.nitradoApiClient = nitradoApiClient;
        this.positionParser = positionParser;
    }

    /**
     * Retrieves the last 3 unique positions for a player from the server logs.
     *
     * @param dayzPlayerName the player's DayZ in-game name
     * @return list of up to 3 unique positions, or empty list if none found
     */
    public List<PlayerPosition> getLastPositions(String dayzPlayerName) {
        if (serviceId <= 0) {
            log.warn("[PlayerPosition] No service ID configured for shop.");
            return List.of();
        }

        try {
            String logContent = nitradoApiClient.getServerLogs(serviceId);
            if (logContent == null || logContent.isBlank()) {
                log.debug("[PlayerPosition] Log content is empty.");
                return List.of();
            }

            List<PlayerPosition> positions = positionParser.getLastUniquePositions(logContent, dayzPlayerName, 3);
            log.debug("[PlayerPosition] Found {} unique positions for player '{}'", positions.size(), dayzPlayerName);
            return positions;
        } catch (Exception e) {
            log.error("[PlayerPosition] Error retrieving positions for '{}': {}", dayzPlayerName, e.getMessage());
            return List.of();
        }
    }
}
