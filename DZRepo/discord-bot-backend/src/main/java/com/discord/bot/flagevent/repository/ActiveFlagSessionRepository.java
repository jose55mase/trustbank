package com.discord.bot.flagevent.repository;

import com.discord.bot.flagevent.model.ActiveFlagSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ActiveFlagSessionRepository extends JpaRepository<ActiveFlagSession, Long> {
    Optional<ActiveFlagSession> findByGuildId(String guildId);
}
