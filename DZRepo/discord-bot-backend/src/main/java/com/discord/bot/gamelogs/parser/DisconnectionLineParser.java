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
     * Regex capturing groups:
     * 1 = timestamp (HH:mm:ss)
     * 2 = player name
     */
    private static final Pattern DISCONNECTION_PATTERN = Pattern.compile(
            "^(\\d{2}:\\d{2}:\\d{2}) \\| Player \"(.+?)\" has been disconnected$"
    );

    @Override
    public Optional<GameLogEvent> parseLine(String line, int lineIndex) {
        if (line == null || line.isBlank()) {
            return Optional.empty();
        }

        Matcher matcher = DISCONNECTION_PATTERN.matcher(line.trim());
        if (!matcher.matches()) {
            return Optional.empty();
        }

        String timestamp = matcher.group(1);
        String playerName = matcher.group(2);

        Map<String, Object> details = Map.of();

        return Optional.of(new GameLogEvent(
                timestamp,
                GameLogCategory.DISCONNECTION,
                playerName,
                line.trim(),
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
