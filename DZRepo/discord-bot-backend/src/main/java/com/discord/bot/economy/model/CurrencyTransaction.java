package com.discord.bot.economy.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/**
 * JPA entity representing a currency transaction in the economy system.
 * Each transaction records a change in a player's TNT Coins balance,
 * including the type, amount, resulting balance, and a description.
 */
@Entity
@Table(name = "currency_transactions")
public class CurrencyTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "player_profile_id", nullable = false)
    private PlayerProfile playerProfile;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TransactionType type;

    @Column(nullable = false)
    private long amount;

    @Column(nullable = false)
    private long balanceAfter;

    private String description;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    /** No-arg constructor required by JPA. */
    protected CurrencyTransaction() {
    }

    /**
     * Creates a new currency transaction with all required fields.
     *
     * @param playerProfile the player profile this transaction belongs to
     * @param type          the type of transaction
     * @param amount        the amount of coins involved
     * @param balanceAfter  the player's balance after this transaction
     * @param description   a human-readable description of the transaction
     * @param createdAt     the timestamp when this transaction was created
     */
    public CurrencyTransaction(PlayerProfile playerProfile, TransactionType type, long amount,
                               long balanceAfter, String description, LocalDateTime createdAt) {
        this.playerProfile = playerProfile;
        this.type = type;
        this.amount = amount;
        this.balanceAfter = balanceAfter;
        this.description = description;
        this.createdAt = createdAt;
    }

    // --- Getters and Setters ---

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public PlayerProfile getPlayerProfile() {
        return playerProfile;
    }

    public void setPlayerProfile(PlayerProfile playerProfile) {
        this.playerProfile = playerProfile;
    }

    public TransactionType getType() {
        return type;
    }

    public void setType(TransactionType type) {
        this.type = type;
    }

    public long getAmount() {
        return amount;
    }

    public void setAmount(long amount) {
        this.amount = amount;
    }

    public long getBalanceAfter() {
        return balanceAfter;
    }

    public void setBalanceAfter(long balanceAfter) {
        this.balanceAfter = balanceAfter;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
