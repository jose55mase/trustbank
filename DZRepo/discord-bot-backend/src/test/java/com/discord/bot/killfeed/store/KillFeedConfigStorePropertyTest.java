package com.discord.bot.killfeed.store;

import com.discord.bot.killfeed.model.KillFeedConfig;
import net.jqwik.api.*;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Property-based tests for {@link KillFeedConfigStore}.
 *
 * Feature: kill-feed-discord
 *
 * Property 4: For any pair of configs with the same guildId, saving both results
 * in the second being stored.
 * **Validates: Requirements 1.2, 1.4**
 *
 * Property 5: For any stored config, removing it by guildId returns empty.
 * **Validates: Requirements 1.5**
 */
class KillFeedConfigStorePropertyTest {

    /**
     * Property 4: For any pair of configs with the same guildId but different
     * channelId and serviceId, saving both sequentially results in the second
     * configuration being the one stored.
     *
     * **Validates: Requirements 1.2, 1.4**
     */
    @Property(tries = 100)
    void saveConfig_withSameGuildId_secondOverwritesFirst(
            @ForAll("guildIds") String guildId,
            @ForAll("channelIds") String channelId1,
            @ForAll("channelIds") String channelId2,
            @ForAll("serviceIds") int serviceId1,
            @ForAll("serviceIds") int serviceId2) {

        KillFeedConfigStore store = new KillFeedConfigStore();

        KillFeedConfig first = new KillFeedConfig(guildId, channelId1, serviceId1);
        KillFeedConfig second = new KillFeedConfig(guildId, channelId2, serviceId2);

        store.saveConfig(first);
        store.saveConfig(second);

        Optional<KillFeedConfig> result = store.getConfig(guildId);
        assertTrue(result.isPresent(), "Config should exist after saving");
        assertEquals(second, result.get(), "Second config should overwrite the first");
    }

    /**
     * Property 5: For any stored config, removing it by guildId causes a subsequent
     * getConfig to return empty.
     *
     * **Validates: Requirements 1.5**
     */
    @Property(tries = 100)
    void removeConfig_afterSave_getConfigReturnsEmpty(
            @ForAll("guildIds") String guildId,
            @ForAll("channelIds") String channelId,
            @ForAll("serviceIds") int serviceId) {

        KillFeedConfigStore store = new KillFeedConfigStore();

        KillFeedConfig config = new KillFeedConfig(guildId, channelId, serviceId);
        store.saveConfig(config);

        // Verify it was stored
        assertTrue(store.getConfig(guildId).isPresent(), "Config should exist before removal");

        store.removeConfig(guildId);

        Optional<KillFeedConfig> result = store.getConfig(guildId);
        assertTrue(result.isEmpty(), "Config should be empty after removal");
    }

    @Provide
    Arbitrary<String> guildIds() {
        return Arbitraries.strings()
                .withCharRange('0', '9')
                .ofMinLength(17)
                .ofMaxLength(20);
    }

    @Provide
    Arbitrary<String> channelIds() {
        return Arbitraries.strings()
                .withCharRange('0', '9')
                .ofMinLength(17)
                .ofMaxLength(20);
    }

    @Provide
    Arbitrary<Integer> serviceIds() {
        return Arbitraries.integers().between(1, 999999);
    }
}
