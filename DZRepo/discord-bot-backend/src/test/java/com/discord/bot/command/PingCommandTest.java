package com.discord.bot.command;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.requests.restaction.interactions.ReplyCallbackAction;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * Unit tests for PingCommand.
 * Validates: Requirements 4.2
 */
class PingCommandTest {

    private PingCommand pingCommand;
    private SlashCommandInteractionEvent event;
    private JDA jda;
    private ReplyCallbackAction replyAction;

    @BeforeEach
    void setUp() {
        pingCommand = new PingCommand();
        event = mock(SlashCommandInteractionEvent.class);
        jda = mock(JDA.class);
        replyAction = mock(ReplyCallbackAction.class);

        when(event.getJDA()).thenReturn(jda);
        when(event.reply(anyString())).thenReturn(replyAction);
    }

    @Test
    void nameReturnsPing() {
        assertEquals("ping", pingCommand.getName());
    }

    @Test
    void descriptionIsNotEmpty() {
        assertNotNull(pingCommand.getDescription());
        assertFalse(pingCommand.getDescription().isBlank());
    }

    @Test
    void executeRepliesWithPongAndLatency() {
        when(jda.getGatewayPing()).thenReturn(42L);

        pingCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        verify(replyAction).queue();

        String reply = captor.getValue();
        assertTrue(reply.contains("pong"), "Reply should contain 'pong'");
        assertTrue(reply.contains("42"), "Reply should contain the latency value");
        assertTrue(reply.contains("ms"), "Reply should contain 'ms' unit");
    }

    @Test
    void executeRepliesWithZeroLatency() {
        when(jda.getGatewayPing()).thenReturn(0L);

        pingCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());

        String reply = captor.getValue();
        assertTrue(reply.contains("pong"));
        assertTrue(reply.contains("0"));
        assertTrue(reply.contains("ms"));
    }

    @Test
    void executeRepliesWithHighLatency() {
        when(jda.getGatewayPing()).thenReturn(999L);

        pingCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());

        String reply = captor.getValue();
        assertTrue(reply.contains("pong"));
        assertTrue(reply.contains("999"));
        assertTrue(reply.contains("ms"));
    }

    @Test
    void executeCallsQueueOnReplyAction() {
        when(jda.getGatewayPing()).thenReturn(50L);

        pingCommand.execute(event);

        verify(replyAction).queue();
    }
}
