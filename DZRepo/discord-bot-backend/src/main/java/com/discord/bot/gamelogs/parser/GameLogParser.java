package com.discord.bot.gamelogs.parser;

import com.discord.bot.gamelogs.model.GameLogEvent;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Orchestrator component that delegates log line parsing to the appropriate
 * {@link EventLineParser} implementation.
 *
 * <p>Iterates through registered parsers in order, using the first one that
 * successfully matches each line. {@link UnknownLineParser} is always placed
 * last as a fallback to ensure every non-blank line produces an event.
 */
@Component
public class GameLogParser {

    private final List<EventLineParser> parsers;

    /**
     * Constructs the parser with all available {@link EventLineParser} beans.
     * Sorts the list so that {@link UnknownLineParser} is always last.
     *
     * @param parsers all EventLineParser implementations injected by Spring
     */
    public GameLogParser(List<EventLineParser> parsers) {
        this.parsers = new ArrayList<>(parsers);
        this.parsers.sort((a, b) -> {
            boolean aIsUnknown = a instanceof UnknownLineParser;
            boolean bIsUnknown = b instanceof UnknownLineParser;
            if (aIsUnknown && !bIsUnknown) return 1;
            if (!aIsUnknown && bIsUnknown) return -1;
            return 0;
        });
    }

    /**
     * Parses all lines from the given log content into structured events.
     *
     * <p>Splits the content by newlines, skips blank lines, and delegates each
     * non-empty line to the first parser that returns a present Optional.
     *
     * @param logContent the raw ADM log content (may be null or blank)
     * @return list of parsed events, empty if input is null/blank
     */
    public List<GameLogEvent> parseAll(String logContent) {
        if (logContent == null || logContent.isBlank()) {
            return List.of();
        }

        String[] lines = logContent.split("\\r?\\n");
        List<GameLogEvent> events = new ArrayList<>();

        for (int i = 0; i < lines.length; i++) {
            String line = lines[i];
            if (line.isBlank()) {
                continue;
            }

            for (EventLineParser parser : parsers) {
                Optional<GameLogEvent> event = parser.parseLine(line, i);
                if (event.isPresent()) {
                    events.add(event.get());
                    break;
                }
            }
        }

        return events;
    }

    /**
     * Formats a parsed event back into its ADM log line representation.
     *
     * <p>Delegates to the first parser that can format the given event.
     * Falls back to the event's message if no parser can handle it.
     *
     * @param event the event to format
     * @return the formatted log line text
     */
    public String formatEvent(GameLogEvent event) {
        for (EventLineParser parser : parsers) {
            if (parser.canFormat(event)) {
                return parser.formatEvent(event);
            }
        }
        return event.message();
    }
}
