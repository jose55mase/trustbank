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
 * Unit tests for StatusCommand.
 * Validates: Requirements 4.3
 */
class StatusCommandTest {

    private StatusCommand statusCommand;
    private SlashCommandInteractionEvent event;
    private JDA jda;
    private ReplyCallbackAction replyAction;

    @BeforeEach
    void setUp() {
        statusCommand = new StatusCommand();
        event = mock(SlashCommandInteractionEvent.class);
        jda = mock(JDA.class);
        replyAction = mock(ReplyCallbackAction.class);

        when(event.getJDA()).thenReturn(jda);
        when(event.reply(anyString())).thenReturn(replyAction);
    }

    @Test
    void nameReturnsStatus() {
        assertEquals("status", statusCommand.getName());
    }

    @Test
    void descriptionIsNotEmpty() {
        assertNotNull(statusCommand.getDescription());
        assertFalse(statusCommand.getDescription().isBlank());
    }

    @Test
    void executeRepliesWithUptimeAndConnectionStatus() {
        when(jda.getStatus()).thenReturn(JDA.Status.CONNECTED);

        statusCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        verify(replyAction).queue();

        String reply = captor.getValue();
        assertTrue(reply.contains("Uptime:"), "Reply should contain 'Uptime:'");
        assertTrue(reply.contains("Status:"), "Reply should contain 'Status:'");
        assertTrue(reply.contains("CONNECTED"), "Reply should contain the connection status");
    }

    @Test
    void executeShowsDisconnectedStatus() {
        when(jda.getStatus()).thenReturn(JDA.Status.DISCONNECTED);

        statusCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());

        String reply = captor.getValue();
        assertTrue(reply.contains("DISCONNECTED"));
    }

    @Test
    void executeCallsQueueOnReplyAction() {
        when(jda.getStatus()).thenReturn(JDA.Status.CONNECTED);

        statusCommand.execute(event);

        verify(replyAction).queue();
    }

    // --- Direct tests for formatUptime() ---

    @Test
    void formatUptimeZeroMilliseconds() {
        assertEquals("0s", StatusCommand.formatUptime(0));
    }

    @Test
    void formatUptimeSecondsOnly() {
        // 45 seconds = 45000 ms
        assertEquals("45s", StatusCommand.formatUptime(45_000));
    }

    @Test
    void formatUptimeMinutesAndSeconds() {
        // 5 minutes 30 seconds = 330000 ms
        assertEquals("5m 30s", StatusCommand.formatUptime(330_000));
    }

    @Test
    void formatUptimeHoursMinutesAndSeconds() {
        // 2 hours 15 minutes 30 seconds
        long ms = (2 * 3600 + 15 * 60 + 30) * 1000L;
        assertEquals("2h 15m 30s", StatusCommand.formatUptime(ms));
    }

    @Test
    void formatUptimeExactHour() {
        // 1 hour exactly
        assertEquals("1h 0m 0s", StatusCommand.formatUptime(3_600_000));
    }

    @Test
    void formatUptimeHoursAndSecondsNoMinutes() {
        // 1 hour 0 minutes 5 seconds
        long ms = (3600 + 5) * 1000L;
        assertEquals("1h 0m 5s", StatusCommand.formatUptime(ms));
    }

    @Test
    void formatUptimeLargeValue() {
        // 100 hours 59 minutes 59 seconds
        long ms = (100 * 3600 + 59 * 60 + 59) * 1000L;
        assertEquals("100h 59m 59s", StatusCommand.formatUptime(ms));
    }

    @Test
    void formatUptimeSubSecondRoundsDown() {
        // 999 ms should be 0s (integer division)
        assertEquals("0s", StatusCommand.formatUptime(999));
    }
}
