package com.discord.bot.raid.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/**
 * JPA entity representing a raid schedule configuration for a Discord guild.
 * Stores the raid time windows and the channel to update with raid status.
 */
@Entity
@Table(name = "raid_schedule")
public class RaidSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String guildId;

    /**
     * The Discord channel ID where the raid status will be displayed.
     * The channel name will be renamed to show the current status.
     */
    @Column(nullable = true)
    private String statusChannelId;

    /**
     * Start time of the raid window (when raid becomes enabled).
     */
    @Column(nullable = true)
    private LocalDateTime raidStartTime;

    /**
     * End time of the raid window (when raid becomes disabled).
     */
    @Column(nullable = true)
    private LocalDateTime raidEndTime;

    /**
     * Whether the raid schedule system is enabled for this guild.
     */
    @Column(nullable = false)
    private boolean enabled;

    /**
     * Current raid status (true = raid active/green, false = raid inactive/red).
     * This is calculated based on current time vs schedule.
     */
    @Column(nullable = false)
    private boolean raidActive;

    /** No-arg constructor required by JPA. */
    protected RaidSchedule() {
    }

    /**
     * Creates a new raid schedule configuration for the given guild with default values.
     *
     * @param guildId the Discord guild (server) ID
     */
    public RaidSchedule(String guildId) {
        this.guildId = guildId;
        this.enabled = false;
        this.raidActive = false;
    }

    // --- Getters and Setters ---

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getGuildId() {
        return guildId;
    }

    public void setGuildId(String guildId) {
        this.guildId = guildId;
    }

    public String getStatusChannelId() {
        return statusChannelId;
    }

    public void setStatusChannelId(String statusChannelId) {
        this.statusChannelId = statusChannelId;
    }

    public LocalDateTime getRaidStartTime() {
        return raidStartTime;
    }

    public void setRaidStartTime(LocalDateTime raidStartTime) {
        this.raidStartTime = raidStartTime;
    }

    public LocalDateTime getRaidEndTime() {
        return raidEndTime;
    }

    public void setRaidEndTime(LocalDateTime raidEndTime) {
        this.raidEndTime = raidEndTime;
    }

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public boolean isRaidActive() {
        return raidActive;
    }

    public void setRaidActive(boolean raidActive) {
        this.raidActive = raidActive;
    }
}
