package com.discord.bot.economy.repository;

import com.discord.bot.economy.model.EconomyConfig;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * Spring Data JPA repository for {@link EconomyConfig} entities.
 * Provides CRUD operations and a custom query method to look up
 * economy configuration by Discord guild ID.
 */
public interface EconomyConfigRepository extends JpaRepository<EconomyConfig, Long> {

    Optional<EconomyConfig> findByGuildId(String guildId);
}
