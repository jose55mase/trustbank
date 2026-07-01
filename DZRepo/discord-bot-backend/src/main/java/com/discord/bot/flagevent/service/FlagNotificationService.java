package com.discord.bot.flagevent.service;

import com.discord.bot.flagevent.model.FlagEvent;

/**
 * Service responsible for sending Discord embed notifications for flag events.
 * Implementations build rich embeds with leaderboard and dominant flag information.
 */
public interface FlagNotificationService {

    /**
     * Sends a Discord embed notification for a flag raise event.
     * The embed includes the player name, flag name, timestamp, top 5 leaderboard,
     * and the dominant flag.
     *
     * @param event the flag raise event
     * @param channelId the Discord channel ID to send the notification to
     */
    void sendRaiseNotification(FlagEvent event, String channelId);

    /**
     * Sends a Discord embed notification for a flag lower event.
     * The embed includes the player name, flag name, elapsed time, top 5 leaderboard,
     * and the dominant flag.
     *
     * @param event the flag lower event
     * @param elapsedSeconds the time the flag was active, in seconds
     * @param channelId the Discord channel ID to send the notification to
     */
    void sendLowerNotification(FlagEvent event, long elapsedSeconds, String channelId);
}
