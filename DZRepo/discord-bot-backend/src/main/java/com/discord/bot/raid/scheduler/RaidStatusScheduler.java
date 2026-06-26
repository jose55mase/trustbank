package com.discord.bot.raid.scheduler;

import com.discord.bot.raid.model.RaidSchedule;
import com.discord.bot.raid.service.RaidScheduleService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Scheduled task that periodically checks and updates raid status for all enabled schedules.
 * Runs every minute to ensure timely status updates.
 */
@Component
@EnableScheduling
public class RaidStatusScheduler {

    private static final Logger log = LoggerFactory.getLogger(RaidStatusScheduler.class);

    private final RaidScheduleService raidScheduleService;

    public RaidStatusScheduler(RaidScheduleService raidScheduleService) {
        this.raidScheduleService = raidScheduleService;
    }

    /**
     * Checks all enabled raid schedules every minute and updates channel names if needed.
     * Discord has rate limits on channel name changes (2 per 10 minutes per channel),
     * so we only update when the status actually changes.
     */
    @Scheduled(fixedRate = 60000) // Every 60 seconds
    public void checkRaidStatus() {
        List<RaidSchedule> enabledSchedules = raidScheduleService.getAllEnabledSchedules();
        
        if (enabledSchedules.isEmpty()) {
            return;
        }

        log.debug("Checking raid status for {} enabled schedules", enabledSchedules.size());

        for (RaidSchedule schedule : enabledSchedules) {
            try {
                raidScheduleService.checkAndUpdateRaidStatus(schedule);
            } catch (Exception e) {
                log.error("Error checking raid status for guild {}: {}", 
                        schedule.getGuildId(), e.getMessage(), e);
            }
        }
    }
}
