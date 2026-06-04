package com.discord.bot.economy.parser;

import com.discord.bot.economy.model.ZombieKillEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Stateless parser that extracts zombie kill events from DayZ server_log.ADM content.
 *
 * <p>The ADM log format for zombie kills is:
 * {@code HH:mm:ss | Player "PLAYER" (id=... pos=<X, Y, Z>) killed ZmbType}
 * with an optional weapon suffix:
 * {@code HH:mm:ss | Player "PLAYER" (id=... pos=<X, Y, Z>) killed ZmbType with WEAPON}
 *
 * <p>This parser is separate from the existing {@code LogParser} because the zombie kill
 * format differs significantly from the player-vs-player kill format (no "killed by Player",
 * no distance, zombie entity names start with "Zmb").
 */
@Component
public class ZombieKillParser {

    private static final Logger log = LoggerFactory.getLogger(ZombieKillParser.class);

    /**
     * Regex capturing groups:
     * 1 = timestamp (HH:mm:ss)
     * 2 = player name
     * 3 = player X coordinate
     * 4 = player Y coordinate
     * 5 = player Z coordinate
     * 6 = zombie type (e.g., ZmbM_CitizenASkinny)
     * 7 = weapon (optional, may be null if "with WEAPON" is absent)
     */
    private static final Pattern ZOMBIE_KILL_PATTERN = Pattern.compile(
            "^(\\d{2}:\\d{2}:\\d{2}) \\| Player \"(.+?)\" " +
            "\\(id=.+? pos=<([\\d.]+), ([\\d.]+), ([\\d.]+)>\\) " +
            "killed (Zmb\\w+)" +
            "(?: with (.+))?$"
    );

    /**
     * Parses the full log content and returns all zombie kill events found.
     * Lines that partially match but have malformed numeric fields are skipped with a WARN log.
     *
     * @param logContent the raw content of the server_log.ADM file
     * @return list of parsed zombie kill events, never null
     */
    public List<ZombieKillEvent> parseZombieKills(String logContent) {
        if (logContent == null || logContent.isBlank()) {
            return List.of();
        }

        String[] lines = logContent.split("\\r?\\n");
        List<ZombieKillEvent> events = new ArrayList<>();

        for (int i = 0; i < lines.length; i++) {
            parseLine(lines[i], i).ifPresent(events::add);
        }

        return events;
    }

    /**
     * Attempts to parse a single log line as a ZombieKillEvent.
     *
     * @param line      the log line to parse
     * @param lineIndex the zero-based index of the line in the log file
     * @return an Optional containing the ZombieKillEvent if the line is a zombie kill, empty otherwise
     */
    public Optional<ZombieKillEvent> parseLine(String line, int lineIndex) {
        if (line == null || line.isBlank()) {
            return Optional.empty();
        }

        Matcher matcher = ZOMBIE_KILL_PATTERN.matcher(line.trim());
        if (!matcher.matches()) {
            return Optional.empty();
        }

        try {
            String timestamp = matcher.group(1);
            String playerName = matcher.group(2);
            double playerX = Double.parseDouble(matcher.group(3));
            double playerY = Double.parseDouble(matcher.group(4));
            double playerZ = Double.parseDouble(matcher.group(5));
            String zombieType = matcher.group(6);
            String weapon = matcher.group(7); // null if "with WEAPON" is absent

            return Optional.of(new ZombieKillEvent(
                    playerName, zombieType, weapon,
                    playerX, playerY, playerZ,
                    timestamp, lineIndex
            ));
        } catch (NumberFormatException e) {
            log.warn("Malformed numeric field in zombie kill line at index {}: {}", lineIndex, e.getMessage());
            return Optional.empty();
        }
    }

    /**
     * Formats a ZombieKillEvent back to ADM log text representation.
     * Used to validate the round-trip property: format → parse should produce an equivalent event.
     *
     * @param event the zombie kill event to format
     * @return the formatted log line
     */
    public String formatZombieKillEvent(ZombieKillEvent event) {
        String base = String.format(java.util.Locale.US,
                "%s | Player \"%s\" (id=Unknown pos=<%.1f, %.1f, %.1f>) killed %s",
                event.timestamp(),
                event.playerName(),
                event.playerX(), event.playerY(), event.playerZ(),
                event.zombieType()
        );

        if (event.weapon() != null) {
            return base + " with " + event.weapon();
        }

        return base;
    }
}
