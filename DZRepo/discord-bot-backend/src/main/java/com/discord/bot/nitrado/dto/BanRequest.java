package com.discord.bot.nitrado.dto;

/**
 * Request body for banning a player, containing an optional reason.
 *
 * @param reason the reason for the ban, may be null
 */
public record BanRequest(
    String reason
) {}
