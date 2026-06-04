package com.discord.bot.economy.model;

/**
 * Holds the result of a successful transfer operation,
 * containing the transaction records for both sender and receiver.
 *
 * @param senderTransaction   the transaction record for the sender (type PLAYER_TRANSFER_SENT)
 * @param receiverTransaction the transaction record for the receiver (type PLAYER_TRANSFER_RECEIVED)
 */
public record TransferResult(
        CurrencyTransaction senderTransaction,
        CurrencyTransaction receiverTransaction
) {
}
