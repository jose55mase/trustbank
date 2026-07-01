package com.discord.bot.flagevent.service;

import com.discord.bot.flagevent.model.FlagEvent;
import com.discord.bot.flagevent.model.FlagLocation;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalTime;

import static org.junit.jupiter.api.Assertions.*;

class PositionMatcherTest {

    private PositionMatcher matcher;

    @BeforeEach
    void setUp() {
        matcher = new PositionMatcher();
    }

    @Test
    void distance2D_samePoint_returnsZero() {
        assertEquals(0.0, matcher.distance2D(100.0, 200.0, 100.0, 200.0), 0.0001);
    }

    @Test
    void distance2D_knownDistance_returnsCorrectValue() {
        // 3-4-5 triangle: distance between (0,0) and (3,4) = 5
        assertEquals(5.0, matcher.distance2D(0.0, 0.0, 3.0, 4.0), 0.0001);
    }

    @Test
    void distance2D_negativeCoordinates_returnsCorrectValue() {
        // distance between (-3, -4) and (0, 0) = 5
        assertEquals(5.0, matcher.distance2D(-3.0, -4.0, 0.0, 0.0), 0.0001);
    }

    @Test
    void matches_withinTolerance_returnsTrue() {
        FlagEvent event = new FlagEvent(
            "raised", "Player1", "abc123", "Flag_Chedaki",
            100.0, 50.0, 200.0,  // player pos
            1003.0, 999.0, 2004.0,  // flag pos (distance from location = 5)
            LocalTime.of(12, 0, 0)
        );
        FlagLocation location = new FlagLocation("guild1", 1000.0, 2000.0, 10.0);

        assertTrue(matcher.matches(event, location));
    }

    @Test
    void matches_exactlyAtTolerance_returnsTrue() {
        // distance = exactly 10.0
        FlagEvent event = new FlagEvent(
            "raised", "Player1", "abc123", "Flag_Chedaki",
            100.0, 50.0, 200.0,
            1006.0, 999.0, 2008.0,  // flag pos: distance = sqrt(36 + 64) = sqrt(100) = 10
            LocalTime.of(12, 0, 0)
        );
        FlagLocation location = new FlagLocation("guild1", 1000.0, 2000.0, 10.0);

        assertTrue(matcher.matches(event, location));
    }

    @Test
    void matches_outsideTolerance_returnsFalse() {
        FlagEvent event = new FlagEvent(
            "raised", "Player1", "abc123", "Flag_Chedaki",
            100.0, 50.0, 200.0,
            1020.0, 999.0, 2020.0,  // flag pos: distance = sqrt(400+400) ≈ 28.28
            LocalTime.of(12, 0, 0)
        );
        FlagLocation location = new FlagLocation("guild1", 1000.0, 2000.0, 10.0);

        assertFalse(matcher.matches(event, location));
    }

    @Test
    void matches_ignoresYCoordinate() {
        // Same X and Z but different Y values should produce same result
        FlagEvent event1 = new FlagEvent(
            "raised", "Player1", "abc123", "Flag_Chedaki",
            100.0, 0.0, 200.0,
            1003.0, 0.0, 2004.0,  // Y = 0
            LocalTime.of(12, 0, 0)
        );
        FlagEvent event2 = new FlagEvent(
            "raised", "Player1", "abc123", "Flag_Chedaki",
            100.0, 99999.0, 200.0,
            1003.0, -99999.0, 2004.0,  // Y = -99999 (wildly different)
            LocalTime.of(12, 0, 0)
        );
        FlagLocation location = new FlagLocation("guild1", 1000.0, 2000.0, 10.0);

        assertEquals(matcher.matches(event1, location), matcher.matches(event2, location));
    }

    @Test
    void matches_usesFlagPositionNotPlayerPosition() {
        // Flag is at the location, player is far away — should match
        FlagEvent event = new FlagEvent(
            "raised", "Player1", "abc123", "Flag_Chedaki",
            9999.0, 50.0, 9999.0,  // player far from location
            1000.0, 50.0, 2000.0,  // flag exactly at location
            LocalTime.of(12, 0, 0)
        );
        FlagLocation location = new FlagLocation("guild1", 1000.0, 2000.0, 10.0);

        assertTrue(matcher.matches(event, location));
    }
}
