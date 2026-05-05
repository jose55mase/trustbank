package com.discord.bot.gamelogs.parser;

import com.discord.bot.gamelogs.model.GameLogEvent;

import java.util.Optional;

/**
 * Strategy interface for parsing individual lines from a DayZ server ADM log.
 *
 * <p>Each implementation handles a specific event category (connection, kill, etc.)
 * and provides both parsing (line → event) and formatting (event → line) capabilities
 * to support round-trip fidelity.
 */
public interface EventLineParser {

    /**
     * Attempts to parse a single log line into a structured event.
     *
     * @param line      the raw text of the log line
     * @param lineIndex the zero-based position of the line in the log file
     * @return an event if this parser recognizes the line, or empty otherwise
     */
    Optional<GameLogEvent> parseLine(String line, int lineIndex);

    /**
     * Formats a previously parsed event back into its ADM log line representation.
     *
     * @param event the event to format
     * @return the reconstructed log line text
     */
    String formatEvent(GameLogEvent event);

    /**
     * Indicates whether this parser can format the given event.
     *
     * @param event the event to check
     * @return true if this parser handles the event's category
     */
    boolean canFormat(GameLogEvent event);
}
