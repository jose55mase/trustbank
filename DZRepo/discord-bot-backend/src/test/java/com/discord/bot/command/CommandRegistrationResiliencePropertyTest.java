package com.discord.bot.command;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.function.Consumer;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.requests.restaction.CommandCreateAction;
import net.jqwik.api.*;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

// Feature: discord-bot-backend, Property 7: Registro parcial de comandos es resiliente
class CommandRegistrationResiliencePropertyTest {

    /**
     * Property 7: For any list of slash commands where an arbitrary subset fails
     * during registration, all commands that did not fail SHALL register successfully,
     * and each failed command SHALL generate an error log with its name and failure reason.
     *
     * Generates a list of 1-10 mock SlashCommands with unique names. Randomly selects
     * a subset to "fail" by making jda.upsertCommand(failName, failDesc) throw a
     * RuntimeException. Verifies that upsertCommand() was called for ALL commands
     * (both failing and non-failing), and that non-failing commands had queue() called
     * on their CommandCreateAction.
     *
     * **Validates: Requirements 6.3**
     */
    @Property(tries = 100)
    void partialCommandRegistrationIsResilient(
            @ForAll("commandNames") List<String> commandNames,
            @ForAll("failureIndices") Set<Integer> failureIndexSeeds) {

        if (commandNames.isEmpty()) {
            return;
        }

        // Determine which indices will fail (map seeds into valid range)
        Set<Integer> failingIndices = new HashSet<>();
        for (int seed : failureIndexSeeds) {
            failingIndices.add(Math.abs(seed) % commandNames.size());
        }

        // Create mock SlashCommands
        List<SlashCommand> commands = new ArrayList<>();
        for (String name : commandNames) {
            SlashCommand cmd = mock(SlashCommand.class);
            when(cmd.getName()).thenReturn(name);
            when(cmd.getDescription()).thenReturn("Description for " + name);
            commands.add(cmd);
        }

        // Set up JDA mock
        JDA jda = mock(JDA.class);
        CommandCreateAction successAction = mock(CommandCreateAction.class);

        // Default: upsertCommand returns a working CommandCreateAction
        when(jda.upsertCommand(anyString(), anyString())).thenReturn(successAction);

        // For failing commands: make upsertCommand throw RuntimeException
        for (int idx : failingIndices) {
            String failName = commandNames.get(idx);
            String failDesc = "Description for " + failName;
            when(jda.upsertCommand(failName, failDesc))
                    .thenThrow(new RuntimeException("Registration failed for " + failName));
        }

        // Execute registration
        CommandRegistry registry = new CommandRegistry();
        registry.registerCommands(jda, commands);

        // Verify: upsertCommand was called for ALL commands (failing and non-failing)
        for (int i = 0; i < commandNames.size(); i++) {
            String name = commandNames.get(i);
            String desc = "Description for " + name;
            verify(jda).upsertCommand(name, desc);
        }

        // Verify: non-failing commands had queue() called on their CommandCreateAction
        int expectedQueueCalls = commandNames.size() - failingIndices.size();
        verify(successAction, times(expectedQueueCalls))
                .queue(any(Consumer.class), any(Consumer.class));
    }

    /**
     * Provides lists of 1-10 unique alphanumeric command names.
     */
    @Provide
    Arbitrary<List<String>> commandNames() {
        Arbitrary<String> commandName = Arbitraries.strings()
                .alpha()
                .numeric()
                .ofMinLength(1)
                .ofMaxLength(20)
                .map(String::toLowerCase);

        return commandName.list()
                .ofMinSize(1)
                .ofMaxSize(10)
                .uniqueElements();
    }

    /**
     * Provides a set of 0-5 arbitrary integers used as seeds to determine
     * which commands will fail during registration.
     */
    @Provide
    Arbitrary<Set<Integer>> failureIndices() {
        return Arbitraries.integers()
                .between(0, Integer.MAX_VALUE - 1)
                .set()
                .ofMinSize(0)
                .ofMaxSize(5);
    }
}
