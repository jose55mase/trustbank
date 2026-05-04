package com.discord.bot.killfeed.command;

import com.discord.bot.BotInitializer;
import com.discord.bot.killfeed.model.KillEvent;
import com.discord.bot.killfeed.model.KillFeedConfig;
import com.discord.bot.killfeed.service.KillFeedEmbedBuilder;
import com.discord.bot.killfeed.store.KillFeedConfigStore;
import com.discord.bot.nitrado.dto.GameServerDto;
import com.discord.bot.nitrado.service.NitradoApiClient;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.entities.Guild;
import net.dv8tion.jda.api.entities.Member;
import net.dv8tion.jda.api.entities.MessageEmbed;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.entities.channel.unions.GuildChannelUnion;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.OptionMapping;
import net.dv8tion.jda.api.requests.restaction.MessageCreateAction;
import net.dv8tion.jda.api.requests.restaction.interactions.ReplyCallbackAction;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for KillFeedCommand.
 * Validates: Requirements 1.1-1.7, 7.1-7.5
 */
@ExtendWith(MockitoExtension.class)
class KillFeedCommandTest {

    @Mock private NitradoApiClient nitradoApiClient;
    @Mock private KillFeedConfigStore configStore;
    @Mock private KillFeedEmbedBuilder embedBuilder;
    @Mock private BotInitializer botInitializer;

    @Mock private SlashCommandInteractionEvent event;
    @Mock private Member member;
    @Mock private Guild guild;
    @Mock private ReplyCallbackAction replyAction;
    @Mock private OptionMapping channelOption;
    @Mock private OptionMapping serviceIdOption;
    @Mock private GuildChannelUnion channelUnion;
    @Mock private JDA jda;
    @Mock private TextChannel textChannel;
    @Mock private MessageCreateAction messageCreateAction;
    @Mock private MessageEmbed messageEmbed;

    private KillFeedCommand command;

    @BeforeEach
    void setUp() {
        command = new KillFeedCommand(nitradoApiClient, configStore, embedBuilder, botInitializer);
    }

    // --- Helper methods ---

    private void setupAdminMember() {
        when(event.getMember()).thenReturn(member);
        when(member.hasPermission(Permission.ADMINISTRATOR)).thenReturn(true);
    }

    private void setupNonAdminMember() {
        when(event.getMember()).thenReturn(member);
        when(member.hasPermission(Permission.ADMINISTRATOR)).thenReturn(false);
    }

    private void setupEphemeralReply() {
        when(event.reply(anyString())).thenReturn(replyAction);
        when(replyAction.setEphemeral(true)).thenReturn(replyAction);
    }

    private void setupNormalReply() {
        when(event.reply(anyString())).thenReturn(replyAction);
    }

    private void setupSetupOptions(String channelId, int serviceId) {
        when(event.getGuild()).thenReturn(guild);
        when(guild.getId()).thenReturn("guild123");
        when(event.getOption("channel")).thenReturn(channelOption);
        when(event.getOption("service_id")).thenReturn(serviceIdOption);
        when(channelOption.getAsChannel()).thenReturn(channelUnion);
        when(channelUnion.getId()).thenReturn(channelId);
        when(serviceIdOption.getAsInt()).thenReturn(serviceId);
    }

    private GameServerDto createServer(int id, String name) {
        return new GameServerDto(id, name, "1.2.3.4", 2302, "started", 10, 60, "chernarusplus", "1.25");
    }

    // --- Test 1: getName() returns "killfeed" ---

    @Test
    void getNameReturnsKillfeed() {
        assertEquals("killfeed", command.getName());
    }

    // --- Test 2: getDescription() is not empty ---

    @Test
    void getDescriptionIsNotEmpty() {
        assertNotNull(command.getDescription());
        assertFalse(command.getDescription().isBlank());
    }

    // --- Test 3: getCommandData() returns data with subcommands ---

    @Test
    void getCommandDataReturnsDataWithSubcommands() {
        var commandData = command.getCommandData();
        assertNotNull(commandData);
        assertEquals("killfeed", commandData.getName());
    }

    // --- Test 4: Successful setup (Req 1.2) ---

    @Test
    void setupSuccessful() {
        setupAdminMember();
        setupSetupOptions("channel456", 12345);
        setupNormalReply();

        when(event.getSubcommandName()).thenReturn("setup");
        when(nitradoApiClient.getServers()).thenReturn(List.of(createServer(12345, "Mi Servidor")));

        command.execute(event);

        ArgumentCaptor<KillFeedConfig> configCaptor = ArgumentCaptor.forClass(KillFeedConfig.class);
        verify(configStore).saveConfig(configCaptor.capture());

        KillFeedConfig savedConfig = configCaptor.getValue();
        assertEquals("guild123", savedConfig.guildId());
        assertEquals("channel456", savedConfig.channelId());
        assertEquals(12345, savedConfig.serviceId());

        ArgumentCaptor<String> replyCaptor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(replyCaptor.capture());
        assertTrue(replyCaptor.getValue().contains("✅"));
        assertTrue(replyCaptor.getValue().contains("channel456"));
        assertTrue(replyCaptor.getValue().contains("12345"));
    }

    // --- Test 5: Setup without admin permissions (Req 1.3) ---

    @Test
    void setupWithoutPermissions() {
        setupNonAdminMember();
        setupEphemeralReply();
        when(event.getSubcommandName()).thenReturn("setup");

        command.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        verify(replyAction).setEphemeral(true);
        assertTrue(captor.getValue().contains("permisos de administrador"));

        verifyNoInteractions(nitradoApiClient);
        verifyNoInteractions(configStore);
    }

    // --- Test 6: Setup with invalid serviceId (Req 1.7) ---

    @Test
    void setupWithInvalidServiceId() {
        setupAdminMember();
        setupSetupOptions("channel456", 99999);
        setupEphemeralReply();

        when(event.getSubcommandName()).thenReturn("setup");
        when(nitradoApiClient.getServers()).thenReturn(List.of(createServer(12345, "Mi Servidor")));

        command.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        verify(replyAction).setEphemeral(true);
        assertTrue(captor.getValue().contains("99999"));

        verify(configStore, never()).saveConfig(any());
    }

    // --- Test 7: Setup overwrites existing config (Req 1.4) ---

    @Test
    void setupOverwritesExistingConfig() {
        setupAdminMember();
        setupSetupOptions("newChannel789", 12345);
        setupNormalReply();

        when(event.getSubcommandName()).thenReturn("setup");
        when(nitradoApiClient.getServers()).thenReturn(List.of(createServer(12345, "Mi Servidor")));

        command.execute(event);

        ArgumentCaptor<KillFeedConfig> configCaptor = ArgumentCaptor.forClass(KillFeedConfig.class);
        verify(configStore).saveConfig(configCaptor.capture());

        KillFeedConfig savedConfig = configCaptor.getValue();
        assertEquals("guild123", savedConfig.guildId());
        assertEquals("newChannel789", savedConfig.channelId());
        assertEquals(12345, savedConfig.serviceId());
    }

    // --- Test 8: Successful remove (Req 1.5) ---

    @Test
    void removeSuccessful() {
        setupAdminMember();
        setupNormalReply();

        when(event.getSubcommandName()).thenReturn("remove");
        when(event.getGuild()).thenReturn(guild);
        when(guild.getId()).thenReturn("guild123");
        when(configStore.getConfig("guild123")).thenReturn(
                Optional.of(new KillFeedConfig("guild123", "channel456", 12345)));

        command.execute(event);

        verify(configStore).removeConfig("guild123");

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        assertTrue(captor.getValue().contains("✅"));
        assertTrue(captor.getValue().contains("eliminada"));
    }

    // --- Test 9: Remove without existing config (Req 1.6) ---

    @Test
    void removeWithoutConfig() {
        setupAdminMember();
        setupEphemeralReply();

        when(event.getSubcommandName()).thenReturn("remove");
        when(event.getGuild()).thenReturn(guild);
        when(guild.getId()).thenReturn("guild123");
        when(configStore.getConfig("guild123")).thenReturn(Optional.empty());

        command.execute(event);

        verify(configStore, never()).removeConfig(anyString());

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        verify(replyAction).setEphemeral(true);
        assertTrue(captor.getValue().contains("No hay configuración activa"));
    }

    // --- Test 10: Successful test (Req 7.2) ---

    @Test
    void testSuccessful() {
        setupAdminMember();
        setupNormalReply();

        when(event.getSubcommandName()).thenReturn("test");
        when(event.getGuild()).thenReturn(guild);
        when(guild.getId()).thenReturn("guild123");
        when(configStore.getConfig("guild123")).thenReturn(
                Optional.of(new KillFeedConfig("guild123", "channel456", 12345)));

        KillEvent dummyEvent = new KillEvent("SurvivorJoe", "BanditKing", "M4-A1",
                253.7, 7523.4, 2841.6, 312.1, 7310.2, 2790.8, 305.5, "12:00:00", 0);
        when(embedBuilder.createDummyEvent()).thenReturn(dummyEvent);
        when(embedBuilder.buildEmbed(dummyEvent)).thenReturn(messageEmbed);

        when(botInitializer.getJda()).thenReturn(jda);
        when(jda.getTextChannelById("channel456")).thenReturn(textChannel);
        when(textChannel.sendMessageEmbeds(messageEmbed)).thenReturn(messageCreateAction);

        command.execute(event);

        verify(textChannel).sendMessageEmbeds(messageEmbed);
        verify(messageCreateAction).queue();

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        assertTrue(captor.getValue().contains("✅"));
        assertTrue(captor.getValue().contains("channel456"));
    }

    // --- Test 11: Test without config (Req 7.3) ---

    @Test
    void testWithoutConfig() {
        setupAdminMember();
        setupEphemeralReply();

        when(event.getSubcommandName()).thenReturn("test");
        when(event.getGuild()).thenReturn(guild);
        when(guild.getId()).thenReturn("guild123");
        when(configStore.getConfig("guild123")).thenReturn(Optional.empty());

        command.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        verify(replyAction).setEphemeral(true);
        assertTrue(captor.getValue().contains("/killfeed setup"));

        verifyNoInteractions(embedBuilder);
    }

    // --- Test 12: Test without admin permissions (Req 7.4) ---

    @Test
    void testWithoutPermissions() {
        setupNonAdminMember();
        setupEphemeralReply();
        when(event.getSubcommandName()).thenReturn("test");

        command.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        verify(replyAction).setEphemeral(true);
        assertTrue(captor.getValue().contains("permisos de administrador"));

        verifyNoInteractions(configStore);
        verifyNoInteractions(embedBuilder);
    }
}
