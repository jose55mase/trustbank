package com.discord.bot.gamelogs.parser;

import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Parser for player chat events from the DayZ server_log.ADM.
 *
 * <p>Matches lines with the format:
 * {@code HH:mm:ss | Player "NAME" (id=ID) placed Chat: MESSAGE}
 *
 * <p>Extracts timestamp, playerName, playerId, and chatMessage into the event details.
 */
@Component
public class ChatLineParser implements EventLineParser {

    /**
     * Regex capturing groups:
     * 1 = timestamp (HH:mm:ss)
     * 2 = player name
     * 3 = player id
     * 4 = chat message
     */
    private static final Pattern CHAT_PATTERN = Pattern.compile(
            "^(\\d{2}:\\d{2}:\\d{2}) \\| Player \"(.+?)\" \\(id=(.+?)\\) placed Chat: (.+)$"
    );

    @Override
    public Optional<GameLogEvent> parseLine(String line, int lineIndex) {
        if (line == null || line.isBlank()) {
            return Optional.empty();
        }

        Matcher matcher = CHAT_PATTERN.matcher(line.trim());
        if (!matcher.matches()) {
            return Optional.empty();
        }

        String timestamp = matcher.group(1);
        String playerName = matcher.group(2);
        String playerId = matcher.group(3);
        String chatMessage = matcher.group(4);

        Map<String, Object> details = Map.of(
                "chatMessage", chatMessage,
                "playerId", playerId
        );

        return Optional.of(new GameLogEvent(
                timestamp,
                GameLogCategory.CHAT,
                playerName,
                chatMessage,
                details,
                lineIndex
        ));
    }

    @Override
    public String formatEvent(GameLogEvent event) {
        String timestamp = event.timestamp();
        String playerName = event.playerName();
        String playerId = (String) event.details().get("playerId");
        String chatMessage = (String) event.details().get("chatMessage");

        return String.format("%s | Player \"%s\" (id=%s) placed Chat: %s",
                timestamp, playerName, playerId, chatMessage);
    }

    @Override
    public boolean canFormat(GameLogEvent event) {
        return event != null && event.category() == GameLogCategory.CHAT;
    }
}
