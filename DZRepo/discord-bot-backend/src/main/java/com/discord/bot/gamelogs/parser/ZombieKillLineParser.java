package com.discord.bot.gamelogs.parser;

import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Parser for zombie kill events from the DayZ server_log.ADM.
 *
 * <p>Matches lines with the format:
 * {@code HH:mm:ss | Player "PLAYER" (id=... pos=<X, Y, Z>) killed ZmbType}
 * with an optional weapon suffix:
 * {@code HH:mm:ss | Player "PLAYER" (id=... pos=<X, Y, Z>) killed ZmbType with WEAPON}
 *
 * <p>Adapted from {@code ZombieKillParser} in the economy package to the
 * {@code EventLineParser} interface.
 */
@Component
public class ZombieKillLineParser implements EventLineParser {

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

    @Override
    public Optional<GameLogEvent> parseLine(String line, int lineIndex) {
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

            Map<String, Object> playerPos = Map.of("x", playerX, "y", playerY, "z", playerZ);

            Map<String, Object> details = new HashMap<>();
            details.put("zombieType", zombieType);
            details.put("weapon", weapon);
            details.put("playerPos", playerPos);

            return Optional.of(new GameLogEvent(
                    timestamp,
                    GameLogCategory.ZOMBIE_KILL,
                    playerName,
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
        String playerName = event.playerName();
        Map<String, Object> details = event.details();

        String zombieType = (String) details.get("zombieType");
        String weapon = (String) details.get("weapon");

        @SuppressWarnings("unchecked")
        Map<String, Object> playerPos = (Map<String, Object>) details.get("playerPos");

        double playerX = ((Number) playerPos.get("x")).doubleValue();
        double playerY = ((Number) playerPos.get("y")).doubleValue();
        double playerZ = ((Number) playerPos.get("z")).doubleValue();

        String base = String.format(Locale.US,
                "%s | Player \"%s\" (id=Unknown pos=<%.1f, %.1f, %.1f>) killed %s",
                timestamp,
                playerName,
                playerX, playerY, playerZ,
                zombieType
        );

        if (weapon != null) {
            return base + " with " + weapon;
        }

        return base;
    }

    @Override
    public boolean canFormat(GameLogEvent event) {
        return event != null && event.category() == GameLogCategory.ZOMBIE_KILL;
    }
}
