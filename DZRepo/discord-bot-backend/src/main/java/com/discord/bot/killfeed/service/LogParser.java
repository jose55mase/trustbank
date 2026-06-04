package com.discord.bot.killfeed.service;

import com.discord.bot.killfeed.model.KillEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Stateless parser that extracts kill events from DayZ server_log.ADM content.
 *
 * <p>The ADM log format for kills is:
 * {@code HH:mm:ss | Player "VICTIM" (id=... pos=<X, Y, Z>) killed by Player "KILLER" (id=... pos=<X, Y, Z>) with WEAPON from DISTANCE meters}
 *
 * <p>Note: In the ADM format the VICTIM appears first, then "killed by Player" KILLER.
 */
@Component
public class LogParser {

    private static final Logger log = LoggerFactory.getLogger(LogParser.class);

    /**
     * Regex capturing groups:
     * 1 = timestamp (HH:mm:ss)
     * 2 = victim name
     * 3 = victim X
     * 4 = victim Y
     * 5 = victim Z
     * 6 = killer name
     * 7 = killer X
     * 8 = killer Y
     * 9 = killer Z
     * 10 = weapon
     * 11 = distance
     */
    private static final Pattern KILL_PATTERN = Pattern.compile(
            "^(\\d{2}:\\d{2}:\\d{2}) \\| Player \"(.+?)\" " +
            "\\(id=.+? pos=<([\\d.]+), ([\\d.]+), ([\\d.]+)>\\) " +
            "killed by Player \"(.+?)\" " +
            "\\(id=.+? pos=<([\\d.]+), ([\\d.]+), ([\\d.]+)>\\) " +
            "with (.+?) from ([\\d.]+) meters$"
    );

    /**
     * Parses the full log content and returns all kill events found.
     * Lines with unexpected format are skipped with a WARN log.
     *
     * @param logContent the raw content of the server_log.ADM file
     * @return list of parsed kill events, never null
     */
    public List<KillEvent> parseKillEvents(String logContent) {
        if (logContent == null || logContent.isBlank()) {
            return List.of();
        }

        String[] lines = logContent.split("\\r?\\n");
        List<KillEvent> events = new ArrayList<>();

        for (int i = 0; i < lines.length; i++) {
            try {
                parseLine(lines[i], i).ifPresent(events::add);
            } catch (Exception e) {
                log.warn("Error parsing line {}: {}", i, e.getMessage());
            }
        }

        return events;
    }

    /**
     * Attempts to parse a single log line as a KillEvent.
     *
     * @param line      the log line to parse
     * @param lineIndex the zero-based index of the line in the log file
     * @return an Optional containing the KillEvent if the line is a kill, empty otherwise
     */
    public Optional<KillEvent> parseLine(String line, int lineIndex) {
        if (line == null || line.isBlank()) {
            return Optional.empty();
        }

        Matcher matcher = KILL_PATTERN.matcher(line.trim());
        if (!matcher.matches()) {
            return Optional.empty();
        }

        try {
            String timestamp = matcher.group(1);
            String victimName = matcher.group(2);
            double victimX = Double.parseDouble(matcher.group(3));
            double victimY = Double.parseDouble(matcher.group(4));
            double victimZ = Double.parseDouble(matcher.group(5));
            String killerName = matcher.group(6);
            double killerX = Double.parseDouble(matcher.group(7));
            double killerY = Double.parseDouble(matcher.group(8));
            double killerZ = Double.parseDouble(matcher.group(9));
            String weapon = matcher.group(10);
            double distance = Double.parseDouble(matcher.group(11));

            return Optional.of(new KillEvent(
                    killerName, victimName, weapon, distance,
                    killerX, killerY, killerZ,
                    victimX, victimY, victimZ,
                    timestamp, lineIndex
            ));
        } catch (NumberFormatException e) {
            log.warn("Malformed numeric field in kill line at index {}: {}", lineIndex, e.getMessage());
            return Optional.empty();
        }
    }

    /**
     * Formats a KillEvent back to ADM log text representation.
     * Used to validate the round-trip property: format → parse should produce an equivalent event.
     *
     * @param event the kill event to format
     * @return the formatted log line
     */
    public String formatKillEvent(KillEvent event) {
        return String.format(java.util.Locale.US,
                "%s | Player \"%s\" (id=unknown pos=<%.1f, %.1f, %.1f>) " +
                "killed by Player \"%s\" (id=unknown pos=<%.1f, %.1f, %.1f>) " +
                "with %s from %.1f meters",
                event.timestamp(),
                event.victimName(),
                event.victimX(), event.victimY(), event.victimZ(),
                event.killerName(),
                event.killerX(), event.killerY(), event.killerZ(),
                event.weapon(),
                event.distance()
        );
    }
}
