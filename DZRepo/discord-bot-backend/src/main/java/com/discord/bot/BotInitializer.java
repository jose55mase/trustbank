package com.discord.bot;

import java.time.Instant;

import com.discord.bot.command.CommandHandler;
import com.discord.bot.command.CommandRegistry;
import com.discord.bot.config.BotConfigProperties;
import com.discord.bot.listener.DiscordEventListener;
import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.JDABuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

/**
 * Initializes the Discord bot on application startup.
 * Creates the JDA instance, registers the event listener, waits for the connection
 * to be ready, and triggers slash command registration.
 * Exposes the JDA instance and start time for health checks.
 */
@Component
public class BotInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(BotInitializer.class);

    private final BotConfigProperties config;
    private final DiscordEventListener eventListener;
    private final CommandHandler commandHandler;
    private final CommandRegistry commandRegistry;
    private final ApplicationContext applicationContext;

    private JDA jda;
    private Instant startTime;

    public BotInitializer(BotConfigProperties config,
                          DiscordEventListener eventListener,
                          CommandHandler commandHandler,
                          CommandRegistry commandRegistry,
                          ApplicationContext applicationContext) {
        this.config = config;
        this.eventListener = eventListener;
        this.commandHandler = commandHandler;
        this.commandRegistry = commandRegistry;
        this.applicationContext = applicationContext;
    }

    @Override
    public void run(ApplicationArguments args) {
        try {
            log.info("Initializing Discord bot...");

            jda = JDABuilder.createDefault(config.getToken())
                    .setAutoReconnect(true)
                    .addEventListeners(eventListener)
                    .build();

            jda.awaitReady();

            commandRegistry.registerCommands(jda, commandHandler.getRegisteredCommands());

            startTime = Instant.now();
            log.info("Discord bot initialized successfully. Connected as: {}",
                    jda.getSelfUser().getName());

        } catch (net.dv8tion.jda.api.exceptions.InvalidTokenException e) {
            log.error("Invalid bot token: {}", e.getMessage());
            shutdown();
        } catch (InterruptedException e) {
            log.error("Bot initialization interrupted: {}", e.getMessage());
            Thread.currentThread().interrupt();
            shutdown();
        } catch (Exception e) {
            log.error("Failed to initialize Discord bot: {}", e.getMessage(), e);
            shutdown();
        }
    }

    private void shutdown() {
        log.error("Shutting down application due to bot initialization failure");
        SpringApplication.exit(applicationContext, () -> 1);
    }

    /**
     * Returns the JDA instance for health checks and other components.
     *
     * @return the JDA instance, or null if not yet initialized
     */
    public JDA getJda() {
        return jda;
    }

    /**
     * Returns the time when the bot completed initialization.
     *
     * @return the start time, or null if not yet initialized
     */
    public Instant getStartTime() {
        return startTime;
    }
}
