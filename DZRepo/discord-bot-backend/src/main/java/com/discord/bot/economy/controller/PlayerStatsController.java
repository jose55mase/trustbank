package com.discord.bot.economy.controller;

import com.discord.bot.economy.dto.PlayerStatsDto;
import com.discord.bot.economy.exception.PlayerNotLinkedException;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.service.PlayerStatsService;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * REST controller for player statistics.
 *
 * <p>Exposes endpoints consumed by the Flutter admin app to view
 * linked players and their individual statistics.</p>
 */
@RestController
@RequestMapping("/api/players")
public class PlayerStatsController {

    private final PlayerStatsService playerStatsService;

    public PlayerStatsController(PlayerStatsService playerStatsService) {
        this.playerStatsService = playerStatsService;
    }

    /**
     * Returns statistics for all linked players.
     *
     * @return list of player stats DTOs
     */
    @GetMapping("/stats")
    public List<PlayerStatsDto> getAllPlayerStats() {
        return playerStatsService.getAllLinkedPlayers().stream()
                .map(PlayerStatsDto::fromProfile)
                .toList();
    }

    /**
     * Returns statistics for a specific player identified by their Discord ID.
     *
     * @param discordId the Discord user ID
     * @return the player stats DTO
     * @throws PlayerNotLinkedException if no player is linked with the given Discord ID
     */
    @GetMapping("/{discordId}/stats")
    public PlayerStatsDto getPlayerStats(@PathVariable String discordId) {
        PlayerProfile profile = playerStatsService.getStats(discordId)
                .orElseThrow(() -> new PlayerNotLinkedException(
                        "No linked player found for Discord ID: " + discordId));
        return PlayerStatsDto.fromProfile(profile);
    }
}
