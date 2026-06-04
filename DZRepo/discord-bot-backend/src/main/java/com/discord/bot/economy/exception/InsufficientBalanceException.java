package com.discord.bot.economy.exception;

/**
 * Thrown when a debit operation exceeds the player's current balance.
 */
public class InsufficientBalanceException extends RuntimeException {

    private final long currentBalance;
    private final long requestedAmount;

    public InsufficientBalanceException(String message, long currentBalance, long requestedAmount) {
        super(message);
        this.currentBalance = currentBalance;
        this.requestedAmount = requestedAmount;
    }

    public long getCurrentBalance() {
        return currentBalance;
    }

    public long getRequestedAmount() {
        return requestedAmount;
    }
}
