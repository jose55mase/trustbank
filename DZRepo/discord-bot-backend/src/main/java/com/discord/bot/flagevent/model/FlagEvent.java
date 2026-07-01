package com.discord.bot.flagevent.model;

import java.time.LocalTime;

/**
 * Value object representing a parsed flag raise or lower event from the DayZ server log.
 *
 * @param action     the event action: "raised" or "lowered"
 * @param playerName the name of the player who performed the action (max 128 chars)
 * @param playerId   the player's hexadecimal ID (up to 64 chars)
 * @param flagName   the name of the flag (e.g., "Flag_Chedaki")
 * @param playerX    the player's X coordinate
 * @param playerY    the player's Y coordinate
 * @param playerZ    the player's Z coordinate
 * @param flagX      the flag's X coordinate
 * @param flagY      the flag's Y coordinate
 * @param flagZ      the flag's Z coordinate
 * @param timestamp  the time extracted from the log line (HH:mm:ss)
 */
public record FlagEvent(
    String action,
    String playerName,
    String playerId,
    String flagName,
    double playerX,
    double playerY,
    double playerZ,
    double flagX,
    double flagY,
    double flagZ,
    LocalTime timestamp
) {}
