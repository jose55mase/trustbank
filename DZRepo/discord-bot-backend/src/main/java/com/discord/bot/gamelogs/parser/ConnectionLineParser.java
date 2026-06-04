package com.discord.bot.gamelogs.parser;

import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Parser for player connection events from the DayZ server_log.ADM.
 *
 * <p>Matches lines with the format:
 * {@code HH:mm:ss | Player "NAME" is connected (id=ID)}
 *
 * <p>Extracts timestamp, playerName, and playerId into the event details.
 */
@Component
public class ConnectionLineParser implements EventLineParser {

    /**
     * Regex capturing groups for Xbox/PS format:
     * {@code HH:mm:ss | Player "NAME" (id=ID pos=<X, Y, Z>) is connected}
     * 1 = timestamp (HH:mm:ss)
     * 2 = player name
     * 3 = player id
     *
     * Also supports PC format: {@code HH:mm:ss | Player "NAME" is connected (id=ID)}
     */
    private static final Pattern CONNECTION_PATTERN_CONSOLE = Pattern.compile(
            "^(\\d{2}:\\d{2}:\\d{2}) \\| Player \"(.+?)\" \\(id=(.+?)(?:\\s+pos=<[^>]+>)?\\) is connected$"
    );

    private static final Pattern CONNECTION_PATTERN_PC = Pattern.compile(
            "^(\\d{2}:\\d{2}:\\d{2}) \\| Player \"(.+?)\" is connected \\(id=(.+?)\\)$"
    );

    @Override
    public Optional<GameLogEvent> parseLine(String line, int lineIndex) {
        if (line == null || line.isBlank()) {
            return Optional.empty();
        }

        String trimmed = line.trim();

        // Try console format first (Xbox/PS): Player "NAME" (id=ID pos=<X,Y,Z>) is connected
        Matcher matcher = CONNECTION_PATTERN_CONSOLE.matcher(trimmed);
        if (!matcher.matches()) {
            // Try PC format: Player "NAME" is connected (id=ID)
            matcher = CONNECTION_PATTERN_PC.matcher(trimmed);
            if (!matcher.matches()) {
                return Optional.empty();
            }
        }

        String timestamp = matcher.group(1);
        String playerName = matcher.group(2);
        String playerId = matcher.group(3);

        Map<String, Object> details = Map.of(
                "playerId", playerId
        );

        return Optional.of(new GameLogEvent(
                timestamp,
                GameLogCategory.CONNECTION,
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
        String playerId = (String) event.details().get("playerId");

        return String.format("%s | Player \"%s\" is connected (id=%s)",
                timestamp, playerName, playerId);
    }

    @Override
    public boolean canFormat(GameLogEvent event) {
        return event != null && event.category() == GameLogCategory.CONNECTION;
    }
}
