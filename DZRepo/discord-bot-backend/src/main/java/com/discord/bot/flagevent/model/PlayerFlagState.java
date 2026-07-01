package com.discord.bot.flagevent.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * JPA entity tracking the accumulated flag time for a player in a guild.
 */
@Entity
@Table(name = "player_flag_state")
public class PlayerFlagState {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String guildId;

    @Column(nullable = false)
    private String playerName;

    @Column(nullable = false)
    private String flagName;

    @Column(nullable = false)
    private long accumulatedSeconds;

    protected PlayerFlagState() {}

    public PlayerFlagState(String guildId, String playerName, String flagName, long accumulatedSeconds) {
        this.guildId = guildId;
        this.playerName = playerName;
        this.flagName = flagName;
        this.accumulatedSeconds = accumulatedSeconds;
    }

    public Long getId() { return id; }

    public String getGuildId() { return guildId; }
    public void setGuildId(String guildId) { this.guildId = guildId; }

    public String getPlayerName() { return playerName; }
    public void setPlayerName(String playerName) { this.playerName = playerName; }

    public String getFlagName() { return flagName; }
    public void setFlagName(String flagName) { this.flagName = flagName; }

    public long getAccumulatedSeconds() { return accumulatedSeconds; }
    public void setAccumulatedSeconds(long accumulatedSeconds) { this.accumulatedSeconds = accumulatedSeconds; }
}
