package com.discord.bot.gamelogs.model;

import java.util.Map;

/**
 * Immutable representation of a single event parsed from the DayZ server ADM log.
 *
 * @param timestamp  the timestamp from the log line (HH:mm:ss format)
 * @param category   the classification of this event
 * @param playerName the name of the primary player involved in the event (empty for unknown)
 * @param message    a human-readable representation of the event
 * @param details    type-specific data extracted from the log line
 * @param lineIndex  the zero-based index of the line in the log file
 */
public record GameLogEvent(
    String timestamp,
    GameLogCategory category,
    String playerName,
    String message,
    Map<String, Object> details,
    int lineIndex
) {}
