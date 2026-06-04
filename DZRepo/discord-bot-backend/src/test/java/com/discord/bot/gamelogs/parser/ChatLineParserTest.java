package com.discord.bot.gamelogs.parser;

import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for ChatLineParser covering DayZ ADM chat log format.
 * Validates: Requirements 1.5, 6.1
 */
class ChatLineParserTest {

    private ChatLineParser parser;

    @BeforeEach
    void setUp() {
        parser = new ChatLineParser();
    }

    @Test
    void parseLine_validChatLine_extractsAllFields() {
        String line = "14:40:00 | Player \"Talker\" (id=xyz789) placed Chat: Hola a todos!";

        Optional<GameLogEvent> result = parser.parseLine(line, 0);

        assertTrue(result.isPresent());
        GameLogEvent event = result.get();
        assertEquals("14:40:00", event.timestamp());
        assertEquals(GameLogCategory.CHAT, event.category());
        assertEquals("Talker", event.playerName());
        assertEquals("Hola a todos!", event.message());
        assertEquals("Hola a todos!", event.details().get("chatMessage"));
        assertEquals("xyz789", event.details().get("playerId"));
        assertEquals(0, event.lineIndex());
    }

    @Test
    void parseLine_preservesLineIndex() {
        String line = "10:00:00 | Player \"TestPlayer\" (id=abc123) placed Chat: Hello";

        Optional<GameLogEvent> result = parser.parseLine(line, 42);

        assertTrue(result.isPresent());
        assertEquals(42, result.get().lineIndex());
    }

    @Test
    void parseLine_playerNameWithSpaces() {
        String line = "08:15:30 | Player \"John Doe\" (id=player-001) placed Chat: GG everyone";

        Optional<GameLogEvent> result = parser.parseLine(line, 0);

        assertTrue(result.isPresent());
        assertEquals("John Doe", result.get().playerName());
        assertEquals("player-001", result.get().details().get("playerId"));
        assertEquals("GG everyone", result.get().details().get("chatMessage"));
    }

    @Test
    void parseLine_chatMessageWithSpecialCharacters() {
        String line = "12:00:00 | Player \"User\" (id=id1) placed Chat: Hello! How are you? :)";

        Optional<GameLogEvent> result = parser.parseLine(line, 0);

        assertTrue(result.isPresent());
        assertEquals("Hello! How are you? :)", result.get().details().get("chatMessage"));
    }

    @Test
    void parseLine_nonChatLine_returnsEmpty() {
        String line = "12:34:56 | Player \"SomePlayer\" is connected (id=abc123)";
        assertTrue(parser.parseLine(line, 0).isEmpty());
    }

    @Test
    void parseLine_disconnectionLine_returnsEmpty() {
        String line = "12:34:56 | Player \"SomePlayer\" has been disconnected";
        assertTrue(parser.parseLine(line, 0).isEmpty());
    }

    @Test
    void parseLine_emptyLine_returnsEmpty() {
        assertTrue(parser.parseLine("", 0).isEmpty());
    }

    @Test
    void parseLine_nullLine_returnsEmpty() {
        assertTrue(parser.parseLine(null, 0).isEmpty());
    }

    @Test
    void parseLine_blankLine_returnsEmpty() {
        assertTrue(parser.parseLine("   ", 0).isEmpty());
    }

    @Test
    void formatEvent_reconstructsOriginalLine() {
        String originalLine = "14:40:00 | Player \"Talker\" (id=xyz789) placed Chat: Hola a todos!";
        GameLogEvent event = parser.parseLine(originalLine, 0).orElseThrow();

        String formatted = parser.formatEvent(event);

        assertEquals(originalLine, formatted);
    }

    @Test
    void formatEvent_roundTrip_producesEquivalentEvent() {
        String line = "20:45:10 | Player \"NightOwl\" (id=night-42) placed Chat: Good night server!";
        GameLogEvent original = parser.parseLine(line, 5).orElseThrow();

        String formatted = parser.formatEvent(original);
        GameLogEvent reparsed = parser.parseLine(formatted, 5).orElseThrow();

        assertEquals(original.timestamp(), reparsed.timestamp());
        assertEquals(original.category(), reparsed.category());
        assertEquals(original.playerName(), reparsed.playerName());
        assertEquals(original.details().get("playerId"), reparsed.details().get("playerId"));
        assertEquals(original.details().get("chatMessage"), reparsed.details().get("chatMessage"));
    }

    @Test
    void canFormat_chatEvent_returnsTrue() {
        String line = "14:40:00 | Player \"Test\" (id=abc) placed Chat: Hello";
        GameLogEvent event = parser.parseLine(line, 0).orElseThrow();

        assertTrue(parser.canFormat(event));
    }

    @Test
    void canFormat_nullEvent_returnsFalse() {
        assertFalse(parser.canFormat(null));
    }

    @Test
    void canFormat_nonChatEvent_returnsFalse() {
        GameLogEvent connectionEvent = new GameLogEvent(
                "12:00:00",
                GameLogCategory.CONNECTION,
                "Player",
                "some message",
                Map.of(),
                0
        );

        assertFalse(parser.canFormat(connectionEvent));
    }
}
