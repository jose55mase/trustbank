package com.discord.bot.flagevent.model;

/**
 * DTO representing a single entry in the flag leaderboard.
 *
 * @param rank           the rank position (1-based)
 * @param playerName     the player name
 * @param flagName       the flag name associated with this player
 * @param totalSeconds   total accumulated time in seconds (including active session elapsed)
 * @param formattedTime  time formatted as HH:MM:SS
 */
public record LeaderboardEntry(
        int rank,
        String playerName,
        String flagName,
        long totalSeconds,
        String formattedTime
) {}
