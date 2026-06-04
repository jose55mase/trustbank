package com.discord.bot.economy.exception;

/**
 * Thrown when a player attempts to transfer coins to themselves.
 */
public class SelfTransferException extends RuntimeException {

    public SelfTransferException(String message) {
        super(message);
    }
}
