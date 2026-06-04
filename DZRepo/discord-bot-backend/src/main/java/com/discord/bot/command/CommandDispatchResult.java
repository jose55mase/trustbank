package com.discord.bot.command;

/**
 * Internal tracking record for command dispatch results.
 * Captures execution metadata for logging and observability.
 *
 * @param commandName    the name of the dispatched command
 * @param userId         the Discord user ID who invoked the command
 * @param channelId      the Discord channel ID where the command was invoked
 * @param success        true if the command executed successfully
 * @param executionTimeMs execution time in milliseconds
 * @param errorMessage   error description if success=false, null if success=true
 */
public record CommandDispatchResult(
    String commandName,
    String userId,
    String channelId,
    boolean success,
    long executionTimeMs,
    String errorMessage
) {}
