package com.discord.bot.command;

import java.lang.management.ManagementFactory;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import org.springframework.stereotype.Component;

/**
 * Slash command that responds with the bot's uptime and JDA connection status.
 */
@Component
public class StatusCommand implements SlashCommand {

    @Override
    public String getName() {
        return "status";
    }

    @Override
    public String getDescription() {
        return "Shows bot uptime and connection status";
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String uptime = formatUptime(ManagementFactory.getRuntimeMXBean().getUptime());
        String connectionStatus = event.getJDA().getStatus().name();
        event.reply("Uptime: " + uptime + " | Status: " + connectionStatus).queue();
    }

    /**
     * Formats milliseconds into a human-readable string (e.g., "2h 15m 30s").
     *
     * @param uptimeMs uptime in milliseconds
     * @return formatted uptime string
     */
    static String formatUptime(long uptimeMs) {
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
