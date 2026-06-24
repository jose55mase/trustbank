package com.discord.bot.shop.parser;

import com.discord.bot.shop.model.PlayerPosition;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Parses DayZ server ADM logs to extract player positions.
 *
 * <p>Any log line containing {@code Player "NAME" (id=... pos=<X, Z, Y>)}
 * is matched. The coordinates from the log are in the order {@code <X, Z, Y>}
 * where X and Z are horizontal and Y is the height/altitude.
 *
 * <p>For the custom object spawner JSON, the format is {@code [X, Y, Z]} —
 * so we swap the second and third values from the log.
 */
@Component
public class PlayerPositionParser {

    private static final Logger log = LoggerFactory.getLogger(PlayerPositionParser.class);

    /**
     * Matches any log line containing a player with position data.
     * Captures: 1=timestamp, 2=playerName, 3=X, 4=Z, 5=Y (log order)
     */
    private static final Pattern PLAYER_POS_PATTERN = Pattern.compile(
            "^(\\d{2}:\\d{2}:\\d{2}) \\| Player \"(.+?)\" \\(id=.+? pos=<([\\d.]+), ([\\d.]+), ([\\d.]+)>\\)"
    );

    /**
     * Parses the full log content and returns the last N positions for a specific player.
     *
     * @param logContent the raw ADM log content
     * @param playerName the DayZ player name to filter for (case-insensitive)
     * @param maxPositions the maximum number of positions to return
     * @return list of positions (most recent last), never null
     */
    public List<PlayerPosition> getLastPositions(String logContent, String playerName, int maxPositions) {
        if (logContent == null || logContent.isBlank() || playerName == null) {
            return List.of();
        }

        String[] lines = logContent.split("\\r?\\n");
        List<PlayerPosition> positions = new ArrayList<>();

        for (String line : lines) {
            if (line.isBlank()) {
                continue;
            }

            Matcher matcher = PLAYER_POS_PATTERN.matcher(line.trim());
            if (!matcher.find()) {
                continue;
            }

            String name = matcher.group(2);
            if (!name.equalsIgnoreCase(playerName)) {
                continue;
            }

            try {
                String timestamp = matcher.group(1);
                double logX = Double.parseDouble(matcher.group(3));
                double logZ = Double.parseDouble(matcher.group(4));
                double logY = Double.parseDouble(matcher.group(5));

                // Log format: <X, Z, Y> → JSON format: [X, Y, Z]
                positions.add(new PlayerPosition(logX, logY, logZ, timestamp));
            } catch (NumberFormatException e) {
                log.debug("Malformed coordinates in line: {}", line);
            }
        }

        // Return the last N positions
        if (positions.size() <= maxPositions) {
            return positions;
        }
        return positions.subList(positions.size() - maxPositions, positions.size());
    }

    /**
     * Parses the full log content and returns the last N unique positions
     * for a specific player (deduplicates positions that are very close together).
     *
     * @param logContent the raw ADM log content
     * @param playerName the DayZ player name to filter for (case-insensitive)
     * @param maxPositions the maximum number of unique positions to return
     * @return list of deduplicated positions (most recent last), never null
     */
    public List<PlayerPosition> getLastUniquePositions(String logContent, String playerName, int maxPositions) {
        List<PlayerPosition> allPositions = getLastPositions(logContent, playerName, Integer.MAX_VALUE);

        // Deduplicate: consider positions within 5 meters as the same location
        List<PlayerPosition> unique = new ArrayList<>();
        for (int i = allPositions.size() - 1; i >= 0 && unique.size() < maxPositions; i--) {
            PlayerPosition candidate = allPositions.get(i);
            boolean isDuplicate = unique.stream().anyMatch(existing -> existing.distanceTo(candidate) < 5.0);
            if (!isDuplicate) {
                unique.add(candidate);
            }
        }

        // Reverse to maintain chronological order (oldest first)
        Collections.reverse(unique);
        return unique;
    }
}
