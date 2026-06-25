package com.discord.bot.economy.dto;

import com.discord.bot.economy.model.EconomyConfig;

import java.util.Arrays;
import java.util.List;

/**
 * Response DTO representing the current economy configuration for a guild.
 *
 * <p>Used by the REST API ({@code GET /api/economy/config}) to expose
 * economy settings. The melee weapons list is returned as a
 * {@code List<String>} rather than the raw CSV stored in the entity.</p>
 *
 * @param coinsPerZombieKill number of Coins awarded per zombie melee kill
 * @param meleeWeapons       list of weapon names classified as melee
 * @param enabled            whether the economy system is currently enabled
 */
public record EconomyConfigDto(
        int coinsPerZombieKill,
        List<String> meleeWeapons,
        boolean enabled
) {

    /**
     * Creates an {@code EconomyConfigDto} from an {@link EconomyConfig} entity,
     * splitting the CSV melee-weapons string into a {@code List<String>}.
     *
     * @param config the JPA economy configuration entity
     * @return a new DTO populated from the entity
     */
    public static EconomyConfigDto fromConfig(EconomyConfig config) {
        List<String> weapons = config.getMeleeWeapons() == null || config.getMeleeWeapons().isBlank()
                ? List.of()
                : Arrays.stream(config.getMeleeWeapons().split(","))
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .toList();

        return new EconomyConfigDto(
                config.getCoinsPerZombieKill(),
                weapons,
                config.isEnabled()
        );
    }
}
