package com.discord.bot.nitrado.dto;

/**
 * Represents a player connected to a game server.
 *
 * @param id     the player identifier
 * @param name   the player display name
 * @param online whether the player is currently online
 */
public record PlayerDto(
    String id,
    String name,
    boolean online
) {}
