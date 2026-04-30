package com.discord.bot.nitrado.dto;

/**
 * Response containing the content of a downloaded file.
 *
 * @param content the file content as text
 */
public record FileContentResponse(
    String content
) {}
