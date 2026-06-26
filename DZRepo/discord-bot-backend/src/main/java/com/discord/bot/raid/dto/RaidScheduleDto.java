package com.discord.bot.raid.dto;

import com.discord.bot.raid.model.RaidSchedule;

import java.time.LocalDateTime;

/**
 * DTO for transferring raid schedule data to the admin panel.
 */
public class RaidScheduleDto {

    private Long id;
    private String guildId;
    private String statusChannelId;
    private LocalDateTime raidStartTime;
    private LocalDateTime raidEndTime;
    private boolean enabled;
    private boolean raidActive;

    public RaidScheduleDto() {
    }

    public static RaidScheduleDto fromEntity(RaidSchedule entity) {
        RaidScheduleDto dto = new RaidScheduleDto();
        dto.setId(entity.getId());
        dto.setGuildId(entity.getGuildId());
        dto.setStatusChannelId(entity.getStatusChannelId());
        dto.setRaidStartTime(entity.getRaidStartTime());
        dto.setRaidEndTime(entity.getRaidEndTime());
        dto.setEnabled(entity.isEnabled());
        dto.setRaidActive(entity.isRaidActive());
        return dto;
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
