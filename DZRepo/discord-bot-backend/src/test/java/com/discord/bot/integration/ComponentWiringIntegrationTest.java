package com.discord.bot.integration;

import java.time.Instant;
import java.util.List;
import java.util.function.Consumer;

import com.discord.bot.BotInitializer;
import com.discord.bot.command.CommandDispatchResult;
import com.discord.bot.command.CommandHandler;
import com.discord.bot.command.PingCommand;
import com.discord.bot.command.SlashCommand;
import com.discord.bot.command.StatusCommand;
import com.discord.bot.message.MessageSender;
import com.discord.bot.monitor.BotHealthIndicator;
import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.entities.Message;
import net.dv8tion.jda.api.entities.User;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.entities.channel.unions.MessageChannelUnion;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.requests.restaction.MessageCreateAction;
import net.dv8tion.jda.api.requests.restaction.interactions.ReplyCallbackAction;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.Status;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * Integration tests for component wiring.
 * Manually wires real components together with mocked JDA dependencies
 * to verify end-to-end flows without connecting to Discord.
 *
 * Validates: Requirements 3.3, 4.1, 5.1, 7.3
 */
class ComponentWiringIntegrationTest {

    // --- Shared real components ---
    private PingCommand pingCommand;
    private StatusCommand statusCommand;
    private CommandHandler commandHandler;

    @BeforeEach
    void setUp() {
        pingCommand = new PingCommand();
        statusCommand = new StatusCommand();
        commandHandler = new CommandHandler(List.of(pingCommand, statusCommand));
    }

    // =========================================================================
    // Test 1: Command dispatch end-to-end flow with mocked JDA
    // =========================================================================
    @Nested
    @DisplayName("Command dispatch end-to-end")
    class CommandDispatchEndToEnd {

        @Test
        @DisplayName("Dispatching /ping through real CommandHandler with real PingCommand replies with pong content")
        void pingCommandDispatchEndToEnd() {
            // Arrange: mock the JDA event infrastructure
            SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);
            ReplyCallbackAction replyAction = mock(ReplyCallbackAction.class);
            JDA jda = mock(JDA.class);
            User user = mock(User.class);
            MessageChannelUnion channel = mock(MessageChannelUnion.class);

            when(event.getName()).thenReturn("ping");
            when(event.getJDA()).thenReturn(jda);
            when(jda.getGatewayPing()).thenReturn(42L);
            when(event.getUser()).thenReturn(user);
            when(user.getId()).thenReturn("user-001");
            when(event.getChannel()).thenReturn(channel);
            when(channel.getId()).thenReturn("channel-001");
            when(event.reply(anyString())).thenReturn(replyAction);

            // Act: dispatch through real CommandHandler → real PingCommand
            CommandDispatchResult result = commandHandler.dispatch(event);

            // Assert: verify the reply content contains "pong"
            ArgumentCaptor<String> replyCaptor = ArgumentCaptor.forClass(String.class);
            verify(event).reply(replyCaptor.capture());
            verify(replyAction).queue();

            String replyContent = replyCaptor.getValue();
            assertTrue(replyContent.contains("pong"), "Reply should contain 'pong', got: " + replyContent);
            assertTrue(replyContent.contains("42"), "Reply should contain gateway latency '42', got: " + replyContent);

            // Assert: CommandDispatchResult is success
            assertTrue(result.success());
            assertEquals("ping", result.commandName());
            assertEquals("user-001", result.userId());
            assertEquals("channel-001", result.channelId());
            assertNull(result.errorMessage());
            assertTrue(result.executionTimeMs() >= 0);
        }

        @Test
        @DisplayName("Dispatching /status through real CommandHandler with real StatusCommand replies with uptime and status")
        void statusCommandDispatchEndToEnd() {
            // Arrange
            SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);
            ReplyCallbackAction replyAction = mock(ReplyCallbackAction.class);
            JDA jda = mock(JDA.class);
            User user = mock(User.class);
            MessageChannelUnion channel = mock(MessageChannelUnion.class);

            when(event.getName()).thenReturn("status");
            when(event.getJDA()).thenReturn(jda);
            when(jda.getStatus()).thenReturn(JDA.Status.CONNECTED);
            when(event.getUser()).thenReturn(user);
            when(user.getId()).thenReturn("user-002");
            when(event.getChannel()).thenReturn(channel);
            when(channel.getId()).thenReturn("channel-002");
            when(event.reply(anyString())).thenReturn(replyAction);

            // Act
            CommandDispatchResult result = commandHandler.dispatch(event);

            // Assert
            ArgumentCaptor<String> replyCaptor = ArgumentCaptor.forClass(String.class);
            verify(event).reply(replyCaptor.capture());
            verify(replyAction).queue();

            String replyContent = replyCaptor.getValue();
            assertTrue(replyContent.contains("Uptime"), "Reply should contain 'Uptime', got: " + replyContent);
            assertTrue(replyContent.contains("CONNECTED"), "Reply should contain 'CONNECTED', got: " + replyContent);

            assertTrue(result.success());
            assertEquals("status", result.commandName());
        }

        @Test
        @DisplayName("Dispatching unrecognized command returns failure result with error message")
        void unrecognizedCommandDispatchEndToEnd() {
            // Arrange
            SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);
            ReplyCallbackAction replyAction = mock(ReplyCallbackAction.class);
            User user = mock(User.class);
            MessageChannelUnion channel = mock(MessageChannelUnion.class);

            when(event.getName()).thenReturn("unknown-cmd");
            when(event.getUser()).thenReturn(user);
            when(user.getId()).thenReturn("user-003");
            when(event.getChannel()).thenReturn(channel);
            when(channel.getId()).thenReturn("channel-003");
            when(event.reply(anyString())).thenReturn(replyAction);
            when(replyAction.setEphemeral(true)).thenReturn(replyAction);

            // Act
            CommandDispatchResult result = commandHandler.dispatch(event);

            // Assert
            ArgumentCaptor<String> replyCaptor = ArgumentCaptor.forClass(String.class);
            verify(event).reply(replyCaptor.capture());
            verify(replyAction).setEphemeral(true);
            verify(replyAction).queue();

            assertTrue(replyCaptor.getValue().contains("Comando no reconocido"));
            assertFalse(result.success());
            assertEquals("unknown-cmd", result.commandName());
            assertNotNull(result.errorMessage());
        }
    }

    // =========================================================================
    // Test 2: Message sending with mocked channels
    // =========================================================================
    @Nested
    @DisplayName("Message sending with mocked channels")
    class MessageSendingWithMockedChannels {

        private MessageSender messageSender;

        @BeforeEach
        void setUp() {
            messageSender = new MessageSender();
        }

        @Test
        @DisplayName("Sending a message through real MessageSender calls sendMessage on the mocked channel")
        @SuppressWarnings("unchecked")
        void sendMessageToMockedChannel() {
            // Arrange
            JDA jda = mock(JDA.class);
            TextChannel textChannel = mock(TextChannel.class);
            MessageCreateAction messageCreateAction = mock(MessageCreateAction.class);

            String channelId = "channel-100";
            String content = "Hello from integration test!";

            when(jda.getTextChannelById(channelId)).thenReturn(textChannel);
            when(textChannel.sendMessage(content)).thenReturn(messageCreateAction);

            // Act
            messageSender.send(jda, channelId, content);

            // Assert: channel.sendMessage() was called with the correct content
            verify(textChannel).sendMessage(content);
            verify(messageCreateAction).queue(any(Consumer.class), any(Consumer.class));
        }

        @Test
        @DisplayName("Sending a long message splits into multiple chunks and sends each")
        @SuppressWarnings("unchecked")
        void sendLongMessageSplitsIntoChunks() {
            // Arrange
            JDA jda = mock(JDA.class);
            TextChannel textChannel = mock(TextChannel.class);
            MessageCreateAction messageCreateAction = mock(MessageCreateAction.class);

            String channelId = "channel-200";
            String content = "X".repeat(4500); // Should split into 3 chunks: 2000 + 2000 + 500

            when(jda.getTextChannelById(channelId)).thenReturn(textChannel);
            when(textChannel.sendMessage(anyString())).thenReturn(messageCreateAction);

            // Act
            messageSender.send(jda, channelId, content);

            // Assert: sendMessage called 3 times for 3 chunks
            verify(textChannel, times(3)).sendMessage(anyString());
            verify(messageCreateAction, times(3)).queue(any(Consumer.class), any(Consumer.class));
        }

        @Test
        @DisplayName("Sending to a non-existent channel does not attempt to send a message")
        void sendToNonExistentChannel() {
            // Arrange
            JDA jda = mock(JDA.class);
            String channelId = "nonexistent-channel";

            when(jda.getTextChannelById(channelId)).thenReturn(null);

            // Act
            messageSender.send(jda, channelId, "Some content");

            // Assert: no message sending attempted
            verify(jda).getTextChannelById(channelId);
            // No TextChannel interactions should occur
        }
    }

    // =========================================================================
    // Test 3: Health endpoint returns expected structure
    // =========================================================================
    @Nested
    @DisplayName("Health endpoint structure")
    class HealthEndpointStructure {

        @Test
        @DisplayName("Health returns UP with all expected detail keys when JDA is CONNECTED")
        void healthReturnsUpWithAllExpectedDetails() {
            // Arrange: mock BotInitializer with a mock JDA in CONNECTED status
            BotInitializer botInitializer = mock(BotInitializer.class);
            JDA jda = mock(JDA.class);

            when(botInitializer.getJda()).thenReturn(jda);
            when(jda.getStatus()).thenReturn(JDA.Status.CONNECTED);
            when(jda.getGatewayPing()).thenReturn(55L);
            when(botInitializer.getStartTime()).thenReturn(Instant.now().minusSeconds(300));

            // Wire real CommandHandler (with real commands) and real BotHealthIndicator
            BotHealthIndicator healthIndicator = new BotHealthIndicator(botInitializer, commandHandler);

            // Act
            Health health = healthIndicator.health();

            // Assert: status is UP
            assertEquals(Status.UP, health.getStatus());

            // Assert: all expected detail keys are present
            assertTrue(health.getDetails().containsKey("discordConnection"),
                    "Health details should contain 'discordConnection'");
            assertTrue(health.getDetails().containsKey("gatewayPing"),
                    "Health details should contain 'gatewayPing'");
            assertTrue(health.getDetails().containsKey("uptime"),
                    "Health details should contain 'uptime'");
            assertTrue(health.getDetails().containsKey("registeredCommands"),
                    "Health details should contain 'registeredCommands'");

            // Assert: detail values are correct
            assertEquals("CONNECTED", health.getDetails().get("discordConnection"));
            assertEquals(55L, health.getDetails().get("gatewayPing"));

            String uptime = (String) health.getDetails().get("uptime");
            assertNotNull(uptime);
            assertNotEquals("N/A", uptime);

            @SuppressWarnings("unchecked")
            List<String> commands = (List<String>) health.getDetails().get("registeredCommands");
            assertNotNull(commands);
            assertEquals(2, commands.size());
            assertTrue(commands.contains("ping"));
            assertTrue(commands.contains("status"));
        }

        @Test
        @DisplayName("Health returns DOWN when JDA is not connected")
        void healthReturnsDownWhenDisconnected() {
            // Arrange
            BotInitializer botInitializer = mock(BotInitializer.class);
            JDA jda = mock(JDA.class);

            when(botInitializer.getJda()).thenReturn(jda);
            when(jda.getStatus()).thenReturn(JDA.Status.DISCONNECTED);

            BotHealthIndicator healthIndicator = new BotHealthIndicator(botInitializer, commandHandler);

            // Act
            Health health = healthIndicator.health();

            // Assert
            assertEquals(Status.DOWN, health.getStatus());
            assertEquals("DISCONNECTED", health.getDetails().get("discordConnection"));
            assertEquals(-1, health.getDetails().get("gatewayPing"));
            assertEquals("N/A", health.getDetails().get("uptime"));

            // registeredCommands should still be present even when DOWN
            assertTrue(health.getDetails().containsKey("registeredCommands"));
        }

        @Test
        @DisplayName("Health returns DOWN with NOT_INITIALIZED when JDA is null")
        void healthReturnsDownWhenJdaIsNull() {
            // Arrange
            BotInitializer botInitializer = mock(BotInitializer.class);
            when(botInitializer.getJda()).thenReturn(null);

            BotHealthIndicator healthIndicator = new BotHealthIndicator(botInitializer, commandHandler);

            // Act
            Health health = healthIndicator.health();

            // Assert
            assertEquals(Status.DOWN, health.getStatus());
            assertEquals("NOT_INITIALIZED", health.getDetails().get("discordConnection"));
            assertEquals(-1, health.getDetails().get("gatewayPing"));
            assertEquals("N/A", health.getDetails().get("uptime"));
            assertTrue(health.getDetails().containsKey("registeredCommands"));
        }
    }
}
