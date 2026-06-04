package com.discord.bot.economy.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/**
 * JPA entity representing a player's profile, linking a Discord account
 * to a DayZ player name with economy balance and gameplay statistics.
 */
@Entity
@Table(name = "player_profiles")
public class PlayerProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String discordId;

    @Column(unique = true, nullable = false)
    private String dayzPlayerName;

    @Column(nullable = false)
    private long balance;

    private int playerKills;

    private int deaths;

    private int zombieKills;

    private int zombieMeleeKills;

    @Column(nullable = false)
    private LocalDateTime linkedAt;

    private LocalDateTime lastActivity;

    /** No-arg constructor required by JPA. */
    protected PlayerProfile() {
    }

    /**
     * Creates a new player profile with the required fields.
     *
     * @param discordId      the Discord user ID
     * @param dayzPlayerName the DayZ in-game player name
     * @param linkedAt       the timestamp when the account was linked
     */
    public PlayerProfile(String discordId, String dayzPlayerName, LocalDateTime linkedAt) {
        this.discordId = discordId;
        this.dayzPlayerName = dayzPlayerName;
        this.linkedAt = linkedAt;
        this.balance = 0;
        this.playerKills = 0;
        this.deaths = 0;
        this.zombieKills = 0;
        this.zombieMeleeKills = 0;
    }

    // --- Getters and Setters ---

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getDiscordId() {
        return discordId;
    }

    public void setDiscordId(String discordId) {
        this.discordId = discordId;
    }

    public String getDayzPlayerName() {
        return dayzPlayerName;
    }

    public void setDayzPlayerName(String dayzPlayerName) {
        this.dayzPlayerName = dayzPlayerName;
    }

    public long getBalance() {
        return balance;
    }

    public void setBalance(long balance) {
        this.balance = balance;
    }

    public int getPlayerKills() {
        return playerKills;
    }

    public void setPlayerKills(int playerKills) {
        this.playerKills = playerKills;
    }

    public int getDeaths() {
        return deaths;
    }

    public void setDeaths(int deaths) {
        this.deaths = deaths;
    }

    public int getZombieKills() {
        return zombieKills;
    }

    public void setZombieKills(int zombieKills) {
        this.zombieKills = zombieKills;
    }

    public int getZombieMeleeKills() {
        return zombieMeleeKills;
    }

    public void setZombieMeleeKills(int zombieMeleeKills) {
        this.zombieMeleeKills = zombieMeleeKills;
    }

    public LocalDateTime getLinkedAt() {
        return linkedAt;
    }

    public void setLinkedAt(LocalDateTime linkedAt) {
        this.linkedAt = linkedAt;
    }

    public LocalDateTime getLastActivity() {
        return lastActivity;
    }

    public void setLastActivity(LocalDateTime lastActivity) {
        this.lastActivity = lastActivity;
    }
}
