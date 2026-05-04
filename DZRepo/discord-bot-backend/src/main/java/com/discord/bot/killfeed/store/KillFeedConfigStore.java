package com.discord.bot.killfeed.store;

import com.discord.bot.killfeed.model.KillFeedConfig;
import com.discord.bot.killfeed.model.LastProcessedState;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory, thread-safe store for kill feed configurations and last-processed state.
 * <p>
 * Configurations are keyed by Discord guild ID. Each guild can have at most one
 * active kill feed configuration. The store also tracks the last processed event
 * per guild to prevent duplicate publishing across poll cycles.
 */
@Component
public class KillFeedConfigStore {

    private final ConcurrentHashMap<String, KillFeedConfig> configs = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, LastProcessedState> lastProcessed = new ConcurrentHashMap<>();

    /**
     * Saves or replaces the kill feed configuration for the given guild.
     *
     * @param config the configuration to store (keyed by its guildId)
     */
    public void saveConfig(KillFeedConfig config) {
        configs.put(config.guildId(), config);
    }

    /**
     * Retrieves the kill feed configuration for the given guild.
     *
     * @param guildId the Discord guild ID
     * @return an Optional containing the configuration, or empty if none exists
     */
    public Optional<KillFeedConfig> getConfig(String guildId) {
        return Optional.ofNullable(configs.get(guildId));
    }

    /**
     * Removes the kill feed configuration and last-processed state for the given guild.
     *
     * @param guildId the Discord guild ID
     */
    public void removeConfig(String guildId) {
        configs.remove(guildId);
        lastProcessed.remove(guildId);
    }

    /**
     * Returns all active kill feed configurations.
     *
     * @return an unmodifiable view of all stored configurations
     */
    public Collection<KillFeedConfig> getAllConfigs() {
        return configs.values();
    }

    /**
     * Retrieves the last processed event state for the given guild.
     *
     * @param guildId the Discord guild ID
     * @return an Optional containing the last processed state, or empty if none exists
     */
    public Optional<LastProcessedState> getLastProcessed(String guildId) {
        return Optional.ofNullable(lastProcessed.get(guildId));
    }

    /**
     * Updates the last processed event state for the given guild.
     *
     * @param guildId the Discord guild ID
     * @param state   the new last processed state
     */
    public void updateLastProcessed(String guildId, LastProcessedState state) {
        lastProcessed.put(guildId, state);
    }
}
