package com.discord.bot.flagevent.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/**
 * JPA entity representing a currently active flag session.
 * Only one active session per guild (unique constraint on guildId).
 */
@Entity
@Table(name = "active_flag_session")
public class ActiveFlagSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String guildId;

    @Column(nullable = false)
    private String playerName;

    @Column(nullable = false)
    private String flagName;

    @Column(nullable = false)
    private LocalDateTime startTime;

    protected ActiveFlagSession() {}

    public ActiveFlagSession(String guildId, String playerName, String flagName, LocalDateTime startTime) {
        this.guildId = guildId;
        this.playerName = playerName;
        this.flagName = flagName;
        this.startTime = startTime;
    }

    public Long getId() { return id; }

    public String getGuildId() { return guildId; }
    public void setGuildId(String guildId) { this.guildId = guildId; }

    public String getPlayerName() { return playerName; }
    public void setPlayerName(String playerName) { this.playerName = playerName; }

    public String getFlagName() { return flagName; }
    public void setFlagName(String flagName) { this.flagName = flagName; }

    public LocalDateTime getStartTime() { return startTime; }
    public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }
}
