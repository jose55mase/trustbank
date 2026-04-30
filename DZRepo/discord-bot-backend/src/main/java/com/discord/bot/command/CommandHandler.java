package com.discord.bot.command;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Maintains a registry of slash commands and dispatches incoming events
 * to the correct command handler.
 */
@Component
public class CommandHandler {

    private static final Logger log = LoggerFactory.getLogger(CommandHandler.class);

    private final Map<String, SlashCommand> commands;

    /**
     * Constructs a CommandHandler with all available SlashCommand implementations.
     * Spring auto-injects all beans implementing SlashCommand.
     *
     * @param commandList list of all SlashCommand beans
     */
    public CommandHandler(List<SlashCommand> commandList) {
        this.commands = commandList.stream()
                .collect(Collectors.toMap(SlashCommand::getName, Function.identity()));
        log.info("CommandHandler initialized with {} commands: {}", commands.size(), commands.keySet());
    }

    /**
     * Dispatches a slash command interaction event to the appropriate command handler.
     * If the command is not recognized, replies with an ephemeral error message.
     * If execution throws an exception, replies with a generic error and logs the details.
     * Tracks execution time and returns a {@link CommandDispatchResult} for internal tracking.
     *
     * @param event the slash command interaction event
     * @return a CommandDispatchResult with execution metadata
     */
    public CommandDispatchResult dispatch(SlashCommandInteractionEvent event) {
        String commandName = event.getName();
        String userId = event.getUser().getId();
        String channelId = event.getChannel().getId();
        SlashCommand command = commands.get(commandName);

        if (command == null) {
            log.warn("Unrecognized command received: {}", commandName);
            event.reply("Comando no reconocido: " + commandName)
                    .setEphemeral(true)
                    .queue();
            return new CommandDispatchResult(commandName, userId, channelId, false, 0, "Comando no reconocido");
        }

        long startNanos = System.nanoTime();
        try {
            command.execute(event);
            long executionTimeMs = (System.nanoTime() - startNanos) / 1_000_000;
            return new CommandDispatchResult(commandName, userId, channelId, true, executionTimeMs, null);
        } catch (Exception e) {
            long executionTimeMs = (System.nanoTime() - startNanos) / 1_000_000;
            log.error("Error executing command '{}': {}", commandName, e.getMessage(), e);
            event.reply("Ha ocurrido un error al ejecutar el comando")
                    .setEphemeral(true)
                    .queue();
            return new CommandDispatchResult(commandName, userId, channelId, false, executionTimeMs, e.getMessage());
        }
    }

    /**
     * Returns all registered slash commands.
     *
     * @return collection of registered SlashCommand instances
     */
    public Collection<SlashCommand> getRegisteredCommands() {
        return commands.values();
    }
}
