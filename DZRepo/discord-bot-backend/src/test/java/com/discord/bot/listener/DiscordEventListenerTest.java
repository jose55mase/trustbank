package com.discord.bot.listener;

import com.discord.bot.command.CommandDispatchResult;
import com.discord.bot.command.CommandHandler;
import com.discord.bot.monitor.ErrorRateMonitor;
import net.dv8tion.jda.api.entities.User;
import net.dv8tion.jda.api.entities.channel.unions.MessageChannelUnion;
import net.dv8tion.jda.api.events.GenericEvent;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.events.message.MessageReceivedEvent;
import net.dv8tion.jda.api.events.session.ReadyEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DiscordEventListenerTest {

    @Mock
    private CommandHandler commandHandler;

    @Mock
    private ErrorRateMonitor errorRateMonitor;

    private DiscordEventListener listener;

    @BeforeEach
    void setUp() {
        listener = new DiscordEventListener(commandHandler, errorRateMonitor);
    }

    @Test
    void onSlashCommandInteraction_dispatchesToCommandHandler() {
        SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);
        User user = mock(User.class);
        MessageChannelUnion channel = mock(MessageChannelUnion.class);

        when(event.getName()).thenReturn("ping");
        when(event.getUser()).thenReturn(user);
        when(user.getId()).thenReturn("user123");
        when(event.getChannel()).thenReturn(channel);
        when(channel.getId()).thenReturn("channel456");

        CommandDispatchResult successResult = new CommandDispatchResult("ping", "user123", "channel456", true, 10, null);
        when(commandHandler.dispatch(event)).thenReturn(successResult);

        listener.onSlashCommandInteraction(event);

        verify(commandHandler).dispatch(event);
    }

    @Test
    void onMessageReceived_doesNotDispatchToCommandHandler() {
        MessageReceivedEvent event = mock(MessageReceivedEvent.class);
        User author = mock(User.class);
        MessageChannelUnion channel = mock(MessageChannelUnion.class);

        when(event.getAuthor()).thenReturn(author);
        when(author.getId()).thenReturn("user789");
        when(event.getChannel()).thenReturn(channel);
        when(channel.getId()).thenReturn("channel101");

        listener.onMessageReceived(event);

        verifyNoInteractions(commandHandler);
    }

    @Test
    void onGenericEvent_doesNotLogForSlashCommandEvents() {
        // SlashCommandInteractionEvent should be skipped in onGenericEvent
        SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);

        // Should not throw or cause issues — just returns early
        listener.onGenericEvent(event);

        verifyNoInteractions(commandHandler);
    }

    @Test
    void onGenericEvent_doesNotLogForMessageReceivedEvents() {
        // MessageReceivedEvent should be skipped in onGenericEvent
        MessageReceivedEvent event = mock(MessageReceivedEvent.class);

        listener.onGenericEvent(event);

        verifyNoInteractions(commandHandler);
    }

    @Test
    void onGenericEvent_handlesUnrecognizedEventTypes() {
        // A generic event that is not slash command or message should be logged as WARN
        GenericEvent event = mock(ReadyEvent.class);

        // Should not throw — just logs a warning
        listener.onGenericEvent(event);

        verifyNoInteractions(commandHandler);
    }

    @Test
    void onSlashCommandInteraction_recordsErrorWhenDispatchThrows() {
        SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);
        User user = mock(User.class);
        MessageChannelUnion channel = mock(MessageChannelUnion.class);

        when(event.getName()).thenReturn("failing-cmd");
        when(event.getUser()).thenReturn(user);
        when(user.getId()).thenReturn("user999");
        when(event.getChannel()).thenReturn(channel);
        when(channel.getId()).thenReturn("channel999");

        doThrow(new RuntimeException("dispatch failed")).when(commandHandler).dispatch(event);

        listener.onSlashCommandInteraction(event);

        verify(errorRateMonitor).recordError();
    }

    @Test
    void onSlashCommandInteraction_recordsErrorWhenDispatchReturnsFailure() {
        SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);
        User user = mock(User.class);
        MessageChannelUnion channel = mock(MessageChannelUnion.class);

        when(event.getName()).thenReturn("unknown");
        when(event.getUser()).thenReturn(user);
        when(user.getId()).thenReturn("user123");
        when(event.getChannel()).thenReturn(channel);
        when(channel.getId()).thenReturn("channel456");

        CommandDispatchResult failResult = new CommandDispatchResult("unknown", "user123", "channel456", false, 0, "Comando no reconocido");
        when(commandHandler.dispatch(event)).thenReturn(failResult);

        listener.onSlashCommandInteraction(event);

        verify(commandHandler).dispatch(event);
        verify(errorRateMonitor).recordError();
    }

    @Test
    void onSlashCommandInteraction_doesNotRecordErrorOnSuccess() {
        SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);
        User user = mock(User.class);
        MessageChannelUnion channel = mock(MessageChannelUnion.class);

        when(event.getName()).thenReturn("ping");
        when(event.getUser()).thenReturn(user);
        when(user.getId()).thenReturn("user123");
        when(event.getChannel()).thenReturn(channel);
        when(channel.getId()).thenReturn("channel456");

        CommandDispatchResult successResult = new CommandDispatchResult("ping", "user123", "channel456", true, 5, null);
        when(commandHandler.dispatch(event)).thenReturn(successResult);

        listener.onSlashCommandInteraction(event);

        verify(commandHandler).dispatch(event);
        verifyNoInteractions(errorRateMonitor);
    }
}
