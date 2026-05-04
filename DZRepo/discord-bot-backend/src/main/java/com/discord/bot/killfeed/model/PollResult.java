package com.discord.bot.killfeed.model;

/**
 * Metrics collected after a complete poll cycle across all active kill feed configurations.
 *
 * @param configsProcessed the number of configurations that were processed
 * @param newEventsFound   the number of new kill events found across all configurations
 * @param embedsPublished  the number of embeds successfully published to Discord
 * @param errors           the number of errors encountered during the poll cycle
 */
public record PollResult(
    int configsProcessed,
    int newEventsFound,
    int embedsPublished,
    int errors
) {}
