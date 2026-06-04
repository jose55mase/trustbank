package com.discord.bot.economy.service;

import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.repository.PlayerProfileRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Service responsible for tracking and querying player statistics:
 * kills, deaths, zombie kills, and leaderboard queries.
 *
 * <p>Increment methods look up players by their DayZ name (case-insensitive).
 * If the player is not linked, a warning is logged and the call returns
 * silently — no exception is thrown.</p>
 */
@Service
public class PlayerStatsService {

    private static final Logger log = LoggerFactory.getLogger(PlayerStatsService.class);

    private final PlayerProfileRepository playerProfileRepository;

    public PlayerStatsService(PlayerProfileRepository playerProfileRepository) {
        this.playerProfileRepository = playerProfileRepository;
    }

    // ---- Increment methods ----

    /**
     * Increments the player-kill counter for the player identified by their
     * DayZ in-game name (case-insensitive). Also updates {@code lastActivity}.
     *
     * @param killerName the DayZ player name of the killer
     */
    public void incrementPlayerKills(String killerName) {
        Optional<PlayerProfile> optProfile = playerProfileRepository
                .findByDayzPlayerNameIgnoreCase(killerName);

        if (optProfile.isEmpty()) {
            log.warn("Player '{}' not found (not linked). Skipping player kill increment.", killerName);
            return;
        }

        PlayerProfile profile = optProfile.get();
        profile.setPlayerKills(profile.getPlayerKills() + 1);
        profile.setLastActivity(LocalDateTime.now());
        playerProfileRepository.save(profile);
        log.debug("Incremented playerKills for '{}'. New count: {}", killerName, profile.getPlayerKills());
    }

    /**
     * Increments the death counter for the player identified by their
     * DayZ in-game name (case-insensitive). Also updates {@code lastActivity}.
     *
     * @param victimName the DayZ player name of the victim
     */
    public void incrementDeaths(String victimName) {
        Optional<PlayerProfile> optProfile = playerProfileRepository
                .findByDayzPlayerNameIgnoreCase(victimName);

        if (optProfile.isEmpty()) {
            log.warn("Player '{}' not found (not linked). Skipping death increment.", victimName);
            return;
        }

        PlayerProfile profile = optProfile.get();
        profile.setDeaths(profile.getDeaths() + 1);
        profile.setLastActivity(LocalDateTime.now());
        playerProfileRepository.save(profile);
        log.debug("Incremented deaths for '{}'. New count: {}", victimName, profile.getDeaths());
    }

    /**
     * Increments the zombie-kill counter for the player identified by their
     * DayZ in-game name (case-insensitive). Also updates {@code lastActivity}.
     *
     * @param playerName the DayZ player name
     */
    public void incrementZombieKills(String playerName) {
        Optional<PlayerProfile> optProfile = playerProfileRepository
                .findByDayzPlayerNameIgnoreCase(playerName);

        if (optProfile.isEmpty()) {
            log.warn("Player '{}' not found (not linked). Skipping zombie kill increment.", playerName);
            return;
        }

        PlayerProfile profile = optProfile.get();
        profile.setZombieKills(profile.getZombieKills() + 1);
        profile.setLastActivity(LocalDateTime.now());
        playerProfileRepository.save(profile);
        log.debug("Incremented zombieKills for '{}'. New count: {}", playerName, profile.getZombieKills());
    }

    /**
     * Increments both the zombie-melee-kill counter <em>and</em> the general
     * zombie-kill counter for the player identified by their DayZ in-game name
     * (case-insensitive). A melee kill is also a zombie kill.
     * Also updates {@code lastActivity}.
     *
     * @param playerName the DayZ player name
     */
    public void incrementZombieMeleeKills(String playerName) {
        Optional<PlayerProfile> optProfile = playerProfileRepository
                .findByDayzPlayerNameIgnoreCase(playerName);

        if (optProfile.isEmpty()) {
            log.warn("Player '{}' not found (not linked). Skipping zombie melee kill increment.", playerName);
            return;
        }

        PlayerProfile profile = optProfile.get();
        profile.setZombieMeleeKills(profile.getZombieMeleeKills() + 1);
        profile.setZombieKills(profile.getZombieKills() + 1);
        profile.setLastActivity(LocalDateTime.now());
        playerProfileRepository.save(profile);
        log.debug("Incremented zombieMeleeKills for '{}'. New melee count: {}, total zombie count: {}",
                playerName, profile.getZombieMeleeKills(), profile.getZombieKills());
    }

    // ---- Query methods ----

    /**
     * Returns the player profile for the given Discord ID, if linked.
     *
     * @param discordId the Discord user ID
     * @return an {@link Optional} containing the profile, or empty if not found
     */
    public Optional<PlayerProfile> getStats(String discordId) {
        return playerProfileRepository.findByDiscordId(discordId);
    }

    /**
     * Returns the top 10 players ordered by player kills (descending).
     *
     * @return list of up to 10 player profiles
     */
    public List<PlayerProfile> getTopKills() {
        return playerProfileRepository.findTop10ByOrderByPlayerKillsDesc();
    }

    /**
     * Returns the top 10 players ordered by zombie kills (descending).
     *
     * @return list of up to 10 player profiles
     */
    public List<PlayerProfile> getTopZombieKills() {
        return playerProfileRepository.findTop10ByOrderByZombieKillsDesc();
    }

    /**
     * Returns the top 10 players ordered by balance (descending).
     *
     * @return list of up to 10 player profiles
     */
    public List<PlayerProfile> getTopBalance() {
        return playerProfileRepository.findTop10ByOrderByBalanceDesc();
    }

    /**
     * Returns the top 10 players ordered by K/D ratio (descending),
     * filtered to only include players with at least 5 deaths.
     *
     * @return list of up to 10 player profiles
     */
    public List<PlayerProfile> getTopKd() {
        return playerProfileRepository.findTop10ByKdRatio(PageRequest.of(0, 10));
    }

    /**
     * Returns all linked player profiles.
     *
     * @return list of all player profiles
     */
    public List<PlayerProfile> getAllLinkedPlayers() {
        return playerProfileRepository.findAll();
    }

    // ---- Utility methods ----

    /**
     * Calculates the K/D ratio as a formatted string.
     *
     * @param kills  the number of kills (must be &gt;= 0)
     * @param deaths the number of deaths (must be &gt;= 0)
     * @return the K/D ratio formatted to 2 decimal places, or "N/A" if deaths is 0
     */
    public static String calculateKdRatio(int kills, int deaths) {
        if (deaths == 0) {
            return "N/A";
        }
        return String.format("%.2f", (double) kills / deaths);
    }
}
