package com.discord.bot.economy.service;

import com.discord.bot.economy.exception.DayzNameAlreadyLinkedException;
import com.discord.bot.economy.exception.PlayerNotLinkedException;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.repository.PlayerProfileRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * Service responsible for managing the link between Discord accounts
 * and DayZ player names.
 *
 * <p>Enforces uniqueness of DayZ names across Discord accounts and
 * supports re-linking (replacing an existing link with a new DayZ name).</p>
 */
@Service
public class PlayerLinkService {

    private static final Logger log = LoggerFactory.getLogger(PlayerLinkService.class);

    private final PlayerProfileRepository playerProfileRepository;

    public PlayerLinkService(PlayerProfileRepository playerProfileRepository) {
        this.playerProfileRepository = playerProfileRepository;
    }

    /**
     * Links a Discord account to a DayZ player name.
     *
     * <p>If the Discord ID already has a profile, the DayZ name is updated (re-link).
     * If the DayZ name is already taken by a different Discord ID, a
     * {@link DayzNameAlreadyLinkedException} is thrown.</p>
     *
     * @param discordId the Discord user ID
     * @param dayzName  the DayZ in-game player name
     * @return the created or updated {@link PlayerProfile}
     * @throws DayzNameAlreadyLinkedException if the DayZ name is linked to another Discord account
     */
    @Transactional
    public PlayerProfile linkPlayer(String discordId, String dayzName) {
        // Check if the DayZ name is already taken by another Discord account
        Optional<PlayerProfile> existingByName = playerProfileRepository
                .findByDayzPlayerNameIgnoreCase(dayzName);

        if (existingByName.isPresent() && !existingByName.get().getDiscordId().equals(discordId)) {
            throw new DayzNameAlreadyLinkedException(
                    "El nombre DayZ '" + dayzName + "' ya está vinculado a otra cuenta de Discord.",
                    dayzName
            );
        }

        // Check if the Discord ID already has a profile (re-link scenario)
        Optional<PlayerProfile> existingByDiscord = playerProfileRepository.findByDiscordId(discordId);

        if (existingByDiscord.isPresent()) {
            PlayerProfile profile = existingByDiscord.get();
            log.info("Re-linking Discord ID {} from '{}' to '{}'",
                    discordId, profile.getDayzPlayerName(), dayzName);
            profile.setDayzPlayerName(dayzName);
            return playerProfileRepository.save(profile);
        }

        // Create a new profile
        log.info("Linking Discord ID {} to DayZ name '{}'", discordId, dayzName);
        PlayerProfile newProfile = new PlayerProfile(discordId, dayzName, LocalDateTime.now());
        return playerProfileRepository.save(newProfile);
    }

    /**
     * Removes the link between a Discord account and its DayZ player name.
     *
     * @param discordId the Discord user ID to unlink
     * @throws PlayerNotLinkedException if no profile exists for the given Discord ID
     */
    @Transactional
    public void unlinkPlayer(String discordId) {
        PlayerProfile profile = playerProfileRepository.findByDiscordId(discordId)
                .orElseThrow(() -> new PlayerNotLinkedException(
                        "No se encontró una cuenta vinculada para el Discord ID: " + discordId));

        log.info("Unlinking Discord ID {} (DayZ name: '{}')", discordId, profile.getDayzPlayerName());
        playerProfileRepository.delete(profile);
    }

    /**
     * Finds a player profile by Discord ID.
     *
     * @param discordId the Discord user ID
     * @return an {@link Optional} containing the profile, or empty if not found
     */
    public Optional<PlayerProfile> findByDiscordId(String discordId) {
        return playerProfileRepository.findByDiscordId(discordId);
    }

    /**
     * Finds a player profile by DayZ player name (case-insensitive).
     *
     * @param dayzName the DayZ in-game player name
     * @return an {@link Optional} containing the profile, or empty if not found
     */
    public Optional<PlayerProfile> findByDayzName(String dayzName) {
        return playerProfileRepository.findByDayzPlayerNameIgnoreCase(dayzName);
    }

    /**
     * Checks whether a DayZ player name is already linked to any Discord account
     * (case-insensitive).
     *
     * @param dayzName the DayZ in-game player name to check
     * @return {@code true} if the name is already taken, {@code false} otherwise
     */
    public boolean isDayzNameTaken(String dayzName) {
        return playerProfileRepository.findByDayzPlayerNameIgnoreCase(dayzName).isPresent();
    }
}
