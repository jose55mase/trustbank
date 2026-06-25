package com.discord.bot.shop.service;

import com.discord.bot.shop.model.PlayerPosition;
import com.discord.bot.shop.parser.PlayerPositionParser;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service that retrieves player positions from the cached server logs.
 * Uses {@link LogCacheService} which accumulates log data across server restarts,
 * ensuring position history is never lost.
 */
@Service
public class PlayerPositionService {

    private static final Logger log = LoggerFactory.getLogger(PlayerPositionService.class);

    private final LogCacheService logCacheService;
    private final PlayerPositionParser positionParser;

    public PlayerPositionService(LogCacheService logCacheService, PlayerPositionParser positionParser) {
        this.logCacheService = logCacheService;
        this.positionParser = positionParser;
    }

    /**
     * Retrieves the last 3 unique positions for a player from the cached logs.
     *
     * @param dayzPlayerName the player's DayZ in-game name
     * @return list of up to 3 unique positions, or empty list if none found
     */
    public List<PlayerPosition> getLastPositions(String dayzPlayerName) {
        try {
            String logContent = logCacheService.getCachedLog();
            if (logContent.isBlank()) {
                log.debug("[PlayerPosition] Log cache is empty.");
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
