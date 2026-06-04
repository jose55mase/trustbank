package com.discord.bot.killfeed.model;

/**
 * Tracks the last processed kill event for a given configuration to prevent duplicate publishing.
 *
 * @param timestamp the timestamp of the last processed event (HH:mm:ss format)
 * @param lineIndex the line index of the last processed event in the log file
 */
public record LastProcessedState(
    String timestamp,
    int lineIndex
) {}
