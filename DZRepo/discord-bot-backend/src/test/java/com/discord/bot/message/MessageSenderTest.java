package com.discord.bot.message;

import java.util.function.Consumer;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.entities.Guild;
import net.dv8tion.jda.api.entities.Message;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.exceptions.InsufficientPermissionException;
import net.dv8tion.jda.api.requests.restaction.MessageCreateAction;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * Unit tests for MessageSender.
 * Validates: Requirements 5.1, 5.2, 5.4
 */
class MessageSenderTest {

    private MessageSender messageSender;
    private JDA jda;
    private TextChannel channel;
    private MessageCreateAction messageCreateAction;
    private Guild guild;

    @BeforeEach
    void setUp() {
        messageSender = new MessageSender();
        jda = mock(JDA.class);
        channel = mock(TextChannel.class);
        messageCreateAction = mock(MessageCreateAction.class);
        guild = mock(Guild.class);
        when(guild.getIdLong()).thenReturn(1L);
        when(guild.getName()).thenReturn("TestGuild");
    }

    // --- Successful send tests (Req 5.1, 5.4) ---

    @Test
    @SuppressWarnings("unchecked")
    void successfulSendQueuesMessageAndLogsChannelIdAndMessageId() {
        String channelId = "123456789";
        String content = "Hello, Discord!";

        when(jda.getTextChannelById(channelId)).thenReturn(channel);
        when(channel.sendMessage(content)).thenReturn(messageCreateAction);

        messageSender.send(jda, channelId, content);

        // Capture the success and failure consumers passed to queue()
        ArgumentCaptor<Consumer<Message>> successCaptor = ArgumentCaptor.forClass(Consumer.class);
        ArgumentCaptor<Consumer<Throwable>> failureCaptor = ArgumentCaptor.forClass(Consumer.class);
        verify(messageCreateAction).queue(successCaptor.capture(), failureCaptor.capture());

        // Invoke the success callback with a mock Message to trigger the log
        Message mockMessage = mock(Message.class);
        when(mockMessage.getId()).thenReturn("msg-001");
        successCaptor.getValue().accept(mockMessage);

        // Verify sendMessage was called with the correct content
        verify(channel).sendMessage(content);
    }

    @Test
    @SuppressWarnings("unchecked")
    void successfulSendWithMultipleChunksQueuesEachChunk() {
        String channelId = "123456789";
        // Create content that exceeds 2000 chars to trigger splitting
        String content = "A".repeat(3500);

        when(jda.getTextChannelById(channelId)).thenReturn(channel);
        when(channel.sendMessage(anyString())).thenReturn(messageCreateAction);

        messageSender.send(jda, channelId, content);

        // Should send 2 chunks: 2000 + 1500
        verify(channel, times(2)).sendMessage(anyString());
        verify(messageCreateAction, times(2)).queue(any(Consumer.class), any(Consumer.class));
    }

    // --- Non-existent channel tests (Req 5.2) ---

    @Test
    void nonExistentChannelLogsErrorAndDoesNotSend() {
        String channelId = "nonexistent-channel";
        String content = "Hello!";

        when(jda.getTextChannelById(channelId)).thenReturn(null);

        messageSender.send(jda, channelId, content);

        // No message should be sent since channel is null
        verify(jda).getTextChannelById(channelId);
        verifyNoInteractions(channel);
    }

    // --- Insufficient permissions tests (Req 5.2) ---

    @Test
    void insufficientPermissionsLogsErrorAndStopsSending() {
        String channelId = "123456789";
        String content = "Hello!";

        when(jda.getTextChannelById(channelId)).thenReturn(channel);
        // Use doThrow to avoid issues with InsufficientPermissionException constructor
        doThrow(new InsufficientPermissionException(guild, Permission.MESSAGE_SEND))
                .when(channel).sendMessage(content);

        messageSender.send(jda, channelId, content);

        // sendMessage was called but threw InsufficientPermissionException
        verify(channel).sendMessage(content);
        // queue() should never be reached since the exception is thrown before
        verify(messageCreateAction, never()).queue(any(), any());
    }

    @Test
    @SuppressWarnings("unchecked")
    void insufficientPermissionsOnSecondChunkStopsFurtherSending() {
        String channelId = "123456789";
        // Content that splits into 2 chunks
        String content = "A".repeat(3500);

        when(jda.getTextChannelById(channelId)).thenReturn(channel);

        // First chunk succeeds, second chunk throws
        String firstChunk = content.substring(0, 2000);
        String secondChunk = content.substring(2000);

        when(channel.sendMessage(firstChunk)).thenReturn(messageCreateAction);
        doThrow(new InsufficientPermissionException(guild, Permission.MESSAGE_SEND))
                .when(channel).sendMessage(secondChunk);

        messageSender.send(jda, channelId, content);

        // First chunk was queued, second chunk threw before queue
        verify(channel).sendMessage(firstChunk);
        verify(channel).sendMessage(secondChunk);
        verify(messageCreateAction, times(1)).queue(any(Consumer.class), any(Consumer.class));
    }

    // --- Empty/null content tests ---

    @Test
    void nullContentReturnsEarlyWithNoSendAttempt() {
        String channelId = "123456789";

        messageSender.send(jda, channelId, null);

        // Should not even try to look up the channel
        verify(jda, never()).getTextChannelById(anyString());
    }

    @Test
    void emptyContentReturnsEarlyWithNoSendAttempt() {
        String channelId = "123456789";

        messageSender.send(jda, channelId, "");

        verify(jda, never()).getTextChannelById(anyString());
    }

    @Test
    void blankContentReturnsEarlyWithNoSendAttempt() {
        String channelId = "123456789";

        messageSender.send(jda, channelId, "   ");

        verify(jda, never()).getTextChannelById(anyString());
    }

    // --- Failure callback test ---

    @Test
    @SuppressWarnings("unchecked")
    void failureCallbackLogsError() {
        String channelId = "123456789";
        String content = "Hello!";

        when(jda.getTextChannelById(channelId)).thenReturn(channel);
        when(channel.sendMessage(content)).thenReturn(messageCreateAction);

        messageSender.send(jda, channelId, content);

        // Capture the failure consumer and invoke it
        ArgumentCaptor<Consumer<Message>> successCaptor = ArgumentCaptor.forClass(Consumer.class);
        ArgumentCaptor<Consumer<Throwable>> failureCaptor = ArgumentCaptor.forClass(Consumer.class);
        verify(messageCreateAction).queue(successCaptor.capture(), failureCaptor.capture());

        // Invoke the failure callback to trigger error logging
        failureCaptor.getValue().accept(new RuntimeException("Network error"));

        // Verify the message was sent (queue was called)
        verify(channel).sendMessage(content);
    }
}
