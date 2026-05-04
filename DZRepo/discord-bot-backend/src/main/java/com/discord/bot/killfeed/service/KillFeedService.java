package com.discord.bot.killfeed.service;

import com.discord.bot.BotInitializer;
import com.discord.bot.killfeed.model.KillEvent;
import com.discord.bot.killfeed.model.KillFeedConfig;
import com.discord.bot.killfeed.model.LastProcessedState;
import com.discord.bot.killfeed.model.PollResult;
import com.discord.bot.killfeed.store.KillFeedConfigStore;
import com.discord.bot.nitrado.exception.NitradoApiException;
import com.discord.bot.nitrado.exception.NitradoAuthException;
import com.discord.bot.nitrado.exception.NitradoConnectionException;
import com.discord.bot.nitrado.exception.NitradoNotFoundException;
import com.discord.bot.nitrado.exception.NitradoServerException;
import com.discord.bot.nitrado.service.NitradoApiClient;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.entities.MessageEmbed;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.exceptions.InsufficientPermissionException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.List;

/**
 * Orchestration service for the kill feed system.
 *
 * <p>Polls all active configurations, downloads server logs from Nitrado,
 * parses kill events, filters duplicates, and publishes embeds to Discord channels.</p>
 */
@Service
public class KillFeedService {

    private static final Logger log = LoggerFactory.getLogger(KillFeedService.class);

    private final NitradoApiClient nitradoApiClient;
    private final LogParser logParser;
    private final KillFeedConfigStore configStore;
    private final KillFeedEmbedBuilder embedBuilder;
    private final BotInitializer botInitializer;

    public KillFeedService(NitradoApiClient nitradoApiClient,
                           LogParser logParser,
                           KillFeedConfigStore configStore,
                           KillFeedEmbedBuilder embedBuilder,
                           @Lazy BotInitializer botInitializer) {
        this.nitradoApiClient = nitradoApiClient;
        this.logParser = logParser;
        this.configStore = configStore;
        this.embedBuilder = embedBuilder;
        this.botInitializer = botInitializer;
    }

    /**
     * Processes all active kill feed configurations.
     *
     * <p>Each configuration is processed independently with error isolation:
     * a failure in one config does not affect the others.</p>
     *
     * @return a {@link PollResult} with metrics from the poll cycle
     */
    public PollResult pollAllConfigs() {
        Collection<KillFeedConfig> configs = configStore.getAllConfigs();

        int configsProcessed = 0;
        int totalNewEvents = 0;
        int totalEmbedsPublished = 0;
        int totalErrors = 0;

        for (KillFeedConfig config : configs) {
            configsProcessed++;
            try {
                int published = processConfig(config);
                totalEmbedsPublished += published;
                // Count new events as the number of embeds published for this config
                totalNewEvents += published;
            } catch (Exception e) {
                totalErrors++;
                log.error("Unexpected error processing config for guild {}: {}",
                        config.guildId(), e.getMessage(), e);
            }
        }

        return new PollResult(configsProcessed, totalNewEvents, totalEmbedsPublished, totalErrors);
    }

    /**
     * Processes a single kill feed configuration: downloads logs, parses events,
     * filters duplicates, and publishes embeds.
     *
     * @param config the kill feed configuration to process
     * @return the number of embeds successfully published
     */
    public int processConfig(KillFeedConfig config) {
        String logContent;
        try {
            logContent = nitradoApiClient.getServerLogs(config.serviceId());
        } catch (NitradoConnectionException e) {
            log.warn("Connection error downloading logs for guild {} (serviceId={}): {}",
                    config.guildId(), config.serviceId(), e.getMessage());
            return 0;
        } catch (NitradoAuthException e) {
            log.error("Authentication error downloading logs for guild {} (serviceId={}): {}",
                    config.guildId(), config.serviceId(), e.getMessage());
            return 0;
        } catch (NitradoServerException e) {
            log.error("Server error downloading logs for guild {} (serviceId={}): {}",
                    config.guildId(), config.serviceId(), e.getMessage());
            return 0;
        } catch (NitradoNotFoundException e) {
            log.warn("Log file not found for guild {} (serviceId={}): {}",
                    config.guildId(), config.serviceId(), e.getMessage());
            return 0;
        } catch (NitradoApiException e) {
            log.error("API error downloading logs for guild {} (serviceId={}): {}",
                    config.guildId(), config.serviceId(), e.getMessage());
            return 0;
        }

        // Empty log content → skip without error (Req 8.3)
        if (logContent == null || logContent.isBlank()) {
            return 0;
        }

        // Parse kill events from the log
        List<KillEvent> allEvents = logParser.parseKillEvents(logContent);

        // Filter duplicates using the last processed state
        LastProcessedState lastState = configStore.getLastProcessed(config.guildId()).orElse(null);
        List<KillEvent> newEvents = DuplicateFilter.filterNewEvents(allEvents, lastState);

        if (newEvents.isEmpty()) {
            return 0;
        }

        // Publish embeds to the configured Discord channel
        int published = sendEmbeds(config, newEvents);

        // Update last processed state with the last event
        if (!newEvents.isEmpty()) {
            KillEvent lastEvent = newEvents.get(newEvents.size() - 1);
            configStore.updateLastProcessed(config.guildId(),
                    new LastProcessedState(lastEvent.timestamp(), lastEvent.lineIndex()));
        }

        return published;
    }

    /**
     * Sends embeds for the given kill events to the configured Discord channel.
     *
     * @param config the kill feed configuration with the target channel
     * @param events the new kill events to publish
     * @return the number of embeds successfully sent
     */
    private int sendEmbeds(KillFeedConfig config, List<KillEvent> events) {
        JDA jda = botInitializer.getJda();
        if (jda == null) {
            log.error("JDA not initialized, cannot send embeds for guild {}", config.guildId());
            return 0;
        }

        TextChannel channel = jda.getTextChannelById(config.channelId());
        if (channel == null) {
            log.error("Channel {} not found for guild {}", config.channelId(), config.guildId());
            return 0;
        }

        int sent = 0;
        for (KillEvent event : events) {
            try {
                MessageEmbed embed = embedBuilder.buildEmbed(event);
                channel.sendMessageEmbeds(embed).queue();
                sent++;
            } catch (InsufficientPermissionException e) {
                log.error("Insufficient permissions to send embed in channel {} for guild {}: {}",
                        config.channelId(), config.guildId(), e.getMessage());
                return sent;
            } catch (Exception e) {
                log.error("Error sending embed to channel {} for guild {}: {}",
                        config.channelId(), config.guildId(), e.getMessage());
            }
        }

        return sent;
    }
}
