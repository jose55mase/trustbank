package com.discord.bot.flagevent.model;

/**
 * DTO representing the status of a specific player in the flag event system.
 *
 * @param playerName    the player name
 * @param flagName      the flag name associated with this player
 * @param totalSeconds  total accumulated time in seconds (including active session elapsed)
 * @param formattedTime time formatted as HH:MM:SS
 * @param active        whether the player currently has an active flag session
 */
public record PlayerStatus(
        String playerName,
        String flagName,
        long totalSeconds,
        String formattedTime,
        boolean active
) {}
