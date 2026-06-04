package com.discord.bot.nitrado.dto;

/**
 * Represents a DayZ game server from the Nitrado API.
 *
 * @param id             the Nitrado service ID
 * @param name           the server name
 * @param ip             the server IP address
 * @param port           the server port
 * @param status         the server status (e.g., "started", "stopped")
 * @param currentPlayers the number of currently connected players
 * @param maxPlayers     the maximum number of players allowed
 * @param map            the current map name
 * @param gameVersion    the game version running on the server
 */
public record GameServerDto(
    int id,
    String name,
    String ip,
    int port,
    String status,
    int currentPlayers,
    int maxPlayers,
    String map,
    String gameVersion
) {}
