package com.discord.bot.economy.dto;

import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.service.PlayerStatsService;

import java.time.LocalDateTime;

/**
 * Response DTO representing a player's statistics and economy balance.
 *
 * <p>Used by the REST API ({@code GET /api/players/stats} and
 * {@code GET /api/players/{discordId}/stats}) to expose player data
 * without leaking JPA entity internals.</p>
 *
 * @param discordId        the player's Discord user ID
 * @param dayzPlayerName   the linked DayZ in-game name
 * @param playerKills      total player-vs-player kills
 * @param deaths           total deaths
 * @param kdRatio          formatted K/D ratio (2 decimals) or "N/A" when deaths is 0
 * @param zombieKills      total zombie kills (all weapons)
 * @param zombieMeleeKills zombie kills with melee weapons only
 * @param balance          current TNT Coins balance
 * @param lastActivity     timestamp of the player's last recorded activity
 */
public record PlayerStatsDto(
        String discordId,
        String dayzPlayerName,
        int playerKills,
        int deaths,
        String kdRatio,
        int zombieKills,
        int zombieMeleeKills,
        long balance,
        LocalDateTime lastActivity
) {

    /**
     * Creates a {@code PlayerStatsDto} from a {@link PlayerProfile} entity,
     * calculating the K/D ratio via {@link PlayerStatsService#calculateKdRatio}.
     *
     * @param profile the JPA player profile entity
     * @return a new DTO populated from the entity
     */
    public static PlayerStatsDto fromProfile(PlayerProfile profile) {
        return new PlayerStatsDto(
                profile.getDiscordId(),
                profile.getDayzPlayerName(),
                profile.getPlayerKills(),
                profile.getDeaths(),
                PlayerStatsService.calculateKdRatio(profile.getPlayerKills(), profile.getDeaths()),
                profile.getZombieKills(),
                profile.getZombieMeleeKills(),
                profile.getBalance(),
                profile.getLastActivity()
        );
    }
}
