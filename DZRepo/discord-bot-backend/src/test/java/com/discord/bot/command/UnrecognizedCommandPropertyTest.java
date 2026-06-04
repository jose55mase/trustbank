package com.discord.bot.command;

import java.util.List;
import java.util.Set;

import net.dv8tion.jda.api.entities.User;
import net.dv8tion.jda.api.entities.channel.unions.MessageChannelUnion;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.requests.restaction.interactions.ReplyCallbackAction;
import net.jqwik.api.*;
import org.mockito.ArgumentCaptor;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

// Feature: discord-bot-backend, Property 4: Comandos no registrados son rechazados
class UnrecognizedCommandPropertyTest {

    private static final Set<String> REGISTERED_COMMANDS = Set.of("ping", "status");

    /**
     * Property 4: For any command name NOT in the registered set, CommandHandler
     * SHALL respond with a message indicating the command was not recognized.
     *
     * Generates random alphanumeric strings that are not "ping" or "status",
     * creates a CommandHandler with mock ping and status commands, dispatches
     * an event with the unrecognized name, and verifies:
     * - event.reply() is called with a message containing "Comando no reconocido"
     * - setEphemeral(true) is called
     * - No command's execute() is called
     *
     * **Validates: Requirements 4.4**
     */
    @Property(tries = 100)
    void unrecognizedCommandIsRejectedWithProperResponse(
            @ForAll("unrecognizedCommandNames") String unrecognizedName) {

        // Create mock registered commands (ping and status)
        SlashCommand pingCommand = mock(SlashCommand.class);
        when(pingCommand.getName()).thenReturn("ping");

        SlashCommand statusCommand = mock(SlashCommand.class);
        when(statusCommand.getName()).thenReturn("status");

        CommandHandler handler = new CommandHandler(List.of(pingCommand, statusCommand));

        // Create mock event with the unrecognized command name
        SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);
        when(event.getName()).thenReturn(unrecognizedName);

        // Set up user and channel mocks required by dispatch()
        User user = mock(User.class);
        when(user.getId()).thenReturn("user123");
        when(event.getUser()).thenReturn(user);

        MessageChannelUnion channel = mock(MessageChannelUnion.class);
        when(channel.getId()).thenReturn("channel456");
        when(event.getChannel()).thenReturn(channel);

        ReplyCallbackAction replyAction = mock(ReplyCallbackAction.class);
        when(event.reply(anyString())).thenReturn(replyAction);
        when(replyAction.setEphemeral(true)).thenReturn(replyAction);

        // Dispatch the event
        handler.dispatch(event);

        // Verify event.reply() is called with a message containing "Comando no reconocido"
        ArgumentCaptor<String> replyCaptor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(replyCaptor.capture());
        String replyMessage = replyCaptor.getValue();
        assertTrue(replyMessage.contains("Comando no reconocido"),
                "Reply should contain 'Comando no reconocido' but was: " + replyMessage);

        // Verify setEphemeral(true) is called
        verify(replyAction).setEphemeral(true);

        // Verify queue() is called to send the reply
        verify(replyAction).queue();

        // Verify no command's execute() is called
        verify(pingCommand, never()).execute(any());
        verify(statusCommand, never()).execute(any());
    }

    /**
     * Provides random alphanumeric strings that are guaranteed NOT to be
     * in the registered command set ("ping", "status").
     */
    @Provide
    Arbitrary<String> unrecognizedCommandNames() {
        return Arbitraries.strings()
                .alpha()
                .numeric()
                .ofMinLength(1)
                .ofMaxLength(30)
                .map(String::toLowerCase)
                .filter(name -> !REGISTERED_COMMANDS.contains(name));
    }
}
