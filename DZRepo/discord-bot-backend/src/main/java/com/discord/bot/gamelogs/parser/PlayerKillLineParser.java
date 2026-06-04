package com.discord.bot.gamelogs.parser;

import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import org.springframework.stereotype.Component;

import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Parser for player-vs-player kill events from the DayZ server_log.ADM.
 *
 * <p>Matches lines with the format:
 * {@code HH:mm:ss | Player "VICTIM" (id=... pos=<X, Y, Z>) killed by Player "KILLER" (id=... pos=<X, Y, Z>) with WEAPON from DISTANCE meters}
 *
 * <p>Reuses the same regex pattern from {@code LogParser} adapted to the {@code EventLineParser} interface.
 */
@Component
public class PlayerKillLineParser implements EventLineParser {

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

    @Override
    public Optional<GameLogEvent> parseLine(String line, int lineIndex) {
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

            Map<String, Object> killerPos = Map.of("x", killerX, "y", killerY, "z", killerZ);
            Map<String, Object> victimPos = Map.of("x", victimX, "y", victimY, "z", victimZ);

            Map<String, Object> details = Map.of(
                    "victimName", victimName,
                    "killerName", killerName,
                    "weapon", weapon,
                    "distance", distance,
                    "killerPos", killerPos,
                    "victimPos", victimPos
            );

            return Optional.of(new GameLogEvent(
                    timestamp,
                    GameLogCategory.PLAYER_KILL,
                    killerName,
                    line.trim(),
                    details,
                    lineIndex
            ));
        } catch (NumberFormatException e) {
            return Optional.empty();
        }
    }

    @Override
    public String formatEvent(GameLogEvent event) {
        String timestamp = event.timestamp();
        Map<String, Object> details = event.details();

        String victimName = (String) details.get("victimName");
        String killerName = (String) details.get("killerName");
        String weapon = (String) details.get("weapon");
        double distance = (Double) details.get("distance");

        @SuppressWarnings("unchecked")
        Map<String, Object> killerPos = (Map<String, Object>) details.get("killerPos");
        @SuppressWarnings("unchecked")
        Map<String, Object> victimPos = (Map<String, Object>) details.get("victimPos");

        double killerX = ((Number) killerPos.get("x")).doubleValue();
        double killerY = ((Number) killerPos.get("y")).doubleValue();
        double killerZ = ((Number) killerPos.get("z")).doubleValue();
        double victimX = ((Number) victimPos.get("x")).doubleValue();
        double victimY = ((Number) victimPos.get("y")).doubleValue();
        double victimZ = ((Number) victimPos.get("z")).doubleValue();

        return String.format(Locale.US,
                "%s | Player \"%s\" (id=unknown pos=<%.1f, %.1f, %.1f>) " +
                "killed by Player \"%s\" (id=unknown pos=<%.1f, %.1f, %.1f>) " +
                "with %s from %.1f meters",
                timestamp,
                victimName,
                victimX, victimY, victimZ,
                killerName,
                killerX, killerY, killerZ,
                weapon,
                distance
        );
    }

    @Override
    public boolean canFormat(GameLogEvent event) {
        return event != null && event.category() == GameLogCategory.PLAYER_KILL;
    }
}
