package com.discord.bot.economy.model;

/**
 * Represents a parsed zombie kill event from DayZ server logs (server_log.ADM).
 *
 * <p>Each instance captures the details of a player killing a zombie, including
 * the player's name, the type of zombie killed, the weapon used (if available),
 * the player's coordinates at the time of the kill, the log timestamp, and the
 * line index within the log file for deduplication purposes.</p>
 *
 * @param playerName the name of the player who killed the zombie
 * @param zombieType the type/class of zombie killed (e.g., "ZmbM_CitizenASkinny")
 * @param weapon     the weapon used for the kill, or {@code null} if not specified in the log
 * @param playerX    the player's X coordinate at the time of the kill
 * @param playerY    the player's Y coordinate at the time of the kill
 * @param playerZ    the player's Z coordinate at the time of the kill
 * @param timestamp  the timestamp from the log line (format: "HH:mm:ss")
 * @param lineIndex  the zero-based line index within the log file, used for deduplication
 */
public record ZombieKillEvent(
    String playerName,
    String zombieType,
    String weapon,
    double playerX,
    double playerY,
    double playerZ,
    String timestamp,
    int lineIndex
) {}
