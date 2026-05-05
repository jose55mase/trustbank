package com.discord.bot.gamelogs.parser;

import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for GameLogParser orchestrator component.
 * Validates: Requirements 1.7, 6.1, 6.3
 */
class GameLogParserTest {

    private GameLogParser parser;

    @BeforeEach
    void setUp() {
        List<EventLineParser> parsers = List.of(
                new ConnectionLineParser(),
                new DisconnectionLineParser(),
                new PlayerKillLineParser(),
                new ZombieKillLineParser(),
                new ChatLineParser(),
                new UnknownLineParser()
        );
        parser = new GameLogParser(parsers);
    }

    @Test
    void parseAll_nullContent_returnsEmptyList() {
        List<GameLogEvent> events = parser.parseAll(null);
        assertTrue(events.isEmpty());
    }

    @Test
    void parseAll_emptyContent_returnsEmptyList() {
        List<GameLogEvent> events = parser.parseAll("");
        assertTrue(events.isEmpty());
    }

    @Test
    void parseAll_blankContent_returnsEmptyList() {
        List<GameLogEvent> events = parser.parseAll("   \n  \n   ");
        assertTrue(events.isEmpty());
    }

    @Test
    void parseAll_singleConnectionLine_parsesCorrectly() {
        String content = "14:32:05 | Player \"SurvivorJoe\" is connected (id=abc123)";

        List<GameLogEvent> events = parser.parseAll(content);

        assertEquals(1, events.size());
        GameLogEvent event = events.get(0);
        assertEquals(GameLogCategory.CONNECTION, event.category());
        assertEquals("SurvivorJoe", event.playerName());
        assertEquals("14:32:05", event.timestamp());
    }

    @Test
    void parseAll_multipleLines_parsesAllEvents() {
        String content = String.join("\n",
                "14:32:05 | Player \"SurvivorJoe\" is connected (id=abc123)",
                "14:33:00 | Player \"SurvivorJoe\" has been disconnected",
                "14:34:00 | Some unknown log line"
        );

        List<GameLogEvent> events = parser.parseAll(content);

        assertEquals(3, events.size());
        assertEquals(GameLogCategory.CONNECTION, events.get(0).category());
        assertEquals(GameLogCategory.DISCONNECTION, events.get(1).category());
        assertEquals(GameLogCategory.UNKNOWN, events.get(2).category());
    }

    @Test
    void parseAll_skipsBlankLines() {
        String content = String.join("\n",
                "14:32:05 | Player \"Joe\" is connected (id=abc)",
                "",
                "   ",
                "14:33:00 | Player \"Joe\" has been disconnected"
        );

        List<GameLogEvent> events = parser.parseAll(content);

        assertEquals(2, events.size());
        assertEquals(GameLogCategory.CONNECTION, events.get(0).category());
        assertEquals(GameLogCategory.DISCONNECTION, events.get(1).category());
    }

    @Test
    void parseAll_windowsLineEndings_parsesCorrectly() {
        String content = "14:32:05 | Player \"Joe\" is connected (id=abc)\r\n14:33:00 | Player \"Joe\" has been disconnected";

        List<GameLogEvent> events = parser.parseAll(content);

        assertEquals(2, events.size());
    }

    @Test
    void parseAll_unrecognizedLines_classifiedAsUnknown() {
        String content = "This is not a valid ADM log line";

        List<GameLogEvent> events = parser.parseAll(content);

        assertEquals(1, events.size());
        assertEquals(GameLogCategory.UNKNOWN, events.get(0).category());
        assertEquals("This is not a valid ADM log line", events.get(0).details().get("rawLine"));
    }

    @Test
    void parseAll_preservesLineIndex() {
        String content = String.join("\n",
                "14:32:05 | Player \"Joe\" is connected (id=abc)",
                "",
                "14:34:00 | Unknown line"
        );

        List<GameLogEvent> events = parser.parseAll(content);

        assertEquals(2, events.size());
        assertEquals(0, events.get(0).lineIndex());
        assertEquals(2, events.get(1).lineIndex());
    }

    @Test
    void parseAll_unknownParserIsAlwaysLast() {
        // Even if UnknownLineParser is first in the input list, it should be sorted last
        List<EventLineParser> parsersWithUnknownFirst = List.of(
                new UnknownLineParser(),
                new ConnectionLineParser(),
                new DisconnectionLineParser()
        );
        GameLogParser parserWithReorder = new GameLogParser(parsersWithUnknownFirst);

        String content = "14:32:05 | Player \"Joe\" is connected (id=abc)";
        List<GameLogEvent> events = parserWithReorder.parseAll(content);

        assertEquals(1, events.size());
        assertEquals(GameLogCategory.CONNECTION, events.get(0).category());
    }

    @Test
    void formatEvent_delegatesToCorrectParser() {
        String line = "14:32:05 | Player \"SurvivorJoe\" is connected (id=abc123)";
        GameLogEvent event = parser.parseAll(line).get(0);

        String formatted = parser.formatEvent(event);

        assertEquals(line, formatted);
    }

    @Test
    void formatEvent_unknownEvent_formatsViaUnknownParser() {
        GameLogEvent unknownEvent = new GameLogEvent(
                "14:00:00",
                GameLogCategory.UNKNOWN,
                "",
                "some raw line",
                Map.of("rawLine", "some raw line"),
                0
        );

        String formatted = parser.formatEvent(unknownEvent);

        assertEquals("some raw line", formatted);
    }

    @Test
    void formatEvent_noParserCanFormat_fallsBackToMessage() {
        // Create an event with HIT category which no parser handles
        GameLogEvent hitEvent = new GameLogEvent(
                "14:00:00",
                GameLogCategory.HIT,
                "Player",
                "hit event message",
                Map.of(),
                0
        );

        String formatted = parser.formatEvent(hitEvent);

        assertEquals("hit event message", formatted);
    }

    @Test
    void parseAll_mixedValidAndInvalidLines_noExceptions() {
        String content = String.join("\n",
                "14:32:05 | Player \"Joe\" is connected (id=abc)",
                "garbage line with special chars !@#$%",
                "14:33:00 | Player \"Joe\" has been disconnected",
                "another random line",
                ""
        );

        assertDoesNotThrow(() -> {
            List<GameLogEvent> events = parser.parseAll(content);
            assertEquals(4, events.size());
        });
    }

    @Test
    void parseAll_eventsCountLessThanOrEqualToNonBlankLines() {
        String content = String.join("\n",
                "line1",
                "",
                "line2",
                "   ",
                "line3"
        );

        List<GameLogEvent> events = parser.parseAll(content);

        // 3 non-blank lines, should produce exactly 3 events
        assertEquals(3, events.size());
    }
}
