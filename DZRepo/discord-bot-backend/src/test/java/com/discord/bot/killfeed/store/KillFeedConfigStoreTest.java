package com.discord.bot.killfeed.store;

import com.discord.bot.killfeed.model.KillFeedConfig;
import com.discord.bot.killfeed.model.LastProcessedState;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link KillFeedConfigStore}.
 * Covers edge cases: remove without existing config, getAllConfigs empty,
 * getConfig for non-existent guild, and lastProcessed operations.
 */
class KillFeedConfigStoreTest {

    private KillFeedConfigStore store;

    @BeforeEach
    void setUp() {
        store = new KillFeedConfigStore();
    }

    @Test
    void removeConfig_withoutExistingConfig_doesNotThrow() {
        assertDoesNotThrow(() -> store.removeConfig("non-existent-guild"));
    }

    @Test
    void getAllConfigs_whenEmpty_returnsEmptyCollection() {
        assertTrue(store.getAllConfigs().isEmpty());
    }

    @Test
    void getConfig_nonExistentGuild_returnsEmpty() {
        Optional<KillFeedConfig> result = store.getConfig("unknown-guild");
        assertTrue(result.isEmpty());
    }

    @Test
    void saveConfig_thenGetConfig_returnsStoredConfig() {
        KillFeedConfig config = new KillFeedConfig("guild-1", "channel-1", 12345);
        store.saveConfig(config);

        Optional<KillFeedConfig> result = store.getConfig("guild-1");
        assertTrue(result.isPresent());
        assertEquals(config, result.get());
    }

    @Test
    void removeConfig_afterSave_removesConfigAndLastProcessed() {
        KillFeedConfig config = new KillFeedConfig("guild-1", "channel-1", 12345);
        store.saveConfig(config);
        store.updateLastProcessed("guild-1", new LastProcessedState("12:00:00", 5));

        store.removeConfig("guild-1");

        assertTrue(store.getConfig("guild-1").isEmpty());
        assertTrue(store.getLastProcessed("guild-1").isEmpty());
    }

    @Test
    void getLastProcessed_nonExistentGuild_returnsEmpty() {
        assertTrue(store.getLastProcessed("unknown-guild").isEmpty());
    }

    @Test
    void updateLastProcessed_thenGetLastProcessed_returnsState() {
        LastProcessedState state = new LastProcessedState("14:30:00", 42);
        store.updateLastProcessed("guild-1", state);

        Optional<LastProcessedState> result = store.getLastProcessed("guild-1");
        assertTrue(result.isPresent());
        assertEquals(state, result.get());
    }

    @Test
    void getAllConfigs_withMultipleConfigs_returnsAll() {
        store.saveConfig(new KillFeedConfig("guild-1", "channel-1", 100));
        store.saveConfig(new KillFeedConfig("guild-2", "channel-2", 200));

        assertEquals(2, store.getAllConfigs().size());
    }
}
