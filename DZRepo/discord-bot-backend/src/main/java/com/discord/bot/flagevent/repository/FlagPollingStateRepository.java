package com.discord.bot.flagevent.repository;

import com.discord.bot.flagevent.model.FlagPollingState;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FlagPollingStateRepository extends JpaRepository<FlagPollingState, Long> {
    Optional<FlagPollingState> findByGuildId(String guildId);
}
