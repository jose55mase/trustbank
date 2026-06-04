package com.discord.bot.killfeed.service;

import com.discord.bot.killfeed.model.KillEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for LogParser covering DayZ ADM log format examples and edge cases.
 * Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
 */
class LogParserTest {

    private LogParser parser;

    @BeforeEach
    void setUp() {
        parser = new LogParser();
    }

    // --- parseLine tests ---

    @Test
    void parseLine_validKillLine_extractsAllFields() {
        String line = "12:34:56 | Player \"VictimPlayer\" (id=abc123 pos=<1000.5, 200.3, 50.1>) " +
                "killed by Player \"KillerPlayer\" (id=def456 pos=<1100.7, 210.4, 55.2>) " +
                "with M4-A1 from 150.3 meters";

        Optional<KillEvent> result = parser.parseLine(line, 0);

        assertTrue(result.isPresent());
        KillEvent event = result.get();
        assertEquals("KillerPlayer", event.killerName());
        assertEquals("VictimPlayer", event.victimName());
        assertEquals("M4-A1", event.weapon());
        assertEquals(150.3, event.distance(), 0.01);
        assertEquals(1100.7, event.killerX(), 0.01);
        assertEquals(210.4, event.killerY(), 0.01);
        assertEquals(55.2, event.killerZ(), 0.01);
        assertEquals(1000.5, event.victimX(), 0.01);
        assertEquals(200.3, event.victimY(), 0.01);
        assertEquals(50.1, event.victimZ(), 0.01);
        assertEquals("12:34:56", event.timestamp());
        assertEquals(0, event.lineIndex());
    }

    @Test
    void parseLine_nonKillLine_returnsEmpty() {
        String line = "12:34:56 | Player \"SomePlayer\" is connected (id=abc123)";
        Optional<KillEvent> result = parser.parseLine(line, 0);
        assertTrue(result.isEmpty());
    }

    @Test
    void parseLine_disconnectLine_returnsEmpty() {
        String line = "12:34:56 | Player \"SomePlayer\" has been disconnected";
        Optional<KillEvent> result = parser.parseLine(line, 5);
        assertTrue(result.isEmpty());
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
    void parseLine_preservesLineIndex() {
        String line = "00:00:00 | Player \"Victim\" (id=a pos=<0.0, 0.0, 0.0>) " +
                "killed by Player \"Killer\" (id=b pos=<0.0, 0.0, 0.0>) " +
                "with Fists from 1.0 meters";

        Optional<KillEvent> result = parser.parseLine(line, 42);
        assertTrue(result.isPresent());
        assertEquals(42, result.get().lineIndex());
    }

    @Test
    void parseLine_weaponWithSpaces() {
        String line = "10:20:30 | Player \"Victim\" (id=a pos=<100.0, 200.0, 300.0>) " +
                "killed by Player \"Killer\" (id=b pos=<110.0, 220.0, 330.0>) " +
                "with KA-M from 50.0 meters";

        Optional<KillEvent> result = parser.parseLine(line, 0);
        assertTrue(result.isPresent());
        assertEquals("KA-M", result.get().weapon());
    }

    @Test
    void parseLine_playerNamesWithSpaces() {
        String line = "10:20:30 | Player \"John Doe\" (id=a pos=<100.0, 200.0, 300.0>) " +
                "killed by Player \"Jane Smith\" (id=b pos=<110.0, 220.0, 330.0>) " +
                "with IJ-70 from 25.0 meters";

        Optional<KillEvent> result = parser.parseLine(line, 0);
        assertTrue(result.isPresent());
        assertEquals("Jane Smith", result.get().killerName());
        assertEquals("John Doe", result.get().victimName());
    }

    @Test
    void parseLine_largeCoordinates() {
        String line = "23:59:59 | Player \"V\" (id=x pos=<15000.5, 14000.3, 500.1>) " +
                "killed by Player \"K\" (id=y pos=<15100.7, 14010.4, 505.2>) " +
                "with Mosin9130 from 800.5 meters";

        Optional<KillEvent> result = parser.parseLine(line, 0);
        assertTrue(result.isPresent());
        assertEquals(15000.5, result.get().victimX(), 0.01);
        assertEquals(15100.7, result.get().killerX(), 0.01);
    }

    // --- parseKillEvents tests ---

    @Test
    void parseKillEvents_mixedLog_extractsOnlyKills() {
        String log = """
                12:00:00 | Player "Alpha" is connected (id=abc123)
                12:00:05 | Player "Alpha" (id=abc pos=<100.0, 200.0, 50.0>) killed by Player "Bravo" (id=def pos=<110.0, 210.0, 55.0>) with M4-A1 from 50.0 meters
                12:00:10 | Player "Charlie" has been disconnected
                12:00:15 | Player "Delta" (id=ghi pos=<300.0, 400.0, 60.0>) killed by Player "Echo" (id=jkl pos=<310.0, 410.0, 65.0>) with IJ-70 from 10.0 meters
                """;

        List<KillEvent> events = parser.parseKillEvents(log);

        assertEquals(2, events.size());
        assertEquals("Bravo", events.get(0).killerName());
        assertEquals("Alpha", events.get(0).victimName());
        assertEquals("Echo", events.get(1).killerName());
        assertEquals("Delta", events.get(1).victimName());
    }

    @Test
    void parseKillEvents_emptyString_returnsEmptyList() {
        assertTrue(parser.parseKillEvents("").isEmpty());
    }

    @Test
    void parseKillEvents_nullContent_returnsEmptyList() {
        assertTrue(parser.parseKillEvents(null).isEmpty());
    }

    @Test
    void parseKillEvents_noKillLines_returnsEmptyList() {
        String log = """
                12:00:00 | Player "Alpha" is connected (id=abc123)
                12:00:10 | Player "Charlie" has been disconnected
                """;

        assertTrue(parser.parseKillEvents(log).isEmpty());
    }

    @Test
    void parseKillEvents_preservesLineIndices() {
        String log = """
                12:00:00 | Player "Alpha" is connected (id=abc123)
                12:00:05 | Player "V1" (id=a pos=<100.0, 200.0, 50.0>) killed by Player "K1" (id=b pos=<110.0, 210.0, 55.0>) with M4-A1 from 50.0 meters
                12:00:10 | Player "Charlie" has been disconnected
                12:00:15 | Player "V2" (id=c pos=<300.0, 400.0, 60.0>) killed by Player "K2" (id=d pos=<310.0, 410.0, 65.0>) with IJ-70 from 10.0 meters
                """;

        List<KillEvent> events = parser.parseKillEvents(log);
        assertEquals(1, events.get(0).lineIndex());
        assertEquals(3, events.get(1).lineIndex());
    }

    // --- formatKillEvent tests ---

    @Test
    void formatKillEvent_producesParseableLine() {
        KillEvent event = new KillEvent(
                "Killer", "Victim", "M4-A1", 150.3,
                1100.7, 210.4, 55.2,
                1000.5, 200.3, 50.1,
                "12:34:56", 0
        );

        String formatted = parser.formatKillEvent(event);
        Optional<KillEvent> reparsed = parser.parseLine(formatted, 0);

        assertTrue(reparsed.isPresent());
        assertEquals(event.killerName(), reparsed.get().killerName());
        assertEquals(event.victimName(), reparsed.get().victimName());
        assertEquals(event.weapon(), reparsed.get().weapon());
    }

    @Test
    void formatKillEvent_containsAllFields() {
        KillEvent event = new KillEvent(
                "KillerName", "VictimName", "AK-74", 200.5,
                500.0, 600.0, 70.0,
                400.0, 500.0, 60.0,
                "08:15:30", 5
        );

        String formatted = parser.formatKillEvent(event);

        assertTrue(formatted.contains("KillerName"));
        assertTrue(formatted.contains("VictimName"));
        assertTrue(formatted.contains("AK-74"));
        assertTrue(formatted.contains("08:15:30"));
        assertTrue(formatted.contains("meters"));
    }

    // --- Malformed line handling ---

    @Test
    void parseKillEvents_malformedLinesMixedWithValid_extractsValidOnly() {
        String log = """
                GARBAGE LINE WITH NO FORMAT
                12:00:05 | Player "V1" (id=a pos=<100.0, 200.0, 50.0>) killed by Player "K1" (id=b pos=<110.0, 210.0, 55.0>) with M4-A1 from 50.0 meters
                12:00:10 | Player "Incomplete" (id=x pos=<broken
                12:00:15 | Player "V2" (id=c pos=<300.0, 400.0, 60.0>) killed by Player "K2" (id=d pos=<310.0, 410.0, 65.0>) with IJ-70 from 10.0 meters
                """;

        List<KillEvent> events = parser.parseKillEvents(log);

        assertEquals(2, events.size());
        assertEquals("K1", events.get(0).killerName());
        assertEquals("K2", events.get(1).killerName());
    }
}
