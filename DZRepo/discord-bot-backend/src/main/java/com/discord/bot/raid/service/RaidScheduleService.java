package com.discord.bot.raid.service;

import com.discord.bot.BotInitializer;
import com.discord.bot.raid.dto.RaidScheduleUpdateDto;
import com.discord.bot.raid.model.RaidSchedule;
import com.discord.bot.raid.repository.RaidScheduleRepository;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.entities.channel.concrete.VoiceChannel;
import net.dv8tion.jda.api.entities.channel.middleman.GuildChannel;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

/**
 * Service for managing raid schedules and updating Discord channel names
 * to reflect the current raid status.
 */
@Service
public class RaidScheduleService {

    private static final Logger log = LoggerFactory.getLogger(RaidScheduleService.class);

    /** Channel name when raid is INACTIVE (red circle). */
    public static final String CHANNEL_NAME_RAID_OFF = "💥-raid-status-🔴";

    /** Channel name when raid is ACTIVE (green circle). */
    public static final String CHANNEL_NAME_RAID_ON = "💥-raid-status-🟢";

    private final RaidScheduleRepository raidScheduleRepository;
    private final BotInitializer botInitializer;

    public RaidScheduleService(RaidScheduleRepository raidScheduleRepository,
                               BotInitializer botInitializer) {
        this.raidScheduleRepository = raidScheduleRepository;
        this.botInitializer = botInitializer;
    }

    /**
     * Gets the raid schedule configuration for a guild.
     * Creates a default configuration if none exists.
     *
     * @param guildId the Discord guild ID
     * @return the raid schedule configuration
     */
    @Transactional
    public RaidSchedule getOrCreateSchedule(String guildId) {
        return raidScheduleRepository.findByGuildId(guildId)
                .orElseGet(() -> raidScheduleRepository.save(new RaidSchedule(guildId)));
    }

    /**
     * Updates the raid schedule configuration for a guild.
     *
     * @param guildId the Discord guild ID
     * @param dto the update data
     * @return the updated raid schedule
     */
    @Transactional
    public RaidSchedule updateSchedule(String guildId, RaidScheduleUpdateDto dto) {
        RaidSchedule schedule = getOrCreateSchedule(guildId);

        if (dto.getStatusChannelId() != null) {
            schedule.setStatusChannelId(dto.getStatusChannelId());
        }
        if (dto.getRaidStartTime() != null) {
            schedule.setRaidStartTime(dto.getRaidStartTime());
        }
        if (dto.getRaidEndTime() != null) {
            schedule.setRaidEndTime(dto.getRaidEndTime());
        }
        if (dto.getEnabled() != null) {
            schedule.setEnabled(dto.getEnabled());
        }

        RaidSchedule saved = raidScheduleRepository.save(schedule);

        // Immediately check and update status if enabled
        if (saved.isEnabled()) {
            checkAndUpdateRaidStatus(saved);
        }

        return saved;
    }

    /**
     * Gets all enabled raid schedules.
     *
     * @return list of enabled raid schedules
     */
    public List<RaidSchedule> getAllEnabledSchedules() {
        return raidScheduleRepository.findByEnabledTrue();
    }

    /**
     * Checks if raid should be active based on current time and schedule,
     * and updates the Discord channel name if the status changed.
     *
     * @param schedule the raid schedule to check
     */
    @Transactional
    public void checkAndUpdateRaidStatus(RaidSchedule schedule) {
        if (!schedule.isEnabled() || schedule.getStatusChannelId() == null) {
            return;
        }

        boolean shouldBeActive = isRaidTimeActive(schedule);
        boolean statusChanged = shouldBeActive != schedule.isRaidActive();

        if (statusChanged) {
            schedule.setRaidActive(shouldBeActive);
            raidScheduleRepository.save(schedule);
            updateChannelName(schedule);
            log.info("Raid status changed for guild {}: now {}", 
                    schedule.getGuildId(), shouldBeActive ? "ACTIVE 🟢" : "INACTIVE 🔴");
        }
    }

    /**
     * Determines if the current time falls within the raid time window.
     * Supports schedules that cross midnight (e.g., 22:00 to 06:00).
     *
     * @param schedule the raid schedule
     * @return true if raid should be active
     */
    public boolean isRaidTimeActive(RaidSchedule schedule) {
        if (schedule.getRaidStartTime() == null || schedule.getRaidEndTime() == null) {
            return false;
        }

        LocalDateTime now = LocalDateTime.now();
        LocalTime currentTime = now.toLocalTime();
        LocalTime startTime = schedule.getRaidStartTime().toLocalTime();
        LocalTime endTime = schedule.getRaidEndTime().toLocalTime();

        // Handle schedules that cross midnight
        if (startTime.isAfter(endTime)) {
            // e.g., 22:00 to 06:00 - raid is active if current time is after start OR before end
            return !currentTime.isBefore(startTime) || !currentTime.isAfter(endTime);
        } else {
            // e.g., 10:00 to 18:00 - raid is active if current time is between start and end
            return !currentTime.isBefore(startTime) && !currentTime.isAfter(endTime);
        }
    }

    /**
     * Updates the Discord channel name to reflect the current raid status.
     *
     * @param schedule the raid schedule with the channel to update
     */
    public void updateChannelName(RaidSchedule schedule) {
        JDA jda = botInitializer.getJda();
        if (jda == null) {
            log.warn("JDA not available, cannot update channel name");
            return;
        }

        String channelId = schedule.getStatusChannelId();
        if (channelId == null || channelId.isBlank()) {
            log.warn("No status channel configured for guild {}", schedule.getGuildId());
            return;
        }

        String newName = schedule.isRaidActive() ? CHANNEL_NAME_RAID_ON : CHANNEL_NAME_RAID_OFF;

        try {
            GuildChannel channel = jda.getGuildChannelById(channelId);
            if (channel == null) {
                log.warn("Channel {} not found for guild {}", channelId, schedule.getGuildId());
                return;
            }

            // Check if name already matches to avoid rate limits
            if (channel.getName().equals(newName)) {
                log.debug("Channel name already matches: {}", newName);
                return;
            }

            channel.getManager().setName(newName).queue(
                    success -> log.info("Updated raid status channel to: {}", newName),
                    error -> log.error("Failed to update channel name: {}", error.getMessage())
            );
        } catch (Exception e) {
            log.error("Error updating channel name for guild {}: {}", 
                    schedule.getGuildId(), e.getMessage(), e);
        }
    }

    /**
     * Forces an immediate update of the channel name for a schedule.
     * Used when the schedule is first configured or manually triggered.
     *
     * @param guildId the guild ID
     */
    @Transactional
    public void forceUpdateStatus(String guildId) {
        Optional<RaidSchedule> scheduleOpt = raidScheduleRepository.findByGuildId(guildId);
        if (scheduleOpt.isEmpty()) {
            return;
        }

        RaidSchedule schedule = scheduleOpt.get();
        if (!schedule.isEnabled()) {
            return;
        }

        boolean shouldBeActive = isRaidTimeActive(schedule);
        schedule.setRaidActive(shouldBeActive);
        raidScheduleRepository.save(schedule);
        updateChannelName(schedule);
    }
}
