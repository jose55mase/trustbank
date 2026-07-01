package com.discord.bot.flagevent.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * JPA entity representing the configured flag location for a guild.
 * Only one location can be configured per guild (unique constraint on guildId).
 */
@Entity
@Table(name = "flag_location")
public class FlagLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String guildId;

    @Column(nullable = false)
    private double coordX;

    @Column(nullable = false)
    private double coordZ;

    @Column(nullable = false)
    private double tolerance;

    @Column(nullable = true)
    private String notificationChannelId;

    @Column(nullable = false)
    private boolean enabled = false;

    protected FlagLocation() {}

    public FlagLocation(String guildId, double coordX, double coordZ, double tolerance) {
        this.guildId = guildId;
        this.coordX = coordX;
        this.coordZ = coordZ;
        this.tolerance = tolerance;
    }

    public Long getId() { return id; }

    public String getGuildId() { return guildId; }
    public void setGuildId(String guildId) { this.guildId = guildId; }

    public double getCoordX() { return coordX; }
    public void setCoordX(double coordX) { this.coordX = coordX; }

    public double getCoordZ() { return coordZ; }
    public void setCoordZ(double coordZ) { this.coordZ = coordZ; }

    public double getTolerance() { return tolerance; }
    public void setTolerance(double tolerance) { this.tolerance = tolerance; }

    public String getNotificationChannelId() { return notificationChannelId; }
    public void setNotificationChannelId(String notificationChannelId) { this.notificationChannelId = notificationChannelId; }

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }
}
