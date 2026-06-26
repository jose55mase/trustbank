package com.discord.bot.raid.controller;

import com.discord.bot.raid.dto.RaidScheduleDto;
import com.discord.bot.raid.dto.RaidScheduleUpdateDto;
import com.discord.bot.raid.model.RaidSchedule;
import com.discord.bot.raid.service.RaidScheduleService;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for raid schedule configuration.
 * 
 * <p>Exposes endpoints consumed by the Flutter admin app to configure
 * raid time windows and the status channel.</p>
 */
@RestController
@RequestMapping("/api/raid")
public class RaidScheduleController {

    private final RaidScheduleService raidScheduleService;

    public RaidScheduleController(RaidScheduleService raidScheduleService) {
        this.raidScheduleService = raidScheduleService;
    }

    /**
     * Returns the raid schedule configuration for the given guild.
     * If no configuration exists yet, a default one is created automatically.
     *
     * @param guildId the Discord guild (server) ID
     * @return the current raid schedule configuration
     */
    @GetMapping("/schedule")
    public RaidScheduleDto getSchedule(@RequestParam String guildId) {
        RaidSchedule schedule = raidScheduleService.getOrCreateSchedule(guildId);
        return RaidScheduleDto.fromEntity(schedule);
    }

    /**
     * Updates the raid schedule configuration for the given guild.
     * Only non-null fields in the request body are applied.
     *
     * @param guildId the Discord guild (server) ID
     * @param dto the update payload with optional fields
     * @return the updated raid schedule configuration
     */
    @PutMapping("/schedule")
    public RaidScheduleDto updateSchedule(@RequestParam String guildId,
                                          @RequestBody @Valid RaidScheduleUpdateDto dto) {
        RaidSchedule schedule = raidScheduleService.updateSchedule(guildId, dto);
        return RaidScheduleDto.fromEntity(schedule);
    }

    /**
     * Forces an immediate update of the raid status channel.
     * Useful for testing or when you want to manually trigger an update.
     *
     * @param guildId the Discord guild (server) ID
     * @return success response
     */
    @PostMapping("/force-update")
    public ResponseEntity<String> forceUpdate(@RequestParam String guildId) {
        raidScheduleService.forceUpdateStatus(guildId);
        return ResponseEntity.ok("Raid status update triggered");
    }

    /**
     * Checks if raid is currently active for the given guild.
     *
     * @param guildId the Discord guild (server) ID
     * @return the current raid active status
     */
    @GetMapping("/status")
    public ResponseEntity<RaidStatusResponse> getRaidStatus(@RequestParam String guildId) {
        RaidSchedule schedule = raidScheduleService.getOrCreateSchedule(guildId);
        boolean isActive = schedule.isEnabled() && raidScheduleService.isRaidTimeActive(schedule);
        return ResponseEntity.ok(new RaidStatusResponse(isActive, schedule.isEnabled()));
    }

    /**
     * Simple response object for raid status check.
     */
    public record RaidStatusResponse(boolean raidActive, boolean enabled) {}
}
