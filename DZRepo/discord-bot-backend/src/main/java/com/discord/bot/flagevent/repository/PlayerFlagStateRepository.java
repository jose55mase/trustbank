package com.discord.bot.flagevent.repository;

import com.discord.bot.flagevent.model.PlayerFlagState;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PlayerFlagStateRepository extends JpaRepository<PlayerFlagState, Long> {
    List<PlayerFlagState> findByGuildId(String guildId);
    Optional<PlayerFlagState> findByGuildIdAndPlayerNameAndFlagName(String guildId, String playerName, String flagName);
}
