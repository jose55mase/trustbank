package com.discord.bot.command;

import java.util.Collection;
import java.util.Collections;
import java.util.List;

import net.dv8tion.jda.api.entities.User;
import net.dv8tion.jda.api.entities.channel.unions.MessageChannelUnion;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.requests.restaction.interactions.ReplyCallbackAction;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * Unit tests for CommandHandler.
 * Validates: Requirements 3.3, 4.1, 4.4, 4.5
 */
class CommandHandlerTest {

    private SlashCommand pingCommand;
    private SlashCommand statusCommand;
    private CommandHandler handler;
    private SlashCommandInteractionEvent event;
    private ReplyCallbackAction replyAction;

    @BeforeEach
    void setUp() {
        pingCommand = mock(SlashCommand.class);
        when(pingCommand.getName()).thenReturn("ping");

        statusCommand = mock(SlashCommand.class);
        when(statusCommand.getName()).thenReturn("status");

        handler = new CommandHandler(List.of(pingCommand, statusCommand));

        event = mock(SlashCommandInteractionEvent.class);
        replyAction = mock(ReplyCallbackAction.class);
        when(event.reply(anyString())).thenReturn(replyAction);
        when(replyAction.setEphemeral(true)).thenReturn(replyAction);

        // Set up user and channel mocks required by dispatch()
        User user = mock(User.class);
        when(user.getId()).thenReturn("user123");
        when(event.getUser()).thenReturn(user);

        MessageChannelUnion channel = mock(MessageChannelUnion.class);
        when(channel.getId()).thenReturn("channel456");
        when(event.getChannel()).thenReturn(channel);
    }

    @Test
    void constructorBuildsMapFromCommandList() {
        Collection<SlashCommand> registered = handler.getRegisteredCommands();
        assertEquals(2, registered.size());
        assertTrue(registered.contains(pingCommand));
        assertTrue(registered.contains(statusCommand));
    }

    @Test
    void constructorHandlesEmptyList() {
        CommandHandler emptyHandler = new CommandHandler(Collections.emptyList());
        assertTrue(emptyHandler.getRegisteredCommands().isEmpty());
    }

    @Test
    void dispatchRoutesToCorrectCommand() {
        when(event.getName()).thenReturn("ping");

        CommandDispatchResult result = handler.dispatch(event);

        verify(pingCommand).execute(event);
        verify(statusCommand, never()).execute(any());
        assertTrue(result.success());
        assertEquals("ping", result.commandName());
        assertEquals("user123", result.userId());
        assertEquals("channel456", result.channelId());
        assertNull(result.errorMessage());
        assertTrue(result.executionTimeMs() >= 0);
    }

    @Test
    void dispatchRoutesToStatusCommand() {
        when(event.getName()).thenReturn("status");

        CommandDispatchResult result = handler.dispatch(event);

        verify(statusCommand).execute(event);
        verify(pingCommand, never()).execute(any());
        assertTrue(result.success());
        assertEquals("status", result.commandName());
    }

    @Test
    void dispatchRepliesWithUnrecognizedMessageForUnknownCommand() {
        when(event.getName()).thenReturn("unknown");

        CommandDispatchResult result = handler.dispatch(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        verify(replyAction).setEphemeral(true);
        verify(replyAction).queue();

        String reply = captor.getValue();
        assertTrue(reply.contains("Comando no reconocido"), "Reply should contain 'Comando no reconocido'");
        assertTrue(reply.contains("unknown"), "Reply should contain the command name");

        assertFalse(result.success());
        assertEquals("unknown", result.commandName());
        assertEquals("Comando no reconocido", result.errorMessage());
    }

    @Test
    void dispatchHandlesExceptionWithGenericErrorResponse() {
        when(event.getName()).thenReturn("ping");
        doThrow(new RuntimeException("Something went wrong"))
                .when(pingCommand).execute(event);

        CommandDispatchResult result = handler.dispatch(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        verify(replyAction).setEphemeral(true);
        verify(replyAction).queue();

        String reply = captor.getValue();
        assertEquals("Ha ocurrido un error al ejecutar el comando", reply);
        // Ensure internal error details are NOT exposed to the user
        assertFalse(reply.contains("Something went wrong"));

        assertFalse(result.success());
        assertEquals("ping", result.commandName());
        assertEquals("Something went wrong", result.errorMessage());
    }

    @Test
    void dispatchHandlesNullPointerException() {
        when(event.getName()).thenReturn("status");
        doThrow(new NullPointerException("null ref"))
                .when(statusCommand).execute(event);

        CommandDispatchResult result = handler.dispatch(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());

        assertEquals("Ha ocurrido un error al ejecutar el comando", captor.getValue());
        assertFalse(result.success());
        assertEquals("null ref", result.errorMessage());
    }

    @Test
    void dispatchDoesNotExecuteAnyCommandForUnrecognized() {
        when(event.getName()).thenReturn("nonexistent");

        handler.dispatch(event);

        verify(pingCommand, never()).execute(any());
        verify(statusCommand, never()).execute(any());
    }

    @Test
    void getRegisteredCommandsReturnsAllCommands() {
        Collection<SlashCommand> commands = handler.getRegisteredCommands();
        assertEquals(2, commands.size());
    }
}
