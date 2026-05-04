package com.discord.bot.economy.repository;

import com.discord.bot.economy.model.PlayerProfile;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

/**
 * Spring Data JPA repository for {@link PlayerProfile} entities.
 * Provides CRUD operations and custom query methods for player lookups
 * and leaderboard queries.
 */
public interface PlayerProfileRepository extends JpaRepository<PlayerProfile, Long> {

    Optional<PlayerProfile> findByDiscordId(String discordId);

    Optional<PlayerProfile> findByDayzPlayerName(String dayzPlayerName);

    Optional<PlayerProfile> findByDayzPlayerNameIgnoreCase(String dayzPlayerName);

    List<PlayerProfile> findTop10ByOrderByPlayerKillsDesc();

    List<PlayerProfile> findTop10ByOrderByZombieKillsDesc();

    List<PlayerProfile> findTop10ByOrderByBalanceDesc();

    @Query("SELECT p FROM PlayerProfile p WHERE p.deaths >= 5 ORDER BY (p.playerKills * 1.0 / p.deaths) DESC")
    List<PlayerProfile> findTop10ByKdRatio(Pageable pageable);
}
