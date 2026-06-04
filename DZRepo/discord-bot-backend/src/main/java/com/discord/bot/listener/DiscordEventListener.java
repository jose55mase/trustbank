package com.discord.bot.listener;

import com.discord.bot.command.CommandDispatchResult;
import com.discord.bot.command.CommandHandler;
import com.discord.bot.monitor.ErrorRateMonitor;
import net.dv8tion.jda.api.events.GenericEvent;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.events.message.MessageReceivedEvent;
import net.dv8tion.jda.api.hooks.ListenerAdapter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Receives events from the Discord Gateway and dispatches them
 * to the appropriate handlers.
 */
@Component
public class DiscordEventListener extends ListenerAdapter {

    private static final Logger log = LoggerFactory.getLogger(DiscordEventListener.class);

    private final CommandHandler commandHandler;
    private final ErrorRateMonitor errorRateMonitor;

    public DiscordEventListener(CommandHandler commandHandler, ErrorRateMonitor errorRateMonitor) {
        this.commandHandler = commandHandler;
        this.errorRateMonitor = errorRateMonitor;
    }

    /**
     * Handles incoming slash command interactions.
     * Logs command name, user ID, and channel ID, then dispatches to CommandHandler.
     * Records errors via ErrorRateMonitor if dispatch fails.
     */
    @Override
    public void onSlashCommandInteraction(SlashCommandInteractionEvent event) {
        String commandName = event.getName();
        String userId = event.getUser().getId();
        String channelId = event.getChannel().getId();

        log.info("Slash command received: command={}, user={}, channel={}", commandName, userId, channelId);

        try {
            CommandDispatchResult result = commandHandler.dispatch(event);
            if (!result.success()) {
                errorRateMonitor.recordError();
            }
            log.info("Command dispatch result: command={}, success={}, executionTimeMs={}",
                    result.commandName(), result.success(), result.executionTimeMs());
        } catch (Exception e) {
            log.error("Error processing slash command: command={}, user={}, channel={}", commandName, userId, channelId, e);
            errorRateMonitor.recordError();
        }
    }

    /**
     * Handles incoming message events.
     * Logs at DEBUG level for basic message tracking.
     */
    @Override
    public void onMessageReceived(MessageReceivedEvent event) {
        log.debug("Message received: user={}, channel={}", event.getAuthor().getId(), event.getChannel().getId());
    }

    /**
     * Catches all other events not handled by specific overrides.
     * Logs unrecognized event types as WARN.
     */
    @Override
    public void onGenericEvent(GenericEvent event) {
        if (event instanceof SlashCommandInteractionEvent || event instanceof MessageReceivedEvent) {
            return;
        }
        log.warn("Unrecognized event type: {}", event.getClass().getSimpleName());
    }
}
