package com.discord.bot.killfeed.model;

/**
 * Immutable representation of a player kill event extracted from the DayZ server log.
 *
 * @param killerName the name of the player who performed the kill
 * @param victimName the name of the player who was killed
 * @param weapon     the weapon or cause of death
 * @param distance   the distance of the shot in meters
 * @param killerX    the X coordinate of the killer's position
 * @param killerY    the Y coordinate of the killer's position
 * @param killerZ    the Z coordinate of the killer's position
 * @param victimX    the X coordinate of the victim's position
 * @param victimY    the Y coordinate of the victim's position
 * @param victimZ    the Z coordinate of the victim's position
 * @param timestamp  the timestamp from the log line (HH:mm:ss format)
 * @param lineIndex  the zero-based index of the line in the log file
 */
public record KillEvent(
    String killerName,
    String victimName,
    String weapon,
    double distance,
    double killerX,
    double killerY,
    double killerZ,
    double victimX,
    double victimY,
    double victimZ,
    String timestamp,
    int lineIndex
) {}
