package com.discord.bot.economy.exception;

/**
 * Thrown when a player attempts to link a DayZ name that is already linked
 * to a different Discord account.
 */
public class DayzNameAlreadyLinkedException extends RuntimeException {

    private final String dayzName;

    public DayzNameAlreadyLinkedException(String message, String dayzName) {
        super(message);
        this.dayzName = dayzName;
    }

    public String getDayzName() {
        return dayzName;
    }
}
