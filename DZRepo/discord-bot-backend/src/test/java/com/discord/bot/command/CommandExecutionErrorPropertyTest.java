package com.discord.bot.command;

import java.util.List;

import net.dv8tion.jda.api.entities.User;
import net.dv8tion.jda.api.entities.channel.unions.MessageChannelUnion;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.requests.restaction.interactions.ReplyCallbackAction;
import net.jqwik.api.*;
import org.mockito.ArgumentCaptor;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

// Feature: discord-bot-backend, Property 5: Errores en ejecución de comandos producen respuesta genérica
class CommandExecutionErrorPropertyTest {

    private static final String GENERIC_ERROR_MESSAGE = "Ha ocurrido un error al ejecutar el comando";

    /**
     * Property 5: For any command whose execution throws an exception,
     * CommandHandler SHALL respond to the user with a generic error message
     * (without internal details) and log the detailed error (including stack trace).
     *
     * Generates random runtime exception types (RuntimeException, IllegalArgumentException,
     * NullPointerException, IllegalStateException, etc.) with random messages. Creates a mock
     * SlashCommand that throws the generated exception when execute() is called.
     * Builds a CommandHandler with that command, dispatches an event, and verifies:
     * - event.reply() is called with the generic error message
     * - The reply does NOT contain the exception message (no internal details leaked)
     * - setEphemeral(true) is called
     *
     * **Validates: Requirements 4.5**
     */
    @Property(tries = 100)
    void commandExecutionErrorProducesGenericResponse(
            @ForAll("randomExceptions") RuntimeException exception) {

        String commandName = "testcmd";

        // Create a mock SlashCommand that throws the generated exception
        SlashCommand failingCommand = mock(SlashCommand.class);
        when(failingCommand.getName()).thenReturn(commandName);
        doThrow(exception).when(failingCommand).execute(any());

        // Build CommandHandler with the failing command
        CommandHandler handler = new CommandHandler(List.of(failingCommand));

        // Create mock event
        SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);
        when(event.getName()).thenReturn(commandName);

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

        // Dispatch the event — should not throw
        handler.dispatch(event);

        // Verify event.reply() is called with the generic error message
        ArgumentCaptor<String> replyCaptor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(replyCaptor.capture());
        String replyMessage = replyCaptor.getValue();

        assertEquals(GENERIC_ERROR_MESSAGE, replyMessage,
                "Reply should be the generic error message");

        // Verify the reply does NOT contain the exception message (no internal details leaked).
        // We skip very short messages (<=3 chars) since they may coincidentally appear as
        // substrings of the generic Spanish error message (e.g., "a" appears in "al").
        // The assertEquals above already guarantees the reply is exactly the generic message.
        String exceptionMessage = exception.getMessage();
        if (exceptionMessage != null && exceptionMessage.length() > 3) {
            assertFalse(replyMessage.contains(exceptionMessage),
                    "Reply should NOT contain internal exception details: " + exceptionMessage);
        }

        // Verify setEphemeral(true) is called
        verify(replyAction).setEphemeral(true);

        // Verify queue() is called to send the reply
        verify(replyAction).queue();

        // Verify the command's execute() was actually called (the exception came from it)
        verify(failingCommand).execute(event);
    }

    /**
     * Provides random runtime exceptions of various types with random messages.
     * Uses only unchecked exceptions since SlashCommand.execute() does not declare
     * checked exceptions. Covers RuntimeException, IllegalArgumentException,
     * NullPointerException, IllegalStateException, UnsupportedOperationException,
     * and ArrayIndexOutOfBoundsException.
     */
    @Provide
    Arbitrary<RuntimeException> randomExceptions() {
        Arbitrary<String> messages = Arbitraries.strings()
                .alpha()
                .numeric()
                .ofMinLength(5)
                .ofMaxLength(100);

        return messages.flatMap(msg -> Arbitraries.of(
                new RuntimeException(msg),
                new IllegalArgumentException(msg),
                new NullPointerException(msg),
                new IllegalStateException(msg),
                new UnsupportedOperationException(msg),
                new ArrayIndexOutOfBoundsException(msg),
                new NumberFormatException(msg),
                new ClassCastException(msg)
        ));
    }
}
