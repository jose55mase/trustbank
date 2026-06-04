package com.discord.bot.gamelogs.parser;

import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Parser for player disconnection events from the DayZ server_log.ADM.
 *
 * <p>Matches lines with the format:
 * {@code HH:mm:ss | Player "NAME" has been disconnected}
 *
 * <p>Extracts timestamp and playerName into the event.
 */
@Component
public class DisconnectionLineParser implements EventLineParser {

    /**
     * Matches both formats:
     * Xbox/PS: {@code HH:mm:ss | Player "NAME" (id=ID pos=<X, Y, Z>) has been disconnected}
     * PC: {@code HH:mm:ss | Player "NAME" has been disconnected}
     *
     * Capturing groups: 1=timestamp, 2=player name
     */
    private static final Pattern DISCONNECTION_PATTERN_CONSOLE = Pattern.compile(
            "^(\\d{2}:\\d{2}:\\d{2}) \\| Player \"(.+?)\" \\(id=.+?(?:\\s+pos=<[^>]+>)?\\) has been disconnected$"
    );

    private static final Pattern DISCONNECTION_PATTERN_PC = Pattern.compile(
            "^(\\d{2}:\\d{2}:\\d{2}) \\| Player \"(.+?)\" has been disconnected$"
    );

    @Override
    public Optional<GameLogEvent> parseLine(String line, int lineIndex) {
        if (line == null || line.isBlank()) {
            return Optional.empty();
        }

        String trimmed = line.trim();

        // Try console format first (Xbox/PS): Player "NAME" (id=... pos=<...>) has been disconnected
        Matcher matcher = DISCONNECTION_PATTERN_CONSOLE.matcher(trimmed);
        if (!matcher.matches()) {
            // Try PC format: Player "NAME" has been disconnected
            matcher = DISCONNECTION_PATTERN_PC.matcher(trimmed);
            if (!matcher.matches()) {
                return Optional.empty();
            }
        }

        String timestamp = matcher.group(1);
        String playerName = matcher.group(2);

        Map<String, Object> details = Map.of();

        return Optional.of(new GameLogEvent(
                timestamp,
                GameLogCategory.DISCONNECTION,
                playerName,
                trimmed,
                details,
                lineIndex
        ));
    }

    @Override
    public String formatEvent(GameLogEvent event) {
        String timestamp = event.timestamp();
        String playerName = event.playerName();

        return String.format("%s | Player \"%s\" has been disconnected",
                timestamp, playerName);
    }

    @Override
    public boolean canFormat(GameLogEvent event) {
        return event != null && event.category() == GameLogCategory.DISCONNECTION;
    }
}
