package com.discord.bot.command;

import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;

/**
 * Contract that all slash commands must implement.
 * Each command provides its name, description, and execution logic.
 */
public interface SlashCommand {

    /**
     * Returns the name of the slash command (e.g., "ping", "status").
     */
    String getName();

    /**
     * Returns a human-readable description of what the command does.
     */
    String getDescription();

    /**
     * Executes the command logic in response to a Discord slash command interaction.
     *
     * @param event the slash command interaction event from Discord
     */
    void execute(SlashCommandInteractionEvent event);
}
