package com.discord.bot.command;

import java.util.List;
import java.util.function.Consumer;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.requests.restaction.CommandCreateAction;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * Unit tests for CommandRegistry.
 * Validates: Requirements 6.1, 6.2, 6.3
 */
class CommandRegistryTest {

    private CommandRegistry registry;
    private JDA jda;
    private CommandCreateAction commandCreateAction;

    @BeforeEach
    void setUp() {
        registry = new CommandRegistry();
        jda = mock(JDA.class);
        commandCreateAction = mock(CommandCreateAction.class);
        when(jda.upsertCommand(anyString(), anyString())).thenReturn(commandCreateAction);
    }

    @Test
    void registerCommandsCallsUpsertForEachCommand() {
        SlashCommand ping = mockCommand("ping", "Responds with pong");
        SlashCommand status = mockCommand("status", "Shows bot status");

        registry.registerCommands(jda, List.of(ping, status));

        verify(jda).upsertCommand("ping", "Responds with pong");
        verify(jda).upsertCommand("status", "Shows bot status");
        verify(commandCreateAction, times(2)).queue(any(Consumer.class), any(Consumer.class));
    }

    @Test
    void registerCommandsHandlesEmptyCollection() {
        registry.registerCommands(jda, List.of());

        verify(jda, never()).upsertCommand(anyString(), anyString());
    }

    @Test
    void registerCommandsContinuesWhenUpsertThrowsException() {
        SlashCommand failing = mockCommand("fail", "Will fail");
        SlashCommand working = mockCommand("working", "Will work");

        when(jda.upsertCommand("fail", "Will fail")).thenThrow(new RuntimeException("API error"));

        registry.registerCommands(jda, List.of(failing, working));

        // The working command should still be registered despite the first one failing
        verify(jda).upsertCommand("working", "Will work");
        verify(commandCreateAction).queue(any(Consumer.class), any(Consumer.class));
    }

    @SuppressWarnings("unchecked")
    @Test
    void registerCommandsQueuesWithSuccessAndFailureCallbacks() {
        SlashCommand ping = mockCommand("ping", "Responds with pong");

        registry.registerCommands(jda, List.of(ping));

        ArgumentCaptor<Consumer<Object>> successCaptor = ArgumentCaptor.forClass(Consumer.class);
        ArgumentCaptor<Consumer<Throwable>> failureCaptor = ArgumentCaptor.forClass(Consumer.class);
        verify(commandCreateAction).queue(successCaptor.capture(), failureCaptor.capture());

        // Both callbacks should be non-null
        assertNotNull(successCaptor.getValue());
        assertNotNull(failureCaptor.getValue());
    }

    private SlashCommand mockCommand(String name, String description) {
        SlashCommand command = mock(SlashCommand.class);
        when(command.getName()).thenReturn(name);
        when(command.getDescription()).thenReturn(description);
        return command;
    }
}
