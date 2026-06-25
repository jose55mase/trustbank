package com.discord.bot.economy.dto;

import jakarta.validation.constraints.Positive;

import java.util.List;

/**
 * Request DTO for updating economy configuration parameters.
 *
 * <p>All fields are optional — only non-null fields will be applied
 * to the existing configuration.</p>
 *
 * @param coinsPerZombieKill number of Coins awarded per zombie melee kill (must be positive if provided)
 * @param meleeWeapons       list of weapon names classified as melee
 * @param enabled            whether the economy system is enabled
 */
public record EconomyConfigUpdateDto(
        @Positive Integer coinsPerZombieKill,
        List<String> meleeWeapons,
        Boolean enabled
) {
}
