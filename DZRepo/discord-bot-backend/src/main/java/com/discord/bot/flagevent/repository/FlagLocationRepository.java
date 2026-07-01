package com.discord.bot.flagevent.repository;

import com.discord.bot.flagevent.model.FlagLocation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FlagLocationRepository extends JpaRepository<FlagLocation, Long> {
    Optional<FlagLocation> findByGuildId(String guildId);
}
