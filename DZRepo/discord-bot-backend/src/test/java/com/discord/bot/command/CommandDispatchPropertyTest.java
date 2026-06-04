package com.discord.bot.command;

import java.util.ArrayList;
import java.util.List;

import net.dv8tion.jda.api.entities.User;
import net.dv8tion.jda.api.entities.channel.unions.MessageChannelUnion;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.requests.restaction.interactions.ReplyCallbackAction;
import net.jqwik.api.*;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

// Feature: discord-bot-backend, Property 3: Despacho correcto de comandos registrados
class CommandDispatchPropertyTest {

    /**
     * Property 3: For any registered slash command, when CommandHandler receives
     * an event with that command name, it SHALL route execution to the correct
     * handler and produce a response.
     *
     * Generates random alphanumeric command names, creates mock SlashCommand
     * implementations for each, builds a CommandHandler, dispatches events
     * with those names, and verifies the correct mock was called with execute(event).
     *
     * **Validates: Requirements 3.3, 4.1**
     */
    @Property(tries = 100)
    void registeredCommandIsDispatchedToCorrectHandler(
            @ForAll("registeredCommandNames") List<String> commandNames,
            @ForAll("targetIndex") int targetIndexSeed) {

        if (commandNames.isEmpty()) {
            return;
        }

        // Pick a target command to dispatch using modulo to stay in bounds
        int targetIndex = Math.abs(targetIndexSeed) % commandNames.size();
        String targetName = commandNames.get(targetIndex);

        // Create mock SlashCommand for each generated name
        List<SlashCommand> mockCommands = new ArrayList<>();
        for (String name : commandNames) {
            SlashCommand cmd = mock(SlashCommand.class);
            when(cmd.getName()).thenReturn(name);
            mockCommands.add(cmd);
        }

        // Build CommandHandler with all mock commands
        CommandHandler handler = new CommandHandler(mockCommands);

        // Create mock event returning the target command name
        SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);
        when(event.getName()).thenReturn(targetName);

        // Set up user and channel mocks required by dispatch()
        User user = mock(User.class);
        when(user.getId()).thenReturn("user123");
        when(event.getUser()).thenReturn(user);

        MessageChannelUnion channel = mock(MessageChannelUnion.class);
        when(channel.getId()).thenReturn("channel456");
        when(event.getChannel()).thenReturn(channel);

        // Set up reply chain in case the command's execute calls event.reply()
        ReplyCallbackAction replyAction = mock(ReplyCallbackAction.class);
        when(event.reply(anyString())).thenReturn(replyAction);
        when(replyAction.setEphemeral(true)).thenReturn(replyAction);

        // Dispatch the event
        handler.dispatch(event);

        // Verify the correct handler was invoked exactly once
        SlashCommand targetCommand = mockCommands.get(targetIndex);
        verify(targetCommand, times(1)).execute(event);

        // Verify no other command was invoked
        for (int i = 0; i < mockCommands.size(); i++) {
            if (i != targetIndex) {
                verify(mockCommands.get(i), never()).execute(any());
            }
        }
    }

    /**
     * Provides lists of 1-10 unique alphanumeric command names.
     * Command names are lowercase alphanumeric strings of 1-20 characters,
     * matching typical Discord slash command naming conventions.
     */
    @Provide
    Arbitrary<List<String>> registeredCommandNames() {
        Arbitrary<String> commandName = Arbitraries.strings()
                .alpha()
                .numeric()
                .ofMinLength(1)
                .ofMaxLength(20)
                .map(String::toLowerCase);

        return commandName.list()
                .ofMinSize(1)
                .ofMaxSize(10)
                .uniqueElements();
    }

    /**
     * Provides an arbitrary integer used to select which command to dispatch.
     */
    @Provide
    Arbitrary<Integer> targetIndex() {
        return Arbitraries.integers().between(0, Integer.MAX_VALUE - 1);
    }
}
