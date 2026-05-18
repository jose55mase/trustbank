package com.discord.bot.killfeed.model;

/**
 * Configuration for the notification channel where unlinked player alerts are sent.
 *
 * @param guildId   the Discord guild ID
 * @param channelId the Discord channel ID for notifications
 * @param serviceId the Nitrado service ID
 */
public record NotificationConfig(
    String guildId,
    String channelId,
    int serviceId
) {}
