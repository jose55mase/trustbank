package com.discord.bot.monitor;

import java.time.Duration;
import java.time.Instant;

import com.discord.bot.BotInitializer;
import com.discord.bot.command.CommandHandler;
import net.dv8tion.jda.api.JDA;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

/**
 * Spring Boot Actuator health indicator for the Discord bot.
 * Reports UP/DOWN based on JDA connection status and includes
 * details such as gateway ping, uptime, and registered commands.
 */
@Component
public class BotHealthIndicator implements HealthIndicator {

    private final BotInitializer botInitializer;
    private final CommandHandler commandHandler;

    public BotHealthIndicator(BotInitializer botInitializer, CommandHandler commandHandler) {
        this.botInitializer = botInitializer;
        this.commandHandler = commandHandler;
    }

    @Override
    public Health health() {
        JDA jda = botInitializer.getJda();

        if (jda == null || jda.getStatus() != JDA.Status.CONNECTED) {
            String connectionStatus = (jda != null) ? jda.getStatus().name() : "NOT_INITIALIZED";
            return Health.down()
                    .withDetail("discordConnection", connectionStatus)
                    .withDetail("gatewayPing", -1)
                    .withDetail("uptime", "N/A")
                    .withDetail("registeredCommands", getRegisteredCommandNames())
                    .build();
        }

        return Health.up()
                .withDetail("discordConnection", jda.getStatus().name())
                .withDetail("gatewayPing", jda.getGatewayPing())
                .withDetail("uptime", formatUptime())
                .withDetail("registeredCommands", getRegisteredCommandNames())
                .build();
    }

    private java.util.List<String> getRegisteredCommandNames() {
        return commandHandler.getRegisteredCommands().stream()
                .map(cmd -> cmd.getName())
                .sorted()
                .toList();
    }

    private String formatUptime() {
        Instant startTime = botInitializer.getStartTime();
        if (startTime == null) {
            return "N/A";
        }
        long uptimeMs = Duration.between(startTime, Instant.now()).toMillis();
        long totalSeconds = uptimeMs / 1000;
        long hours = totalSeconds / 3600;
        long minutes = (totalSeconds % 3600) / 60;
        long seconds = totalSeconds % 60;

        StringBuilder sb = new StringBuilder();
        if (hours > 0) {
            sb.append(hours).append("h ");
        }
        if (minutes > 0 || hours > 0) {
            sb.append(minutes).append("m ");
        }
        sb.append(seconds).append("s");
        return sb.toString();
    }
}
