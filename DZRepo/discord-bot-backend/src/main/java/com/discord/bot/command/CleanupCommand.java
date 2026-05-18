package com.discord.bot.command;

import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.entities.Member;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.Command;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.commands.build.SubcommandData;
import net.dv8tion.jda.api.interactions.commands.OptionType;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Slash command {@code /cleanup} for managing registered Discord slash commands.
 *
 * <p>Subcommands:
 * <ul>
 *   <li>{@code list} — lists all commands currently registered in Discord</li>
 *   <li>{@code delete} — deletes a specific command by name</li>
 *   <li>{@code deleteall} — deletes ALL registered commands (use with caution)</li>
 * </ul>
 */
@Component
public class CleanupCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(CleanupCommand.class);

    @Override
    public String getName() {
        return "cleanup";
    }

    @Override
    public String getDescription() {
        return "Gestiona los comandos slash registrados en Discord";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addSubcommands(
                        new SubcommandData("list", "Lista todos los comandos registrados en Discord"),
                        new SubcommandData("delete", "Elimina un comando específico por nombre")
                                .addOption(OptionType.STRING, "name", "Nombre del comando a eliminar", true),
                        new SubcommandData("deleteall", "Elimina TODOS los comandos registrados en Discord")
                );
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        if (!checkAdminPermission(event)) return;

        String subcommand = event.getSubcommandName();
        if (subcommand == null) {
            event.reply("❌ Subcomando no reconocido.").setEphemeral(true).queue();
            return;
        }

        switch (subcommand) {
            case "list" -> handleList(event);
            case "delete" -> handleDelete(event);
            case "deleteall" -> handleDeleteAll(event);
            default -> event.reply("❌ Subcomando no reconocido: " + subcommand).setEphemeral(true).queue();
        }
    }

    private void handleList(SlashCommandInteractionEvent event) {
        event.deferReply().setEphemeral(true).queue();

        event.getJDA().retrieveCommands().queue(commands -> {
            if (commands.isEmpty()) {
                event.getHook().sendMessage("ℹ️ No hay comandos registrados en Discord.").queue();
                return;
            }

            String list = commands.stream()
                    .map(c -> "`/" + c.getName() + "` — " + c.getDescription() + " (id: `" + c.getId() + "`)")
                    .collect(Collectors.joining("\n"));

            event.getHook().sendMessage("📋 **Comandos registrados (" + commands.size() + "):**\n" + list).queue();
        }, error -> {
            log.error("Error retrieving commands: {}", error.getMessage());
            event.getHook().sendMessage("❌ Error al obtener los comandos: " + error.getMessage()).queue();
        });
    }

    private void handleDelete(SlashCommandInteractionEvent event) {
        String name = event.getOption("name").getAsString().toLowerCase();
        event.deferReply().setEphemeral(true).queue();

        event.getJDA().retrieveCommands().queue(commands -> {
            List<Command> matches = commands.stream()
                    .filter(c -> c.getName().equalsIgnoreCase(name))
                    .collect(Collectors.toList());

            if (matches.isEmpty()) {
                event.getHook().sendMessage("ℹ️ No se encontró ningún comando con el nombre `/" + name + "`.").queue();
                return;
            }

            for (Command cmd : matches) {
                event.getJDA().deleteCommandById(cmd.getId()).queue(
                        v -> {
                            log.info("Deleted command: /{}", cmd.getName());
                            event.getHook().sendMessage("✅ Comando `/" + cmd.getName() + "` eliminado correctamente.").queue();
                        },
                        error -> {
                            log.error("Error deleting command /{}: {}", cmd.getName(), error.getMessage());
                            event.getHook().sendMessage("❌ Error al eliminar `/" + cmd.getName() + "`: " + error.getMessage()).queue();
                        }
                );
            }
        }, error -> {
            log.error("Error retrieving commands: {}", error.getMessage());
            event.getHook().sendMessage("❌ Error al obtener los comandos: " + error.getMessage()).queue();
        });
    }

    private void handleDeleteAll(SlashCommandInteractionEvent event) {
        event.deferReply().setEphemeral(true).queue();

        event.getJDA().updateCommands().queue(
                v -> {
                    log.info("All global commands deleted");
                    event.getHook().sendMessage("✅ Todos los comandos han sido eliminados de Discord.").queue();
                },
                error -> {
                    log.error("Error deleting all commands: {}", error.getMessage());
                    event.getHook().sendMessage("❌ Error al eliminar los comandos: " + error.getMessage()).queue();
                }
        );
    }

    private boolean checkAdminPermission(SlashCommandInteractionEvent event) {
        Member member = event.getMember();
        if (member == null || !member.hasPermission(Permission.ADMINISTRATOR)) {
            event.reply("❌ Se requieren permisos de administrador.").setEphemeral(true).queue();
            return false;
        }
        return true;
    }
}
