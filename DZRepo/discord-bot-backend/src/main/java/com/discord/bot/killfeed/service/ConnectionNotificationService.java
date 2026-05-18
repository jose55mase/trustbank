package com.discord.bot.killfeed.service;

import com.discord.bot.BotInitializer;
import com.discord.bot.economy.service.PlayerLinkService;
import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import com.discord.bot.gamelogs.parser.GameLogParser;
import com.discord.bot.killfeed.model.NotificationConfig;
import com.discord.bot.killfeed.store.NotificationConfigStore;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class ConnectionNotificationService {

    private static final Logger log = LoggerFactory.getLogger(ConnectionNotificationService.class);

    private final NotificationConfigStore notificationConfigStore;
    private final PlayerLinkService playerLinkService;
    private final GameLogParser gameLogParser;
    private final BotInitializer botInitializer;

    // Track already-notified players per guild to avoid spam on each poll cycle
    private final ConcurrentHashMap<String, Set<String>> notifiedPlayers = new ConcurrentHashMap<>();

    public ConnectionNotificationService(NotificationConfigStore notificationConfigStore,
                                         PlayerLinkService playerLinkService,
                                         GameLogParser gameLogParser,
                                         @Lazy BotInitializer botInitializer) {
        this.notificationConfigStore = notificationConfigStore;
        this.playerLinkService = playerLinkService;
        this.gameLogParser = gameLogParser;
        this.botInitializer = botInitializer;
    }

    /**
     * Processes the log content for a guild, finds connection events,
     * and notifies unlinked players in the configured notification channel.
     *
     * @param guildId    the Discord guild ID
     * @param logContent the raw log content from the ADM file
     */
    public void processConnections(String guildId, String logContent) {
        NotificationConfig config = notificationConfigStore.getConfig(guildId).orElse(null);
        if (config == null) return;

        JDA jda = botInitializer.getJda();
        if (jda == null) return;

        TextChannel channel = jda.getTextChannelById(config.channelId());
        if (channel == null) {
            log.warn("[ConnectionNotification] Channel {} not found for guild {}", config.channelId(), guildId);
            return;
        }

        List<GameLogEvent> events = gameLogParser.parseAll(logContent);
        Set<String> alreadyNotified = notifiedPlayers.computeIfAbsent(guildId, k -> ConcurrentHashMap.newKeySet());

        for (GameLogEvent event : events) {
            if (event.category() != GameLogCategory.CONNECTION) continue;

            String playerName = event.playerName();
            if (playerName == null || playerName.isBlank()) continue;
            if (alreadyNotified.contains(playerName)) continue;

            boolean isLinked = playerLinkService.findByDayzName(playerName).isPresent();
            if (!isLinked) {
                alreadyNotified.add(playerName);
                sendUnlinkedEmbed(channel, playerName);
            }
        }
    }

    /**
     * Clears the notified players cache for a guild (e.g. when log resets).
     *
     * @param guildId the Discord guild ID
     */
    public void clearCache(String guildId) {
        notifiedPlayers.remove(guildId);
    }

    private void sendUnlinkedEmbed(TextChannel channel, String playerName) {
        EmbedBuilder embed = new EmbedBuilder()
                .setColor(Color.ORANGE)
                .setTitle("⚠️ Jugador no vinculado")
                .setDescription("El jugador **" + playerName + "** se ha conectado al servidor pero no está vinculado.")
                .addField("¿Cómo vincularte?", "Usa el comando `/vincular` en el bot para vincular tu cuenta de Discord con tu nombre de DayZ.", false)
                .addField("Nombre en DayZ", "`" + playerName + "`", true)
                .setFooter("Usa /vincular para registrarte");

        channel.sendMessageEmbeds(embed.build()).queue(
                msg -> log.info("[ConnectionNotification] Notified unlinked player '{}' in channel {}", playerName, channel.getId()),
                err -> log.error("[ConnectionNotification] Failed to send embed for '{}': {}", playerName, err.getMessage())
        );
    }
}
