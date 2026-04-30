package com.discord.bot.monitor;

import java.time.Instant;
import java.util.List;

import com.discord.bot.BotInitializer;
import com.discord.bot.command.CommandHandler;
import com.discord.bot.command.SlashCommand;
import net.dv8tion.jda.api.JDA;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.Status;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for BotHealthIndicator.
 * Validates: Requirements 7.3
 */
@ExtendWith(MockitoExtension.class)
class BotHealthIndicatorTest {

    @Mock
    private BotInitializer botInitializer;

    @Mock
    private CommandHandler commandHandler;

    @Mock
    private JDA jda;

    private BotHealthIndicator healthIndicator;

    @BeforeEach
    void setUp() {
        healthIndicator = new BotHealthIndicator(botInitializer, commandHandler);
        // Default: no registered commands
        when(commandHandler.getRegisteredCommands()).thenReturn(List.of());
    }

    @Test
    void jdaIsNullReturnsDownWithNotInitialized() {
        when(botInitializer.getJda()).thenReturn(null);

        Health health = healthIndicator.health();

        assertEquals(Status.DOWN, health.getStatus());
        assertEquals("NOT_INITIALIZED", health.getDetails().get("discordConnection"));
        assertEquals(-1, health.getDetails().get("gatewayPing"));
        assertEquals("N/A", health.getDetails().get("uptime"));
    }

    @Test
    void jdaDisconnectedReturnsDown() {
        when(botInitializer.getJda()).thenReturn(jda);
        when(jda.getStatus()).thenReturn(JDA.Status.DISCONNECTED);

        Health health = healthIndicator.health();

        assertEquals(Status.DOWN, health.getStatus());
        assertEquals("DISCONNECTED", health.getDetails().get("discordConnection"));
        assertEquals(-1, health.getDetails().get("gatewayPing"));
        assertEquals("N/A", health.getDetails().get("uptime"));
    }

    @Test
    void jdaConnectedReturnsUpWithAllDetails() {
        when(botInitializer.getJda()).thenReturn(jda);
        when(jda.getStatus()).thenReturn(JDA.Status.CONNECTED);
        when(jda.getGatewayPing()).thenReturn(45L);
        when(botInitializer.getStartTime()).thenReturn(Instant.now().minusSeconds(120));

        Health health = healthIndicator.health();

        assertEquals(Status.UP, health.getStatus());
        assertEquals("CONNECTED", health.getDetails().get("discordConnection"));
        assertEquals(45L, health.getDetails().get("gatewayPing"));
        assertNotNull(health.getDetails().get("uptime"));
        assertNotEquals("N/A", health.getDetails().get("uptime"));
        assertNotNull(health.getDetails().get("registeredCommands"));
    }

    @Test
    void registeredCommandsContainsCommandNames() {
        when(botInitializer.getJda()).thenReturn(jda);
        when(jda.getStatus()).thenReturn(JDA.Status.CONNECTED);
        when(jda.getGatewayPing()).thenReturn(30L);
        when(botInitializer.getStartTime()).thenReturn(Instant.now().minusSeconds(60));

        SlashCommand pingCmd = mock(SlashCommand.class);
        when(pingCmd.getName()).thenReturn("ping");
        SlashCommand statusCmd = mock(SlashCommand.class);
        when(statusCmd.getName()).thenReturn("status");
        when(commandHandler.getRegisteredCommands()).thenReturn(List.of(pingCmd, statusCmd));

        Health health = healthIndicator.health();

        @SuppressWarnings("unchecked")
        List<String> commands = (List<String>) health.getDetails().get("registeredCommands");
        assertNotNull(commands);
        assertEquals(2, commands.size());
        assertTrue(commands.contains("ping"));
        assertTrue(commands.contains("status"));
    }

    @Test
    void gatewayPingIsIncludedWhenConnected() {
        when(botInitializer.getJda()).thenReturn(jda);
        when(jda.getStatus()).thenReturn(JDA.Status.CONNECTED);
        when(jda.getGatewayPing()).thenReturn(99L);
        when(botInitializer.getStartTime()).thenReturn(Instant.now());

        Health health = healthIndicator.health();

        assertEquals(99L, health.getDetails().get("gatewayPing"));
    }

    @Test
    void uptimeIsIncludedWhenStartTimeIsNonNull() {
        when(botInitializer.getJda()).thenReturn(jda);
        when(jda.getStatus()).thenReturn(JDA.Status.CONNECTED);
        when(jda.getGatewayPing()).thenReturn(50L);
        when(botInitializer.getStartTime()).thenReturn(Instant.now().minusSeconds(3661));

        Health health = healthIndicator.health();

        String uptime = (String) health.getDetails().get("uptime");
        assertNotNull(uptime);
        // 3661 seconds = 1h 1m 1s
        assertTrue(uptime.contains("h"), "Uptime should contain hours: " + uptime);
        assertTrue(uptime.contains("m"), "Uptime should contain minutes: " + uptime);
        assertTrue(uptime.contains("s"), "Uptime should contain seconds: " + uptime);
    }

    @Test
    void uptimeIsNAWhenStartTimeIsNull() {
        when(botInitializer.getJda()).thenReturn(jda);
        when(jda.getStatus()).thenReturn(JDA.Status.CONNECTED);
        when(jda.getGatewayPing()).thenReturn(50L);
        when(botInitializer.getStartTime()).thenReturn(null);

        Health health = healthIndicator.health();

        assertEquals("N/A", health.getDetails().get("uptime"));
    }
}
