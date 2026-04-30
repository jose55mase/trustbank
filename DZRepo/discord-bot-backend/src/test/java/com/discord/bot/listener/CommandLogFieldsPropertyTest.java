package com.discord.bot.listener;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.discord.bot.command.CommandDispatchResult;
import com.discord.bot.command.CommandHandler;
import com.discord.bot.monitor.ErrorRateMonitor;
import net.dv8tion.jda.api.entities.User;
import net.dv8tion.jda.api.entities.channel.unions.MessageChannelUnion;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.jqwik.api.*;
import org.slf4j.LoggerFactory;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

// Feature: discord-bot-backend, Property 8: Logs de comandos contienen campos requeridos
class CommandLogFieldsPropertyTest {

    /**
     * Property 8: For any slash command event received, the generated log SHALL
     * contain the command name, the user ID, and the channel ID.
     *
     * Generates random alphanumeric strings for command names, user IDs, and channel IDs.
     * Creates a mock SlashCommandInteractionEvent with those values.
     * Uses a Logback ListAppender to capture log events programmatically.
     * Calls listener.onSlashCommandInteraction(event) and verifies the captured
     * log message contains all three fields.
     *
     * **Validates: Requirements 7.2**
     */
    @Property(tries = 100)
    void commandLogContainsAllRequiredFields(
            @ForAll("commandNames") String commandName,
            @ForAll("userIds") String userId,
            @ForAll("channelIds") String channelId) {

        // Set up Logback ListAppender to capture log events from DiscordEventListener
        Logger listenerLogger = (Logger) LoggerFactory.getLogger(DiscordEventListener.class);
        ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
        listAppender.start();
        listenerLogger.addAppender(listAppender);

        try {
            // Mock CommandHandler to avoid actual dispatch logic
            CommandHandler commandHandler = mock(CommandHandler.class);
            CommandDispatchResult mockResult = new CommandDispatchResult(commandName, userId, channelId, true, 5, null);
            when(commandHandler.dispatch(any())).thenReturn(mockResult);
            ErrorRateMonitor errorRateMonitor = mock(ErrorRateMonitor.class);
            DiscordEventListener listener = new DiscordEventListener(commandHandler, errorRateMonitor);

            // Create mock SlashCommandInteractionEvent with generated values
            SlashCommandInteractionEvent event = mock(SlashCommandInteractionEvent.class);
            User user = mock(User.class);
            MessageChannelUnion channel = mock(MessageChannelUnion.class);

            when(event.getName()).thenReturn(commandName);
            when(event.getUser()).thenReturn(user);
            when(user.getId()).thenReturn(userId);
            when(event.getChannel()).thenReturn(channel);
            when(channel.getId()).thenReturn(channelId);

            // Call the method under test
            listener.onSlashCommandInteraction(event);

            // Verify at least one log event was captured
            assertFalse(listAppender.list.isEmpty(),
                    "Expected at least one log event to be captured");

            // Find the log message that contains the slash command info
            String matchingLog = listAppender.list.stream()
                    .map(ILoggingEvent::getFormattedMessage)
                    .filter(msg -> msg.contains(commandName)
                            || msg.contains(userId)
                            || msg.contains(channelId))
                    .findFirst()
                    .orElse(null);

            assertNotNull(matchingLog,
                    "Expected a log message containing at least one of the fields");

            // Verify the log message contains ALL three required fields
            assertTrue(matchingLog.contains(commandName),
                    "Log message should contain command name '" + commandName
                            + "' but was: " + matchingLog);
            assertTrue(matchingLog.contains(userId),
                    "Log message should contain user ID '" + userId
                            + "' but was: " + matchingLog);
            assertTrue(matchingLog.contains(channelId),
                    "Log message should contain channel ID '" + channelId
                            + "' but was: " + matchingLog);
        } finally {
            // Clean up: remove the appender to avoid leaking between test runs
            listenerLogger.detachAppender(listAppender);
            listAppender.stop();
        }
    }

    /**
     * Provides random alphanumeric command names (3-20 chars).
     */
    @Provide
    Arbitrary<String> commandNames() {
        return Arbitraries.strings()
                .alpha()
                .numeric()
                .ofMinLength(3)
                .ofMaxLength(20);
    }

    /**
     * Provides random alphanumeric user IDs (5-20 chars), mimicking Discord snowflake IDs.
     */
    @Provide
    Arbitrary<String> userIds() {
        return Arbitraries.strings()
                .numeric()
                .ofMinLength(5)
                .ofMaxLength(20);
    }

    /**
     * Provides random alphanumeric channel IDs (5-20 chars), mimicking Discord snowflake IDs.
     */
    @Provide
    Arbitrary<String> channelIds() {
        return Arbitraries.strings()
                .numeric()
                .ofMinLength(5)
                .ofMaxLength(20);
    }
}
