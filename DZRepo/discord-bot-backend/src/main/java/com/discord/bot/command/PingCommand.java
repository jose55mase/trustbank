package com.discord.bot.command;

import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import org.springframework.stereotype.Component;

/**
 * Slash command that responds with "pong" and the current gateway latency in milliseconds.
 */
@Component
public class PingCommand implements SlashCommand {

    @Override
    public String getName() {
        return "ping";
    }

    @Override
    public String getDescription() {
        return "Responds with pong and gateway latency";
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        long latency = event.getJDA().getGatewayPing();
        event.reply("pong - " + latency + "ms").queue();
    }
}
