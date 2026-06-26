package com.discord.bot.raid.dto;

import java.time.LocalDateTime;

/**
 * DTO for updating raid schedule configuration from the admin panel.
 * All fields are optional - only non-null values will be applied.
 */
public class RaidScheduleUpdateDto {

    private String statusChannelId;
    private LocalDateTime raidStartTime;
    private LocalDateTime raidEndTime;
    private Boolean enabled;

    public RaidScheduleUpdateDto() {
    }

    // --- Getters and Setters ---

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

    public Boolean getEnabled() {
        return enabled;
    }

    public void setEnabled(Boolean enabled) {
        this.enabled = enabled;
    }
}
