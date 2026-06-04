package com.discord.bot.gamelogs.parser;

import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for ConnectionLineParser covering DayZ ADM connection log format.
 * Validates: Requirements 1.1, 6.1
 */
class ConnectionLineParserTest {

    private ConnectionLineParser parser;

    @BeforeEach
    void setUp() {
        parser = new ConnectionLineParser();
    }

    @Test
    void parseLine_validConnectionLine_extractsAllFields() {
        String line = "14:32:05 | Player \"SurvivorJoe\" is connected (id=abc123)";

        Optional<GameLogEvent> result = parser.parseLine(line, 0);

        assertTrue(result.isPresent());
        GameLogEvent event = result.get();
        assertEquals("14:32:05", event.timestamp());
        assertEquals(GameLogCategory.CONNECTION, event.category());
        assertEquals("SurvivorJoe", event.playerName());
        assertEquals(line, event.message());
        assertEquals("abc123", event.details().get("playerId"));
        assertEquals(0, event.lineIndex());
    }

    @Test
    void parseLine_preservesLineIndex() {
        String line = "10:00:00 | Player \"TestPlayer\" is connected (id=xyz789)";

        Optional<GameLogEvent> result = parser.parseLine(line, 42);

        assertTrue(result.isPresent());
        assertEquals(42, result.get().lineIndex());
    }

    @Test
    void parseLine_playerNameWithSpaces() {
        String line = "08:15:30 | Player \"John Doe\" is connected (id=player-001)";

        Optional<GameLogEvent> result = parser.parseLine(line, 0);

        assertTrue(result.isPresent());
        assertEquals("John Doe", result.get().playerName());
        assertEquals("player-001", result.get().details().get("playerId"));
    }

    @Test
    void parseLine_nonConnectionLine_returnsEmpty() {
        String line = "12:34:56 | Player \"SomePlayer\" has been disconnected";
        assertTrue(parser.parseLine(line, 0).isEmpty());
    }

    @Test
    void parseLine_killLine_returnsEmpty() {
        String line = "12:00:05 | Player \"Victim\" (id=abc pos=<100.0, 200.0, 50.0>) " +
                "killed by Player \"Killer\" (id=def pos=<110.0, 210.0, 55.0>) with M4-A1 from 50.0 meters";
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
        String originalLine = "14:32:05 | Player \"SurvivorJoe\" is connected (id=abc123)";
        GameLogEvent event = parser.parseLine(originalLine, 0).orElseThrow();

        String formatted = parser.formatEvent(event);

        assertEquals(originalLine, formatted);
    }

    @Test
    void formatEvent_roundTrip_producesEquivalentEvent() {
        String line = "20:45:10 | Player \"NightOwl\" is connected (id=night-42)";
        GameLogEvent original = parser.parseLine(line, 5).orElseThrow();

        String formatted = parser.formatEvent(original);
        GameLogEvent reparsed = parser.parseLine(formatted, 5).orElseThrow();

        assertEquals(original.timestamp(), reparsed.timestamp());
        assertEquals(original.category(), reparsed.category());
        assertEquals(original.playerName(), reparsed.playerName());
        assertEquals(original.details().get("playerId"), reparsed.details().get("playerId"));
    }

    @Test
    void canFormat_connectionEvent_returnsTrue() {
        String line = "14:32:05 | Player \"Test\" is connected (id=abc)";
        GameLogEvent event = parser.parseLine(line, 0).orElseThrow();

        assertTrue(parser.canFormat(event));
    }

    @Test
    void canFormat_nullEvent_returnsFalse() {
        assertFalse(parser.canFormat(null));
    }

    @Test
    void canFormat_nonConnectionEvent_returnsFalse() {
        GameLogEvent disconnectionEvent = new GameLogEvent(
                "12:00:00",
                GameLogCategory.DISCONNECTION,
                "Player",
                "some message",
                java.util.Map.of(),
                0
        );

        assertFalse(parser.canFormat(disconnectionEvent));
    }
}
