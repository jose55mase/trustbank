package com.discord.bot.killfeed.model;

/**
 * Configuration that associates a Discord guild with a channel and a Nitrado service
 * for kill feed publishing.
 *
 * @param guildId   the Discord guild (server) ID
 * @param channelId the Discord channel ID where kill feed embeds are published
 * @param serviceId the Nitrado service ID for the DayZ server
 */
public record KillFeedConfig(
    String guildId,
    String channelId,
    int serviceId
) {}
