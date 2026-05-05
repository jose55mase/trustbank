package com.discord.bot.gamelogs.dto;

import java.util.Map;

/**
 * DTO representing a single game log event returned by the REST API.
 *
 * @param timestamp  the timestamp from the log line (HH:mm:ss format)
 * @param category   lowercase string representation of the event category (e.g., "connection", "player_kill")
 * @param playerName the name of the primary player involved in the event
 * @param message    a human-readable representation of the event
 * @param details    type-specific data extracted from the log line
 */
public record GameLogEventDto(
    String timestamp,
    String category,
    String playerName,
    String message,
    Map<String, Object> details
) {}
