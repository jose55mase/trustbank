package com.discord.bot.killfeed.service;

import com.discord.bot.BotInitializer;
import com.discord.bot.killfeed.model.KillEvent;
import com.discord.bot.killfeed.model.KillFeedConfig;
import com.discord.bot.killfeed.model.LastProcessedState;
import com.discord.bot.killfeed.model.PollResult;
import com.discord.bot.killfeed.store.KillFeedConfigStore;
import com.discord.bot.nitrado.exception.NitradoAuthException;
import com.discord.bot.nitrado.exception.NitradoConnectionException;
import com.discord.bot.nitrado.exception.NitradoNotFoundException;
import com.discord.bot.nitrado.exception.NitradoServerException;
import com.discord.bot.nitrado.service.NitradoApiClient;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.entities.MessageEmbed;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.exceptions.InsufficientPermissionException;
import net.dv8tion.jda.api.requests.restaction.MessageCreateAction;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link KillFeedService}.
 * Validates: Requirements 2.1-2.6, 4.4, 4.5, 8.1, 8.2, 8.3, 8.4
 */
@ExtendWith(MockitoExtension.class)
class KillFeedServiceTest {

    @Mock
    private NitradoApiClient nitradoApiClient;

    @Mock
    private LogParser logParser;

    @Mock
    private KillFeedConfigStore configStore;

    @Mock
    private KillFeedEmbedBuilder embedBuilder;

    @Mock
    private BotInitializer botInitializer;

    @Mock
    private JDA jda;

    @Mock
    private TextChannel textChannel;

    @Mock
    private MessageCreateAction messageCreateAction;

    private KillFeedService killFeedService;

    private static final String GUILD_ID = "guild-123";
    private static final String CHANNEL_ID = "channel-456";
    private static final int SERVICE_ID = 99999;

    @BeforeEach
    void setUp() {
        killFeedService = new KillFeedService(
                nitradoApiClient, logParser, configStore, embedBuilder, botInitializer);
    }

    // --- Helper methods ---

    private KillFeedConfig createConfig(String guildId, String channelId, int serviceId) {
        return new KillFeedConfig(guildId, channelId, serviceId);
    }

    private KillEvent createKillEvent(String killer, String victim, String timestamp, int lineIndex) {
        return new KillEvent(killer, victim, "M4-A1", 150.0,
                100.0, 200.0, 300.0, 400.0, 500.0, 600.0,
                timestamp, lineIndex);
    }

    private void setupJdaAndChannel() {
        when(botInitializer.getJda()).thenReturn(jda);
        when(jda.getTextChannelById(CHANNEL_ID)).thenReturn(textChannel);
        when(textChannel.sendMessageEmbeds(any(MessageEmbed.class))).thenReturn(messageCreateAction);
    }

    // --- Test 1: Complete poll cycle with mocks ---

    @Test
    void pollAllConfigs_completeCycle_downloadsParseFiltersAndPublishes() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);
        when(configStore.getAllConfigs()).thenReturn(List.of(config));

        String logContent = "12:00:00 | Player \"Victim\" killed by Player \"Killer\" with M4";
        when(nitradoApiClient.getServerLogs(SERVICE_ID)).thenReturn(logContent);

        KillEvent event = createKillEvent("Killer", "Victim", "12:00:00", 0);
        when(logParser.parseKillEvents(logContent)).thenReturn(List.of(event));

        when(configStore.getLastProcessed(GUILD_ID)).thenReturn(Optional.empty());

        MessageEmbed embed = mock(MessageEmbed.class);
        when(embedBuilder.buildEmbed(event)).thenReturn(embed);

        setupJdaAndChannel();

        PollResult result = killFeedService.pollAllConfigs();

        assertEquals(1, result.configsProcessed());
        assertEquals(1, result.newEventsFound());
        assertEquals(1, result.embedsPublished());
        assertEquals(0, result.errors());

        verify(nitradoApiClient).getServerLogs(SERVICE_ID);
        verify(logParser).parseKillEvents(logContent);
        verify(embedBuilder).buildEmbed(event);
        verify(textChannel).sendMessageEmbeds(embed);
        verify(configStore).updateLastProcessed(eq(GUILD_ID), any(LastProcessedState.class));
    }

    // --- Test 2: Error isolation between configs ---

    @Test
    void pollAllConfigs_errorInOneConfig_doesNotAffectOthers() {
        KillFeedConfig config1 = createConfig("guild-1", CHANNEL_ID, 111);
        KillFeedConfig config2 = createConfig("guild-2", CHANNEL_ID, 222);
        when(configStore.getAllConfigs()).thenReturn(List.of(config1, config2));

        // Config 1 throws an unexpected exception
        when(nitradoApiClient.getServerLogs(111)).thenThrow(new RuntimeException("Unexpected error"));

        // Config 2 works normally
        String logContent = "13:00:00 | Player \"V\" killed by Player \"K\" with AK";
        when(nitradoApiClient.getServerLogs(222)).thenReturn(logContent);

        KillEvent event = createKillEvent("K", "V", "13:00:00", 0);
        when(logParser.parseKillEvents(logContent)).thenReturn(List.of(event));
        when(configStore.getLastProcessed("guild-2")).thenReturn(Optional.empty());

        MessageEmbed embed = mock(MessageEmbed.class);
        when(embedBuilder.buildEmbed(event)).thenReturn(embed);

        when(botInitializer.getJda()).thenReturn(jda);
        when(jda.getTextChannelById(CHANNEL_ID)).thenReturn(textChannel);
        when(textChannel.sendMessageEmbeds(any(MessageEmbed.class))).thenReturn(messageCreateAction);

        PollResult result = killFeedService.pollAllConfigs();

        assertEquals(2, result.configsProcessed());
        assertEquals(1, result.newEventsFound());
        assertEquals(1, result.embedsPublished());
        assertEquals(1, result.errors());
    }

    // --- Test 3: Empty log content is skipped without error ---

    @Test
    void processConfig_emptyLog_skipsWithoutError() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);
        when(nitradoApiClient.getServerLogs(SERVICE_ID)).thenReturn("");

        int published = killFeedService.processConfig(config);

        assertEquals(0, published);
        verifyNoInteractions(logParser);
        verifyNoInteractions(embedBuilder);
    }

    @Test
    void processConfig_nullLog_skipsWithoutError() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);
        when(nitradoApiClient.getServerLogs(SERVICE_ID)).thenReturn(null);

        int published = killFeedService.processConfig(config);

        assertEquals(0, published);
        verifyNoInteractions(logParser);
    }

    @Test
    void processConfig_blankLog_skipsWithoutError() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);
        when(nitradoApiClient.getServerLogs(SERVICE_ID)).thenReturn("   ");

        int published = killFeedService.processConfig(config);

        assertEquals(0, published);
        verifyNoInteractions(logParser);
    }

    // --- Test 4: Nitrado error handling ---

    @Test
    void processConfig_nitradoConnectionException_logsWarnAndReturnsZero() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);
        when(nitradoApiClient.getServerLogs(SERVICE_ID))
                .thenThrow(new NitradoConnectionException("Connection refused", new RuntimeException()));

        int published = killFeedService.processConfig(config);

        assertEquals(0, published);
        verifyNoInteractions(logParser);
    }

    @Test
    void processConfig_nitradoAuthException_logsErrorAndReturnsZero() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);
        when(nitradoApiClient.getServerLogs(SERVICE_ID))
                .thenThrow(new NitradoAuthException("Invalid token"));

        int published = killFeedService.processConfig(config);

        assertEquals(0, published);
        verifyNoInteractions(logParser);
    }

    @Test
    void processConfig_nitradoServerException_logsErrorAndReturnsZero() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);
        when(nitradoApiClient.getServerLogs(SERVICE_ID))
                .thenThrow(new NitradoServerException("Internal server error", 500));

        int published = killFeedService.processConfig(config);

        assertEquals(0, published);
        verifyNoInteractions(logParser);
    }

    @Test
    void processConfig_nitradoNotFoundException_logsWarnAndReturnsZero() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);
        when(nitradoApiClient.getServerLogs(SERVICE_ID))
                .thenThrow(new NitradoNotFoundException("Log file not found"));

        int published = killFeedService.processConfig(config);

        assertEquals(0, published);
        verifyNoInteractions(logParser);
    }

    // --- Test 5: Channel not found ---

    @Test
    void processConfig_channelNotFound_logsErrorAndReturnsZero() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);

        String logContent = "14:00:00 | kill line";
        when(nitradoApiClient.getServerLogs(SERVICE_ID)).thenReturn(logContent);

        KillEvent event = createKillEvent("K", "V", "14:00:00", 0);
        when(logParser.parseKillEvents(logContent)).thenReturn(List.of(event));
        when(configStore.getLastProcessed(GUILD_ID)).thenReturn(Optional.empty());

        when(botInitializer.getJda()).thenReturn(jda);
        when(jda.getTextChannelById(CHANNEL_ID)).thenReturn(null);

        int published = killFeedService.processConfig(config);

        assertEquals(0, published);
        verifyNoInteractions(embedBuilder);
    }

    // --- Test 6: JDA not initialized ---

    @Test
    void processConfig_jdaNotInitialized_returnsZero() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);

        String logContent = "14:00:00 | kill line";
        when(nitradoApiClient.getServerLogs(SERVICE_ID)).thenReturn(logContent);

        KillEvent event = createKillEvent("K", "V", "14:00:00", 0);
        when(logParser.parseKillEvents(logContent)).thenReturn(List.of(event));
        when(configStore.getLastProcessed(GUILD_ID)).thenReturn(Optional.empty());

        when(botInitializer.getJda()).thenReturn(null);

        int published = killFeedService.processConfig(config);

        assertEquals(0, published);
    }

    // --- Test 7: Insufficient permissions ---

    @Test
    void processConfig_insufficientPermissions_logsErrorAndStopsSending() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);

        // Create all mocks upfront before any when() calls
        MessageEmbed embed = mock(MessageEmbed.class);
        net.dv8tion.jda.api.entities.Guild guild = mock(net.dv8tion.jda.api.entities.Guild.class);
        InsufficientPermissionException permException =
                new InsufficientPermissionException(guild, net.dv8tion.jda.api.Permission.MESSAGE_SEND);

        String logContent = "15:00:00 | kill line";
        when(nitradoApiClient.getServerLogs(SERVICE_ID)).thenReturn(logContent);

        KillEvent event1 = createKillEvent("K1", "V1", "15:00:00", 0);
        when(logParser.parseKillEvents(logContent)).thenReturn(List.of(event1));
        when(configStore.getLastProcessed(GUILD_ID)).thenReturn(Optional.empty());
        when(embedBuilder.buildEmbed(event1)).thenReturn(embed);
        when(botInitializer.getJda()).thenReturn(jda);
        when(jda.getTextChannelById(CHANNEL_ID)).thenReturn(textChannel);
        when(textChannel.sendMessageEmbeds(any(MessageEmbed.class))).thenThrow(permException);

        int published = killFeedService.processConfig(config);

        assertEquals(0, published);
    }

    // --- Test 8: Multiple events published and last processed state updated ---

    @Test
    void processConfig_multipleEvents_publishesAllAndUpdatesLastProcessed() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);

        String logContent = "16:00:00 | kill1\n16:00:01 | kill2";
        when(nitradoApiClient.getServerLogs(SERVICE_ID)).thenReturn(logContent);

        KillEvent event1 = createKillEvent("K1", "V1", "16:00:00", 0);
        KillEvent event2 = createKillEvent("K2", "V2", "16:00:01", 1);
        when(logParser.parseKillEvents(logContent)).thenReturn(List.of(event1, event2));
        when(configStore.getLastProcessed(GUILD_ID)).thenReturn(Optional.empty());

        MessageEmbed embed1 = mock(MessageEmbed.class);
        MessageEmbed embed2 = mock(MessageEmbed.class);
        when(embedBuilder.buildEmbed(event1)).thenReturn(embed1);
        when(embedBuilder.buildEmbed(event2)).thenReturn(embed2);

        setupJdaAndChannel();

        int published = killFeedService.processConfig(config);

        assertEquals(2, published);
        verify(textChannel).sendMessageEmbeds(embed1);
        verify(textChannel).sendMessageEmbeds(embed2);

        // Verify last processed state is updated with the last event
        verify(configStore).updateLastProcessed(GUILD_ID,
                new LastProcessedState("16:00:01", 1));
    }

    // --- Test 9: No new events after filtering ---

    @Test
    void processConfig_noNewEventsAfterFiltering_publishesNothing() {
        KillFeedConfig config = createConfig(GUILD_ID, CHANNEL_ID, SERVICE_ID);

        String logContent = "10:00:00 | old kill";
        when(nitradoApiClient.getServerLogs(SERVICE_ID)).thenReturn(logContent);

        KillEvent oldEvent = createKillEvent("K", "V", "10:00:00", 0);
        when(logParser.parseKillEvents(logContent)).thenReturn(List.of(oldEvent));

        // Last processed state is at or after the event
        when(configStore.getLastProcessed(GUILD_ID))
                .thenReturn(Optional.of(new LastProcessedState("10:00:00", 0)));

        int published = killFeedService.processConfig(config);

        assertEquals(0, published);
        verifyNoInteractions(embedBuilder);
        verify(configStore, never()).updateLastProcessed(anyString(), any());
    }

    // --- Test 10: No configs returns empty result ---

    @Test
    void pollAllConfigs_noConfigs_returnsEmptyResult() {
        when(configStore.getAllConfigs()).thenReturn(List.of());

        PollResult result = killFeedService.pollAllConfigs();

        assertEquals(0, result.configsProcessed());
        assertEquals(0, result.newEventsFound());
        assertEquals(0, result.embedsPublished());
        assertEquals(0, result.errors());
    }
}
