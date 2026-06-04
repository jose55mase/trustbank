package com.discord.bot.killfeed.service;

import com.discord.bot.killfeed.model.KillEvent;
import com.discord.bot.killfeed.model.LastProcessedState;

import java.util.List;

/**
 * Utility class for filtering out already-processed kill events.
 *
 * <p>Compares each {@link KillEvent} against a {@link LastProcessedState} using
 * lexicographic timestamp comparison (HH:mm:ss format) and line-index ordering
 * to determine which events are new.</p>
 */
public final class DuplicateFilter {

    private DuplicateFilter() {
        // utility class — not instantiable
    }

    /**
     * Returns only the events that occurred after the given last-processed state.
     *
     * <ul>
     *   <li>If {@code lastState} is {@code null}, all events are considered new (first-run scenario).</li>
     *   <li>An event is new when its timestamp is lexicographically greater than the state's timestamp.</li>
     *   <li>An event is also new when its timestamp equals the state's timestamp <em>and</em>
     *       its lineIndex is strictly greater than the state's lineIndex.</li>
     * </ul>
     *
     * @param events    the full list of parsed kill events (may be empty)
     * @param lastState the last-processed state, or {@code null} on first run
     * @return a list containing only the new (unprocessed) events, preserving order
     */
    public static List<KillEvent> filterNewEvents(List<KillEvent> events, LastProcessedState lastState) {
        if (lastState == null) {
            return List.copyOf(events);
        }

        String lastTimestamp = lastState.timestamp();
        int lastLineIndex = lastState.lineIndex();

        return events.stream()
                .filter(event -> {
                    int cmp = event.timestamp().compareTo(lastTimestamp);
                    if (cmp > 0) {
                        return true;
                    }
                    return cmp == 0 && event.lineIndex() > lastLineIndex;
                })
                .toList();
    }
}
