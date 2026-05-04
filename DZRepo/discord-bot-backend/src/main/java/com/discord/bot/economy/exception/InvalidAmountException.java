package com.discord.bot.economy.exception;

/**
 * Thrown when a credit or debit operation is attempted with a non-positive amount.
 */
public class InvalidAmountException extends RuntimeException {

    public InvalidAmountException(String message) {
        super(message);
    }
}
