package com.discord.bot.nitrado.dto;

import java.time.Instant;

/**
 * Represents a banned player on a game server.
 *
 * @param id       the player identifier
 * @param name     the player display name
 * @param reason   the reason for the ban
 * @param bannedAt the timestamp when the player was banned
 */
public record BannedPlayerDto(
    String id,
    String name,
    String reason,
    Instant bannedAt
) {}
