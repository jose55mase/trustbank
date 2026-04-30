package com.discord.bot.nitrado.controller;

import com.discord.bot.nitrado.dto.ActionResponse;
import com.discord.bot.nitrado.dto.PlayerDto;
import com.discord.bot.nitrado.exception.NitradoExceptionHandler;
import com.discord.bot.nitrado.service.NitradoApiClient;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Collections;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Unit tests for PlayerController using @WebMvcTest slice.
 * Validates: Requirements 5.1, 5.3, 6.1, 7.1
 */
@WebMvcTest(PlayerController.class)
@Import(NitradoExceptionHandler.class)
class PlayerControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private NitradoApiClient nitradoClient;

    // ── GET /api/servers/{id}/players ──

    @Test
    void getPlayers_returnsEmptyListWith200() throws Exception {
        // Req 5.3: If no players are connected, return empty list with 200
        when(nitradoClient.getPlayers(12345)).thenReturn(Collections.emptyList());

        mockMvc.perform(get("/api/servers/12345/players"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));

        verify(nitradoClient).getPlayers(12345);
    }

    @Test
    void getPlayers_returnsListOfPlayerDto() throws Exception {
        // Req 5.1: GET /api/servers/{serviceId}/players returns list of Player objects
        List<PlayerDto> players = List.of(
                new PlayerDto("player1", "Alice", true),
                new PlayerDto("player2", "Bob", true)
        );
        when(nitradoClient.getPlayers(12345)).thenReturn(players);

        mockMvc.perform(get("/api/servers/12345/players"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].id", is("player1")))
                .andExpect(jsonPath("$[0].name", is("Alice")))
                .andExpect(jsonPath("$[0].online", is(true)))
                .andExpect(jsonPath("$[1].id", is("player2")))
                .andExpect(jsonPath("$[1].name", is("Bob")));

        verify(nitradoClient).getPlayers(12345);
    }

    // ── POST /api/servers/{id}/players/{pid}/kick ──

    @Test
    void kickPlayer_returns200() throws Exception {
        // Req 6.1: POST /api/servers/{serviceId}/players/{playerId}/kick returns 200
        doNothing().when(nitradoClient).kickPlayer(12345, "player1");

        mockMvc.perform(post("/api/servers/12345/players/player1/kick"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", is("success")))
                .andExpect(jsonPath("$.message", notNullValue()));

        verify(nitradoClient).kickPlayer(12345, "player1");
    }

    // ── POST /api/servers/{id}/players/{pid}/ban ──

    @Test
    void banPlayer_withReason_returns200() throws Exception {
        // Req 7.1: POST /api/servers/{serviceId}/players/{playerId}/ban with reason returns 200
        doNothing().when(nitradoClient).banPlayer(12345, "player1", "Cheating");

        mockMvc.perform(post("/api/servers/12345/players/player1/ban")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\": \"Cheating\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", is("success")))
                .andExpect(jsonPath("$.message", notNullValue()));

        verify(nitradoClient).banPlayer(12345, "player1", "Cheating");
    }

    @Test
    void banPlayer_withoutReason_returns200() throws Exception {
        // Req 7.1: POST /api/servers/{serviceId}/players/{playerId}/ban without reason returns 200
        doNothing().when(nitradoClient).banPlayer(12345, "player1", null);

        mockMvc.perform(post("/api/servers/12345/players/player1/ban"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", is("success")))
                .andExpect(jsonPath("$.message", notNullValue()));

        verify(nitradoClient).banPlayer(12345, "player1", null);
    }
}
