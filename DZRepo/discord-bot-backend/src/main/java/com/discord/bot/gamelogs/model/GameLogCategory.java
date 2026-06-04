package com.discord.bot.gamelogs.model;

/**
 * Categories for classifying events parsed from the DayZ server ADM log.
 */
public enum GameLogCategory {
    CONNECTION,
    DISCONNECTION,
    PLAYER_KILL,
    ZOMBIE_KILL,
    CHAT,
    HIT,
    UNKNOWN
}
