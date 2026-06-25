package com.discord.bot.economy.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * JPA entity representing the economy configuration for a Discord guild.
 * Stores configurable parameters such as coins per zombie kill,
 * the list of melee weapons (as CSV), and whether the economy system is enabled.
 */
@Entity
@Table(name = "economy_config")
public class EconomyConfig {

    /** Default number of Coins awarded per zombie kill with a melee weapon. */
    public static final int DEFAULT_COINS_PER_ZOMBIE_KILL = 10;

    /** Default CSV list of DayZ weapons classified as melee. */
    public static final String DEFAULT_MELEE_WEAPONS =
            "SledgeHammer,FirefighterAxe,Hatchet,CombatKnife,HuntingKnife,"
            + "Machete,BaseballBat,CricketBat,Crowbar,Pipe,Shovel,Pickaxe,Sword";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String guildId;

    @Column(nullable = false)
    private int coinsPerZombieKill;

    @Column(length = 2000)
    private String meleeWeapons;

    @Column(nullable = false)
    private boolean enabled;

    /** No-arg constructor required by JPA. */
    protected EconomyConfig() {
    }

    /**
     * Creates a new economy configuration for the given guild with default values.
     *
     * @param guildId the Discord guild (server) ID
     */
    public EconomyConfig(String guildId) {
        this.guildId = guildId;
        this.coinsPerZombieKill = DEFAULT_COINS_PER_ZOMBIE_KILL;
        this.meleeWeapons = DEFAULT_MELEE_WEAPONS;
        this.enabled = true;
    }

    // --- Getters and Setters ---

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getGuildId() {
        return guildId;
    }

    public void setGuildId(String guildId) {
        this.guildId = guildId;
    }

    public int getCoinsPerZombieKill() {
        return coinsPerZombieKill;
    }

    public void setCoinsPerZombieKill(int coinsPerZombieKill) {
        this.coinsPerZombieKill = coinsPerZombieKill;
    }

    public String getMeleeWeapons() {
        return meleeWeapons;
    }

    public void setMeleeWeapons(String meleeWeapons) {
        this.meleeWeapons = meleeWeapons;
    }

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }
}
