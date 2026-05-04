package com.discord.bot.economy.service;

import com.discord.bot.economy.model.EconomyConfig;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.model.TransactionType;
import com.discord.bot.economy.model.ZombieKillEvent;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

/**
 * Service responsible for processing zombie kill events and awarding
 * TNT Coins to linked players who use melee weapons.
 *
 * <p>For each {@link ZombieKillEvent}, this service:</p>
 * <ol>
 *   <li>Checks if the economy system is enabled for the guild.</li>
 *   <li>Looks up the player by DayZ name to verify they are linked.</li>
 *   <li>Increments the appropriate zombie kill statistics.</li>
 *   <li>Awards coins if the weapon used is classified as melee.</li>
 * </ol>
 *
 * <p>Unlinked players and non-melee kills still have their statistics
 * tracked, but no coin reward is issued.</p>
 */
@Service
public class ZombieKillRewardService {

    private static final Logger log = LoggerFactory.getLogger(ZombieKillRewardService.class);

    private final PlayerLinkService playerLinkService;
    private final EconomyService economyService;
    private final PlayerStatsService playerStatsService;

    public ZombieKillRewardService(PlayerLinkService playerLinkService,
                                   EconomyService economyService,
                                   PlayerStatsService playerStatsService) {
        this.playerLinkService = playerLinkService;
        this.economyService = economyService;
        this.playerStatsService = playerStatsService;
    }

    /**
     * Processes a list of zombie kill events for the given guild.
     *
     * <p>If the economy system is disabled for the guild, all events are skipped.
     * Otherwise, each event is processed individually: statistics are updated
     * and coins are awarded when applicable.</p>
     *
     * @param events  the list of zombie kill events to process
     * @param guildId the Discord guild (server) ID
     */
    public void processZombieKills(List<ZombieKillEvent> events, String guildId) {
        if (events == null || events.isEmpty()) {
            log.debug("No zombie kill events to process for guild '{}'.", guildId);
            return;
        }

        EconomyConfig config = economyService.getConfig(guildId);
        if (!config.isEnabled()) {
            log.debug("Economy system is disabled for guild '{}'. Skipping {} zombie kill events.",
                    guildId, events.size());
            return;
        }

        log.info("Processing {} zombie kill events for guild '{}'.", events.size(), guildId);

        for (ZombieKillEvent event : events) {
            processEvent(event, guildId, config);
        }
    }

    /**
     * Processes a single zombie kill event.
     *
     * @param event   the zombie kill event
     * @param guildId the Discord guild ID
     * @param config  the economy configuration for the guild
     */
    private void processEvent(ZombieKillEvent event, String guildId, EconomyConfig config) {
        String playerName = event.playerName();
        String weapon = event.weapon();

        // Check if the player is linked
        Optional<PlayerProfile> optProfile = playerLinkService.findByDayzName(playerName);

        if (optProfile.isEmpty()) {
            log.debug("Player '{}' is not linked. Skipping coin reward for zombie kill.", playerName);
            return;
        }

        PlayerProfile profile = optProfile.get();

        // If weapon is null, just increment zombie kills (no reward possible)
        if (weapon == null) {
            playerStatsService.incrementZombieKills(playerName);
            log.debug("Player '{}' killed a zombie without a detected weapon. Stats incremented, no reward.",
                    playerName);
            return;
        }

        // Check if the weapon is melee
        if (economyService.isMeleeWeapon(weapon, guildId)) {
            // Melee kill: increment melee stats (which also increments general zombie kills)
            playerStatsService.incrementZombieMeleeKills(playerName);

            // Award coins
            int coinsPerKill = config.getCoinsPerZombieKill();
            String description = String.format("Zombie kill: %s with %s", event.zombieType(), weapon);
            economyService.creditCoins(profile, coinsPerKill, TransactionType.ZOMBIE_KILL_REWARD, description);

            log.info("Awarded {} TNT Coins to player '{}' for melee zombie kill ({} with {}).",
                    coinsPerKill, playerName, event.zombieType(), weapon);
        } else {
            // Non-melee kill: only increment zombie kills, no coin reward
            playerStatsService.incrementZombieKills(playerName);
            log.debug("Player '{}' killed zombie '{}' with non-melee weapon '{}'. Stats incremented, no reward.",
                    playerName, event.zombieType(), weapon);
        }
    }
}
