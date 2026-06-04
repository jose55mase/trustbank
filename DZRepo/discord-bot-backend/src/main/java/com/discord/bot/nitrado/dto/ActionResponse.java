package com.discord.bot.nitrado.dto;

/**
 * Response returned after a successful server action (start, stop, restart, kick, ban, etc.).
 *
 * @param status  the result status (e.g., "success")
 * @param message a human-readable description of the action performed
 */
public record ActionResponse(
    String status,
    String message
) {}
