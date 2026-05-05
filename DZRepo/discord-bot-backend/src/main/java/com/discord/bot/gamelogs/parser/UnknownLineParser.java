package com.discord.bot.gamelogs.parser;

import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Fallback parser for unrecognized lines from the DayZ server_log.ADM.
 *
 * <p>This parser always matches any non-null, non-blank line and classifies it
 * as {@link GameLogCategory#UNKNOWN}. It attempts to extract a timestamp if the
 * line starts with an {@code HH:mm:ss} pattern; otherwise, the timestamp is empty.
 *
 * <p>This parser should always be the last one tried by the orchestrator so that
 * recognized patterns are handled by their specific parsers first.
 */
@Component
public class UnknownLineParser implements EventLineParser {

    /**
     * Pattern to extract a leading timestamp in HH:mm:ss format.
     */
    private static final Pattern TIMESTAMP_PATTERN = Pattern.compile(
            "^(\\d{2}:\\d{2}:\\d{2})\\b.*"
    );

    @Override
    public Optional<GameLogEvent> parseLine(String line, int lineIndex) {
        if (line == null || line.isBlank()) {
            return Optional.empty();
        }

        String trimmedLine = line.trim();
        String timestamp = "";

        Matcher matcher = TIMESTAMP_PATTERN.matcher(trimmedLine);
        if (matcher.matches()) {
            timestamp = matcher.group(1);
        }

        Map<String, Object> details = Map.of("rawLine", trimmedLine);

        return Optional.of(new GameLogEvent(
                timestamp,
                GameLogCategory.UNKNOWN,
                "",
                trimmedLine,
                details,
                lineIndex
        ));
    }

    @Override
    public String formatEvent(GameLogEvent event) {
        return (String) event.details().get("rawLine");
    }

    @Override
    public boolean canFormat(GameLogEvent event) {
        return event != null && event.category() == GameLogCategory.UNKNOWN;
    }
}
