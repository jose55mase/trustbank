package com.discord.bot.economy.dto;

import com.discord.bot.economy.model.CurrencyTransaction;

import java.time.LocalDateTime;

/**
 * Response DTO representing a single currency transaction.
 *
 * <p>Used by the REST API ({@code GET /api/economy/transactions}) to
 * expose transaction history without leaking JPA entity internals or
 * the associated player profile.</p>
 *
 * @param id           the unique transaction identifier
 * @param type         the transaction type (e.g. ZOMBIE_KILL_REWARD, ADMIN_CREDIT, ADMIN_DEBIT)
 * @param amount       the coin amount involved in the transaction
 * @param balanceAfter the player's balance after this transaction was applied
 * @param description  a human-readable description of the transaction
 * @param createdAt    the timestamp when the transaction was created
 */
public record TransactionDto(
        Long id,
        String type,
        long amount,
        long balanceAfter,
        String description,
        LocalDateTime createdAt
) {

    /**
     * Creates a {@code TransactionDto} from a {@link CurrencyTransaction} entity.
     *
     * @param tx the JPA currency transaction entity
     * @return a new DTO populated from the entity
     */
    public static TransactionDto fromTransaction(CurrencyTransaction tx) {
        return new TransactionDto(
                tx.getId(),
                tx.getType().name(),
                tx.getAmount(),
                tx.getBalanceAfter(),
                tx.getDescription(),
                tx.getCreatedAt()
        );
    }
}
