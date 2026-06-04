package com.discord.bot.gamelogs.dto;

import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;

import java.util.List;

/**
 * Utility class for mapping {@link GameLogEvent} domain objects to {@link GameLogEventDto} DTOs.
 */
public final class GameLogEventMapper {

    private GameLogEventMapper() {
        // Utility class — prevent instantiation
    }

    /**
     * Converts a domain {@link GameLogEvent} to a {@link GameLogEventDto}.
     *
     * @param event the domain event to convert
     * @return the corresponding DTO
     */
    public static GameLogEventDto toDto(GameLogEvent event) {
        return new GameLogEventDto(
            event.timestamp(),
            categoryToString(event.category()),
            event.playerName(),
            event.message(),
            event.details()
        );
    }

    /**
     * Converts a list of domain {@link GameLogEvent} objects to a list of {@link GameLogEventDto} DTOs.
     *
     * @param events the domain events to convert
     * @return the corresponding list of DTOs
     */
    public static List<GameLogEventDto> toDtoList(List<GameLogEvent> events) {
        return events.stream()
            .map(GameLogEventMapper::toDto)
            .toList();
    }

    /**
     * Converts a {@link GameLogCategory} enum value to its lowercase snake_case string representation.
     */
    private static String categoryToString(GameLogCategory category) {
        return switch (category) {
            case CONNECTION -> "connection";
            case DISCONNECTION -> "disconnection";
            case PLAYER_KILL -> "player_kill";
            case ZOMBIE_KILL -> "zombie_kill";
            case CHAT -> "chat";
            case HIT -> "hit";
            case UNKNOWN -> "unknown";
        };
    }
}
