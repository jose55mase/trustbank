package com.discord.bot.raid.repository;

import com.discord.bot.raid.model.RaidSchedule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * Spring Data JPA repository for {@link RaidSchedule} entities.
 * Provides CRUD operations and custom query methods for raid schedule management.
 */
public interface RaidScheduleRepository extends JpaRepository<RaidSchedule, Long> {

    /**
     * Finds the raid schedule configuration for a specific guild.
     *
     * @param guildId the Discord guild ID
     * @return the raid schedule if found
     */
    Optional<RaidSchedule> findByGuildId(String guildId);

    /**
     * Finds all enabled raid schedules for processing by the scheduler.
     *
     * @return list of enabled raid schedules
     */
    List<RaidSchedule> findByEnabledTrue();
}
