package com.discord.bot.command;

import java.util.Collection;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Registers slash commands with the Discord REST API on startup.
 * Each command is registered individually so that a failure for one
 * command does not prevent the remaining commands from being registered.
 */
@Component
public class CommandRegistry {

    private static final Logger log = LoggerFactory.getLogger(CommandRegistry.class);

    /**
     * Registers all provided slash commands with Discord via the JDA instance.
     * If a command provides custom {@link CommandData} (e.g., with subcommands or options),
     * that data is used directly. Otherwise, a simple command is created from the name
     * and description. Each command is upserted individually. On success, the command
     * name is logged at INFO level. On failure, the error is logged at ERROR level
     * and registration continues with the remaining commands.
     *
     * @param jda      the JDA instance connected to Discord
     * @param commands the collection of slash commands to register
     */
    public void registerCommands(JDA jda, Collection<SlashCommand> commands) {
        for (SlashCommand command : commands) {
            try {
                CommandData commandData = command.getCommandData();
                if (commandData != null) {
                    jda.upsertCommand(commandData)
                            .queue(
                                    success -> log.info("Registered command: {}", command.getName()),
                                    failure -> log.error("Failed to register command: {} - {}",
                                            command.getName(), failure.getMessage())
                            );
                } else {
                    jda.upsertCommand(command.getName(), command.getDescription())
                            .queue(
                                    success -> log.info("Registered command: {}", command.getName()),
                                    failure -> log.error("Failed to register command: {} - {}",
                                            command.getName(), failure.getMessage())
                            );
                }
            } catch (Exception e) {
                log.error("Failed to register command: {} - {}", command.getName(), e.getMessage());
            }
        }
    }
}
