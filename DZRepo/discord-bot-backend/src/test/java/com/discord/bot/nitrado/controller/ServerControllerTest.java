package com.discord.bot.nitrado.controller;

import com.discord.bot.nitrado.dto.ActionResponse;
import com.discord.bot.nitrado.dto.BannedPlayerDto;
import com.discord.bot.nitrado.dto.GameServerDto;
import com.discord.bot.nitrado.dto.LogResponse;
import com.discord.bot.nitrado.exception.NitradoExceptionHandler;
import com.discord.bot.nitrado.exception.NitradoNotFoundException;
import com.discord.bot.nitrado.service.NitradoApiClient;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.Collections;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Unit tests for ServerController using @WebMvcTest slice.
 * Validates: Requirements 2.1, 2.5, 3.1, 3.3, 4.1, 4.4, 8.1, 9.1, 13.1
 */
@WebMvcTest(ServerController.class)
@Import(NitradoExceptionHandler.class)
class ServerControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private NitradoApiClient nitradoClient;

    // ── GET /api/servers ──

    @Test
    void getServers_returnsListOfGameServerDto() throws Exception {
        // Req 2.1: GET /api/servers returns a list of GameServer objects
        List<GameServerDto> servers = List.of(
                new GameServerDto(12345, "DayZ Server 1", "1.2.3.4", 2302,
                        "active", 10, 60, "chernarusplus", "1.25"),
                new GameServerDto(67890, "DayZ Server 2", "5.6.7.8", 2402,
                        "stopped", 0, 100, "livonia", "1.26")
        );
        when(nitradoClient.getServers()).thenReturn(servers);

        mockMvc.perform(get("/api/servers"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].id", is(12345)))
                .andExpect(jsonPath("$[0].name", is("DayZ Server 1")))
                .andExpect(jsonPath("$[0].ip", is("1.2.3.4")))
                .andExpect(jsonPath("$[0].port", is(2302)))
                .andExpect(jsonPath("$[0].status", is("active")))
                .andExpect(jsonPath("$[0].currentPlayers", is(10)))
                .andExpect(jsonPath("$[0].maxPlayers", is(60)))
                .andExpect(jsonPath("$[0].map", is("chernarusplus")))
                .andExpect(jsonPath("$[0].gameVersion", is("1.25")))
                .andExpect(jsonPath("$[1].id", is(67890)))
                .andExpect(jsonPath("$[1].name", is("DayZ Server 2")));

        verify(nitradoClient).getServers();
    }

    @Test
    void getServers_returnsEmptyListWhenNoServers() throws Exception {
        // Req 2.5: If Nitrado returns no DayZ services, return empty list with 200
        when(nitradoClient.getServers()).thenReturn(Collections.emptyList());

        mockMvc.perform(get("/api/servers"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));

        verify(nitradoClient).getServers();
    }

    // ── GET /api/servers/{id}/status ──

    @Test
    void getServerStatus_returnsDetailedGameServerDto() throws Exception {
        // Req 3.1: GET /api/servers/{serviceId}/status returns detailed GameServer
        GameServerDto server = new GameServerDto(12345, "DayZ Server 1", "1.2.3.4", 2302,
                "started", 42, 60, "chernarusplus", "1.25.158456");
        when(nitradoClient.getServerStatus(12345)).thenReturn(server);

        mockMvc.perform(get("/api/servers/12345/status"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(12345)))
                .andExpect(jsonPath("$.name", is("DayZ Server 1")))
                .andExpect(jsonPath("$.ip", is("1.2.3.4")))
                .andExpect(jsonPath("$.port", is(2302)))
                .andExpect(jsonPath("$.status", is("started")))
                .andExpect(jsonPath("$.currentPlayers", is(42)))
                .andExpect(jsonPath("$.maxPlayers", is(60)))
                .andExpect(jsonPath("$.map", is("chernarusplus")))
                .andExpect(jsonPath("$.gameVersion", is("1.25.158456")));

        verify(nitradoClient).getServerStatus(12345);
    }

    @Test
    void getServerStatus_returns404WhenServerNotFound() throws Exception {
        // Req 3.3: Non-existent serviceId returns 404
        when(nitradoClient.getServerStatus(99999))
                .thenThrow(new NitradoNotFoundException("Servidor no encontrado: 99999"));

        mockMvc.perform(get("/api/servers/99999/status"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error", is("NOT_FOUND")))
                .andExpect(jsonPath("$.message", containsString("99999")));

        verify(nitradoClient).getServerStatus(99999);
    }

    // ── POST /api/servers/{id}/actions/{action} ──

    @Test
    void serverAction_start_returns200() throws Exception {
        // Req 4.1: Valid action (start) returns 200 with confirmation
        doNothing().when(nitradoClient).serverAction(anyInt(), any());

        mockMvc.perform(post("/api/servers/12345/actions/start"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", is("success")))
                .andExpect(jsonPath("$.message", containsString("start")));
    }

    @Test
    void serverAction_invalidAction_returns400() throws Exception {
        // Req 4.4: Invalid action returns 400 with allowed actions in message
        // ServerAction.fromString("invalid") throws IllegalArgumentException
        // which NitradoExceptionHandler catches and returns 400
        mockMvc.perform(post("/api/servers/12345/actions/invalid"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error", is("BAD_REQUEST")))
                .andExpect(jsonPath("$.message", containsString("start, stop, restart")));
    }

    // ── GET /api/servers/{id}/logs ──

    @Test
    void getServerLogs_returnsLogContent() throws Exception {
        // Req 13.1: GET /api/servers/{serviceId}/logs returns log content
        when(nitradoClient.getServerLogs(12345)).thenReturn("2024-01-01 12:00:00 | Server started\n2024-01-01 12:01:00 | Player connected");

        mockMvc.perform(get("/api/servers/12345/logs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", containsString("Server started")))
                .andExpect(jsonPath("$.content", containsString("Player connected")));

        verify(nitradoClient).getServerLogs(12345);
    }

    // ── GET /api/servers/{id}/banlist ──

    @Test
    void getBanList_returnsListOfBannedPlayers() throws Exception {
        // Req 8.1: GET /api/servers/{serviceId}/banlist returns list of BannedPlayer
        Instant bannedAt = Instant.parse("2024-06-15T10:30:00Z");
        List<BannedPlayerDto> banList = List.of(
                new BannedPlayerDto("player1", "BadPlayer", "Cheating", bannedAt),
                new BannedPlayerDto("player2", "Griefer", "Griefing", null)
        );
        when(nitradoClient.getBanList(12345)).thenReturn(banList);

        mockMvc.perform(get("/api/servers/12345/banlist"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].id", is("player1")))
                .andExpect(jsonPath("$[0].name", is("BadPlayer")))
                .andExpect(jsonPath("$[0].reason", is("Cheating")))
                .andExpect(jsonPath("$[1].id", is("player2")))
                .andExpect(jsonPath("$[1].name", is("Griefer")));

        verify(nitradoClient).getBanList(12345);
    }

    @Test
    void getBanList_returnsEmptyListWhenNoBannedPlayers() throws Exception {
        // Req 8.1: Empty ban list returns 200 with empty array
        when(nitradoClient.getBanList(12345)).thenReturn(Collections.emptyList());

        mockMvc.perform(get("/api/servers/12345/banlist"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));

        verify(nitradoClient).getBanList(12345);
    }

    // ── DELETE /api/servers/{id}/banlist/{playerId} ──

    @Test
    void unbanPlayer_returns200() throws Exception {
        // Req 9.1: DELETE /api/servers/{serviceId}/banlist/{playerId} returns 200
        doNothing().when(nitradoClient).unbanPlayer(12345, "player1");

        mockMvc.perform(delete("/api/servers/12345/banlist/player1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", is("success")))
                .andExpect(jsonPath("$.message", containsString("desbaneado")));

        verify(nitradoClient).unbanPlayer(12345, "player1");
    }
}
