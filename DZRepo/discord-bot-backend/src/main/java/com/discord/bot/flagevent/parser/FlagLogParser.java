package com.discord.bot.flagevent.parser;

import com.discord.bot.flagevent.model.FlagEvent;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Stateless parser that extracts flag raise/lower events from DayZ server ADM log content.
 *
 * <p>The ADM log format for flag events is:
 * {@code HH:mm:ss | Player "NAME" (id=ID pos=<X, Y, Z>) has raised/lowered FLAG_NAME on TerritoryFlag at <X, Y, Z>}
 */
@Component
public class FlagLogParser {

    private static final Logger log = LoggerFactory.getLogger(FlagLogParser.class);

    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm:ss");

    private static final double COORD_MIN = -100000.0;
    private static final double COORD_MAX = 100000.0;
    private static final int MAX_PLAYER_NAME_LENGTH = 128;
    private static final int MAX_PLAYER_ID_LENGTH = 64;

    /**
     * Regex capturing groups:
     * 1 = timestamp (HH:mm:ss)
     * 2 = player name
     * 3 = player ID (hex)
     * 4 = player X
     * 5 = player Y
     * 6 = player Z
     * 7 = action (raised or lowered)
     * 8 = flag name
     * 9 = flag X
     * 10 = flag Y
     * 11 = flag Z
     */
    private static final Pattern FLAG_EVENT_PATTERN = Pattern.compile(
            "^(\\d{2}:\\d{2}:\\d{2}) \\| Player \"(.+?)\" " +
            "\\(id=([0-9a-fA-F]+) pos=<([\\d.-]+), ([\\d.-]+), ([\\d.-]+)>\\) " +
            "has (raised|lowered) (.+?) on TerritoryFlag at " +
            "<([\\d.-]+), ([\\d.-]+), ([\\d.-]+)>$"
    );

    /**
     * Parses a single log line into a FlagEvent, or empty if not a flag event.
     *
     * @param line the log line to parse
     * @return an Optional containing the FlagEvent if the line matches, empty otherwise
     */
    public Optional<FlagEvent> parseLine(String line) {
        if (line == null || line.isBlank()) {
            return Optional.empty();
        }

        Matcher matcher = FLAG_EVENT_PATTERN.matcher(line.trim());
        if (!matcher.matches()) {
            return Optional.empty();
        }

        try {
            String timestampStr = matcher.group(1);
            String playerName = matcher.group(2);
            String playerId = matcher.group(3);
            String playerXStr = matcher.group(4);
            String playerYStr = matcher.group(5);
            String playerZStr = matcher.group(6);
            String action = matcher.group(7);
            String flagName = matcher.group(8);
            String flagXStr = matcher.group(9);
            String flagYStr = matcher.group(10);
            String flagZStr = matcher.group(11);

            // Validate player name length
            if (playerName.isEmpty() || playerName.length() > MAX_PLAYER_NAME_LENGTH) {
                log.warn("Malformed flag event line: player name is empty or exceeds {} chars: '{}'",
                        MAX_PLAYER_NAME_LENGTH, truncateForLog(line));
                return Optional.empty();
            }

            // Validate player ID length and hex format
            if (playerId.isEmpty() || playerId.length() > MAX_PLAYER_ID_LENGTH) {
                log.warn("Malformed flag event line: player ID is empty or exceeds {} chars: '{}'",
                        MAX_PLAYER_ID_LENGTH, truncateForLog(line));
                return Optional.empty();
            }

            // Parse timestamp
            LocalTime timestamp;
            try {
                timestamp = LocalTime.parse(timestampStr, TIME_FORMATTER);
            } catch (DateTimeParseException e) {
                log.warn("Malformed flag event line: invalid timestamp '{}': '{}'",
                        timestampStr, truncateForLog(line));
                return Optional.empty();
            }

            // Parse coordinates
            double playerX = Double.parseDouble(playerXStr);
            double playerY = Double.parseDouble(playerYStr);
            double playerZ = Double.parseDouble(playerZStr);
            double flagX = Double.parseDouble(flagXStr);
            double flagY = Double.parseDouble(flagYStr);
            double flagZ = Double.parseDouble(flagZStr);

            // Validate coordinate ranges
            if (!isValidCoordinate(playerX) || !isValidCoordinate(playerY) || !isValidCoordinate(playerZ)
                    || !isValidCoordinate(flagX) || !isValidCoordinate(flagY) || !isValidCoordinate(flagZ)) {
                log.warn("Malformed flag event line: coordinates out of range [{}, {}]: '{}'",
                        COORD_MIN, COORD_MAX, truncateForLog(line));
                return Optional.empty();
            }

            // Validate flag name is not empty
            if (flagName.isEmpty()) {
                log.warn("Malformed flag event line: flag name is empty: '{}'", truncateForLog(line));
                return Optional.empty();
            }

            return Optional.of(new FlagEvent(
                    action, playerName, playerId, flagName,
                    playerX, playerY, playerZ,
                    flagX, flagY, flagZ,
                    timestamp
            ));
        } catch (NumberFormatException e) {
            log.warn("Malformed flag event line: non-numeric coordinate value: '{}'", truncateForLog(line));
            return Optional.empty();
        }
    }

    /**
     * Parses multiple log lines, returning all valid FlagEvents in order.
     *
     * @param lines the list of log lines to parse
     * @return list of parsed flag events preserving source order, never null
     */
    public List<FlagEvent> parseLines(List<String> lines) {
        if (lines == null || lines.isEmpty()) {
            return List.of();
        }

        return lines.stream()
                .map(this::parseLine)
                .filter(Optional::isPresent)
                .map(Optional::get)
                .collect(Collectors.toList());
    }

    /**
     * Formats a FlagEvent back to a log line string for round-trip testing.
     * The output of this method can be parsed back by {@link #parseLine(String)}.
     *
     * @param event the flag event to format
     * @return the formatted log line
     */
    public String format(FlagEvent event) {
        return String.format(Locale.US,
                "%s | Player \"%s\" (id=%s pos=<%.3f, %.3f, %.3f>) has %s %s on TerritoryFlag at <%.3f, %.3f, %.3f>",
                event.timestamp().format(TIME_FORMATTER),
                event.playerName(),
                event.playerId(),
                event.playerX(), event.playerY(), event.playerZ(),
                event.action(),
                event.flagName(),
                event.flagX(), event.flagY(), event.flagZ()
        );
    }

    private boolean isValidCoordinate(double value) {
        return !Double.isNaN(value) && !Double.isInfinite(value)
                && value >= COORD_MIN && value <= COORD_MAX;
    }

    private String truncateForLog(String line) {
        if (line.length() <= 200) {
            return line;
        }
        return line.substring(0, 200) + "...";
    }
}
