package com.discord.bot.nitrado.dto;

/**
 * Standard error response returned by the Nitrado API gateway.
 *
 * @param error   the error code (e.g., "UNAUTHORIZED", "BAD_REQUEST")
 * @param message a human-readable description of the error
 */
public record ErrorResponse(
    String error,
    String message
) {}
