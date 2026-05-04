package com.discord.bot.economy.exception;

/**
 * Thrown when an operation requires a linked player profile but none exists
 * for the given Discord ID.
 */
public class PlayerNotLinkedException extends RuntimeException {

    public PlayerNotLinkedException(String message) {
        super(message);
    }
}
