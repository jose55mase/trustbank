package com.discord.bot.killfeed.service;

import com.discord.bot.killfeed.model.KillEvent;
import com.discord.bot.killfeed.model.LastProcessedState;
import net.jqwik.api.*;
import net.jqwik.api.constraints.IntRange;
import net.jqwik.api.constraints.Size;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Feature: kill-feed-discord, Property 6: For any list of KillEvents and
 * LastProcessedState, the filtering returns only events after the state.
 *
 * <p><b>Validates: Requirements 2.3, 2.4, 5.1, 5.2, 5.4</b></p>
 */
class DuplicateFilterPropertyTest {

    // ---------------------------------------------------------------
    // Property 6 — core filtering invariant
    // ---------------------------------------------------------------

    /**
     * Property 6: For any list of KillEvents and any valid LastProcessedState,
     * {@code DuplicateFilter.filterNewEvents} SHALL return only events whose
     * timestamp is strictly after the state's timestamp, or whose timestamp
     * equals the state's timestamp with a strictly greater lineIndex.
     *
     * <p><b>Validates: Requirements 2.3, 2.4, 5.1, 5.2, 5.4</b></p>
     */
    @Property(tries = 200)
    void filterNewEvents_returnsOnlyEventsAfterState(
            @ForAll("killEventLists") List<KillEvent> events,
            @ForAll("lastProcessedStates") LastProcessedState state) {

        List<KillEvent> result = DuplicateFilter.filterNewEvents(events, state);

        // Every returned event must be strictly after the state
        for (KillEvent event : result) {
            int cmp = event.timestamp().compareTo(state.timestamp());
            assertTrue(cmp > 0 || (cmp == 0 && event.lineIndex() > state.lineIndex()),
                    "Returned event should be after the last-processed state: event="
                            + event.timestamp() + "/" + event.lineIndex()
                            + " state=" + state.timestamp() + "/" + state.lineIndex());
        }

        // Every event NOT in the result must be at or before the state
        for (KillEvent event : events) {
            if (!result.contains(event)) {
                int cmp = event.timestamp().compareTo(state.timestamp());
                assertTrue(cmp < 0 || (cmp == 0 && event.lineIndex() <= state.lineIndex()),
                        "Excluded event should be at or before the last-processed state: event="
                                + event.timestamp() + "/" + event.lineIndex()
                                + " state=" + state.timestamp() + "/" + state.lineIndex());
            }
        }
    }

    /**
     * When lastState is null (first run), all events are returned.
     *
     * <p><b>Validates: Requirements 2.3, 5.1</b></p>
     */
    @Property(tries = 100)
    void filterNewEvents_nullState_returnsAllEvents(
            @ForAll("killEventLists") List<KillEvent> events) {

        List<KillEvent> result = DuplicateFilter.filterNewEvents(events, null);

        assertEquals(events.size(), result.size(),
                "All events should be returned when lastState is null");
        assertTrue(result.containsAll(events));
    }

    /**
     * The order of events in the result preserves the original order.
     *
     * <p><b>Validates: Requirements 5.2</b></p>
     */
    @Property(tries = 100)
    void filterNewEvents_preservesOriginalOrder(
            @ForAll("killEventLists") List<KillEvent> events,
            @ForAll("lastProcessedStates") LastProcessedState state) {

        List<KillEvent> result = DuplicateFilter.filterNewEvents(events, state);

        // Verify order is preserved: for any two elements in result,
        // their relative order matches the original list
        for (int i = 0; i < result.size() - 1; i++) {
            int idxA = events.indexOf(result.get(i));
            int idxB = events.indexOf(result.get(i + 1));
            assertTrue(idxA < idxB,
                    "Filtered results should preserve original event order");
        }
    }

    // ---------------------------------------------------------------
    // Generators
    // ---------------------------------------------------------------

    @Provide
    Arbitrary<List<KillEvent>> killEventLists() {
        return killEvents().list().ofMinSize(0).ofMaxSize(20);
    }

    @Provide
    Arbitrary<KillEvent> killEvents() {
        Arbitrary<String> playerName = Arbitraries.strings()
                .withCharRange('a', 'z')
                .withCharRange('A', 'Z')
                .withCharRange('0', '9')
                .ofMinLength(1)
                .ofMaxLength(12);

        Arbitrary<String> weapon = Arbitraries.of(
                "M4-A1", "AK-74", "IJ-70", "Mosin9130", "KA-M",
                "SVD", "CR-527", "Blaze", "Vaiga", "Fists");

        Arbitrary<Double> coordinate = Arbitraries.doubles()
                .between(0.0, 15000.0).ofScale(1);

        Arbitrary<Double> distance = Arbitraries.doubles()
                .between(0.1, 2000.0).ofScale(1);

        Arbitrary<String> timestamp = timestamps();

        Arbitrary<Integer> lineIndex = Arbitraries.integers().between(0, 500);

        Arbitrary<double[]> coords = Combinators.combine(coordinate, coordinate, coordinate)
                .as((x, y, z) -> new double[]{x, y, z});

        return Combinators.combine(
                playerName, playerName, weapon, distance,
                coords, coords, timestamp, lineIndex
        ).as((killer, victim, w, dist, kc, vc, ts, li) ->
                new KillEvent(killer, victim, w, dist,
                        kc[0], kc[1], kc[2],
                        vc[0], vc[1], vc[2],
                        ts, li));
    }

    @Provide
    Arbitrary<LastProcessedState> lastProcessedStates() {
        return Combinators.combine(
                timestamps(),
                Arbitraries.integers().between(0, 500)
        ).as(LastProcessedState::new);
    }

    private Arbitrary<String> timestamps() {
        return Combinators.combine(
                Arbitraries.integers().between(0, 23),
                Arbitraries.integers().between(0, 59),
                Arbitraries.integers().between(0, 59)
        ).as((h, m, s) -> String.format("%02d:%02d:%02d", h, m, s));
    }
}
