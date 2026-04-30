package com.discord.bot.nitrado.dto;

/**
 * Response containing the server log content.
 *
 * @param content the log content as text
 */
public record LogResponse(
    String content
) {}
