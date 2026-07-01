package com.discord.bot.flagevent.parser;

import com.discord.bot.flagevent.model.FlagEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

class FlagLogParserTest {

    private FlagLogParser parser;

    @BeforeEach
    void setUp() {
        parser = new FlagLogParser();
    }

    @Test
    void parseLine_raisedEvent_extractsAllFields() {
        String line = "14:30:45 | Player \"TestPlayer\" (id=abc123def pos=<1000.5, 200.3, 3000.7>) has raised Flag_Chedaki on TerritoryFlag at <5000.1, 100.2, 6000.3>";

        Optional<FlagEvent> result = parser.parseLine(line);

        assertTrue(result.isPresent());
        FlagEvent event = result.get();
        assertEquals("raised", event.action());
        assertEquals("TestPlayer", event.playerName());
        assertEquals("abc123def", event.playerId());
        assertEquals("Flag_Chedaki", event.flagName());
        assertEquals(1000.5, event.playerX(), 0.001);
        assertEquals(200.3, event.playerY(), 0.001);
        assertEquals(3000.7, event.playerZ(), 0.001);
        assertEquals(5000.1, event.flagX(), 0.001);
        assertEquals(100.2, event.flagY(), 0.001);
        assertEquals(6000.3, event.flagZ(), 0.001);
        assertEquals(LocalTime.of(14, 30, 45), event.timestamp());
    }

    @Test
    void parseLine_loweredEvent_extractsAllFields() {
        String line = "09:15:22 | Player \"AnotherPlayer\" (id=FFAA00 pos=<500.0, 10.0, 750.0>) has lowered Flag_APA on TerritoryFlag at <500.5, 11.0, 751.0>";

        Optional<FlagEvent> result = parser.parseLine(line);

        assertTrue(result.isPresent());
        FlagEvent event = result.get();
        assertEquals("lowered", event.action());
        assertEquals("AnotherPlayer", event.playerName());
        assertEquals("FFAA00", event.playerId());
        assertEquals("Flag_APA", event.flagName());
        assertEquals(LocalTime.of(9, 15, 22), event.timestamp());
    }

    @Test
    void parseLine_nonMatchingLine_returnsEmpty() {
        String line = "14:30:45 | Player \"Someone\" connected";

        Optional<FlagEvent> result = parser.parseLine(line);

        assertFalse(result.isPresent());
    }

    @Test
    void parseLine_nullLine_returnsEmpty() {
        Optional<FlagEvent> result = parser.parseLine(null);
        assertFalse(result.isPresent());
    }

    @Test
    void parseLine_emptyLine_returnsEmpty() {
        Optional<FlagEvent> result = parser.parseLine("");
        assertFalse(result.isPresent());
    }

    @Test
    void parseLine_coordinateOutOfRange_returnsEmpty() {
        String line = "14:30:45 | Player \"Test\" (id=abc123 pos=<200000.0, 0.0, 0.0>) has raised Flag_X on TerritoryFlag at <0.0, 0.0, 0.0>";

        Optional<FlagEvent> result = parser.parseLine(line);

        assertFalse(result.isPresent());
    }

    @Test
    void parseLine_negativeCoordinates_parsesCorrectly() {
        String line = "12:00:00 | Player \"Neg\" (id=aabb pos=<-500.5, -200.3, -1000.0>) has raised Flag_X on TerritoryFlag at <-100.0, -50.0, -2000.0>";

        Optional<FlagEvent> result = parser.parseLine(line);

        assertTrue(result.isPresent());
        FlagEvent event = result.get();
        assertEquals(-500.5, event.playerX(), 0.001);
        assertEquals(-200.3, event.playerY(), 0.001);
        assertEquals(-1000.0, event.playerZ(), 0.001);
        assertEquals(-100.0, event.flagX(), 0.001);
        assertEquals(-50.0, event.flagY(), 0.001);
        assertEquals(-2000.0, event.flagZ(), 0.001);
    }

    @Test
    void parseLines_multipleValidLines_preservesOrder() {
        List<String> lines = List.of(
                "10:00:00 | Player \"First\" (id=aaa pos=<100.0, 0.0, 100.0>) has raised Flag_A on TerritoryFlag at <200.0, 0.0, 200.0>",
                "11:00:00 | Player \"Second\" (id=bbb pos=<300.0, 0.0, 300.0>) has lowered Flag_B on TerritoryFlag at <400.0, 0.0, 400.0>",
                "12:00:00 | Player \"Third\" (id=ccc pos=<500.0, 0.0, 500.0>) has raised Flag_C on TerritoryFlag at <600.0, 0.0, 600.0>"
        );

        List<FlagEvent> events = parser.parseLines(lines);

        assertEquals(3, events.size());
        assertEquals("First", events.get(0).playerName());
        assertEquals("Second", events.get(1).playerName());
        assertEquals("Third", events.get(2).playerName());
    }

    @Test
    void parseLines_mixedValidAndInvalid_skipsInvalid() {
        List<String> lines = List.of(
                "10:00:00 | Player \"Valid\" (id=aaa pos=<100.0, 0.0, 100.0>) has raised Flag_A on TerritoryFlag at <200.0, 0.0, 200.0>",
                "Some random log line that doesn't match",
                "12:00:00 | Player \"AlsoValid\" (id=bbb pos=<500.0, 0.0, 500.0>) has raised Flag_C on TerritoryFlag at <600.0, 0.0, 600.0>"
        );

        List<FlagEvent> events = parser.parseLines(lines);

        assertEquals(2, events.size());
        assertEquals("Valid", events.get(0).playerName());
        assertEquals("AlsoValid", events.get(1).playerName());
    }

    @Test
    void parseLines_emptyList_returnsEmptyList() {
        List<FlagEvent> events = parser.parseLines(List.of());
        assertTrue(events.isEmpty());
    }

    @Test
    void parseLines_nullList_returnsEmptyList() {
        List<FlagEvent> events = parser.parseLines(null);
        assertTrue(events.isEmpty());
    }

    @Test
    void format_producesRoundTrippableLine() {
        FlagEvent event = new FlagEvent(
                "raised", "TestPlayer", "abc123", "Flag_Chedaki",
                1000.5, 200.3, 3000.7,
                5000.1, 100.2, 6000.3,
                LocalTime.of(14, 30, 45)
        );

        String formatted = parser.format(event);
        Optional<FlagEvent> parsed = parser.parseLine(formatted);

        assertTrue(parsed.isPresent());
        FlagEvent roundTripped = parsed.get();
        assertEquals(event.action(), roundTripped.action());
        assertEquals(event.playerName(), roundTripped.playerName());
        assertEquals(event.playerId(), roundTripped.playerId());
        assertEquals(event.flagName(), roundTripped.flagName());
        assertEquals(event.playerX(), roundTripped.playerX(), 0.001);
        assertEquals(event.playerY(), roundTripped.playerY(), 0.001);
        assertEquals(event.playerZ(), roundTripped.playerZ(), 0.001);
        assertEquals(event.flagX(), roundTripped.flagX(), 0.001);
        assertEquals(event.flagY(), roundTripped.flagY(), 0.001);
        assertEquals(event.flagZ(), roundTripped.flagZ(), 0.001);
        assertEquals(event.timestamp(), roundTripped.timestamp());
    }

    @Test
    void parseLine_playerNameTooLong_returnsEmpty() {
        String longName = "A".repeat(129);
        String line = String.format("14:30:45 | Player \"%s\" (id=abc123 pos=<100.0, 0.0, 100.0>) has raised Flag_X on TerritoryFlag at <200.0, 0.0, 200.0>", longName);

        Optional<FlagEvent> result = parser.parseLine(line);

        assertFalse(result.isPresent());
    }

    @Test
    void parseLine_playerIdTooLong_returnsEmpty() {
        String longId = "a".repeat(65);
        String line = String.format("14:30:45 | Player \"Test\" (id=%s pos=<100.0, 0.0, 100.0>) has raised Flag_X on TerritoryFlag at <200.0, 0.0, 200.0>", longId);

        Optional<FlagEvent> result = parser.parseLine(line);

        assertFalse(result.isPresent());
    }

    @Test
    void parseLine_playerNameMaxLength_parsesCorrectly() {
        String maxName = "A".repeat(128);
        String line = String.format("14:30:45 | Player \"%s\" (id=abc123 pos=<100.0, 0.0, 100.0>) has raised Flag_X on TerritoryFlag at <200.0, 0.0, 200.0>", maxName);

        Optional<FlagEvent> result = parser.parseLine(line);

        assertTrue(result.isPresent());
        assertEquals(maxName, result.get().playerName());
    }

    @Test
    void parseLine_playerIdMaxLength_parsesCorrectly() {
        String maxId = "a".repeat(64);
        String line = String.format("14:30:45 | Player \"Test\" (id=%s pos=<100.0, 0.0, 100.0>) has raised Flag_X on TerritoryFlag at <200.0, 0.0, 200.0>", maxId);

        Optional<FlagEvent> result = parser.parseLine(line);

        assertTrue(result.isPresent());
        assertEquals(maxId, result.get().playerId());
    }
}
