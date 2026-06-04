package com.discord.bot.nitrado.controller;

import com.discord.bot.nitrado.dto.FileContentResponse;
import com.discord.bot.nitrado.dto.FileEntryDto;
import com.discord.bot.nitrado.exception.NitradoExceptionHandler;
import com.discord.bot.nitrado.exception.NitradoNotFoundException;
import com.discord.bot.nitrado.service.NitradoApiClient;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Unit tests for FileController using @WebMvcTest slice.
 * Validates: Requirements 10.1, 10.3, 10.4, 11.1, 11.3, 12.1
 */
@WebMvcTest(FileController.class)
@Import(NitradoExceptionHandler.class)
class FileControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private NitradoApiClient nitradoClient;

    // ── GET /api/servers/{id}/files ──

    @Test
    void listFiles_withoutPathParam_usesRootByDefault() throws Exception {
        // Req 10.4: If no path parameter is provided, use "/" as default root directory
        List<FileEntryDto> entries = List.of(
                new FileEntryDto("games", "/games", "dir", null),
                new FileEntryDto("config.cfg", "/config.cfg", "file", 1024L)
        );
        when(nitradoClient.listFiles(12345, "/")).thenReturn(entries);

        mockMvc.perform(get("/api/servers/12345/files"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].name", is("games")))
                .andExpect(jsonPath("$[0].path", is("/games")))
                .andExpect(jsonPath("$[0].type", is("dir")))
                .andExpect(jsonPath("$[0].size").doesNotExist())
                .andExpect(jsonPath("$[1].name", is("config.cfg")))
                .andExpect(jsonPath("$[1].path", is("/config.cfg")))
                .andExpect(jsonPath("$[1].type", is("file")))
                .andExpect(jsonPath("$[1].size", is(1024)));

        verify(nitradoClient).listFiles(12345, "/");
    }

    @Test
    void listFiles_withNonExistentDirectory_returns404() throws Exception {
        // Req 10.3: If the requested directory does not exist, return 404
        when(nitradoClient.listFiles(12345, "/nonexistent"))
                .thenThrow(new NitradoNotFoundException("Directorio no encontrado: /nonexistent"));

        mockMvc.perform(get("/api/servers/12345/files").param("path", "/nonexistent"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error", is("NOT_FOUND")))
                .andExpect(jsonPath("$.message", containsString("/nonexistent")));

        verify(nitradoClient).listFiles(12345, "/nonexistent");
    }

    // ── GET /api/servers/{id}/files/download ──

    @Test
    void downloadFile_returnsFileContent() throws Exception {
        // Req 11.1: GET /api/servers/{serviceId}/files/download returns file content as text
        when(nitradoClient.downloadFile(12345, "/games/dayz/config.cfg"))
                .thenReturn("maxPlayers=60\nserverName=MyServer");

        mockMvc.perform(get("/api/servers/12345/files/download").param("path", "/games/dayz/config.cfg"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", is("maxPlayers=60\nserverName=MyServer")));

        verify(nitradoClient).downloadFile(12345, "/games/dayz/config.cfg");
    }

    @Test
    void downloadFile_withNonExistentFile_returns404() throws Exception {
        // Req 11.3: If the requested file does not exist, return 404
        when(nitradoClient.downloadFile(12345, "/games/dayz/missing.cfg"))
                .thenThrow(new NitradoNotFoundException("Archivo no encontrado: /games/dayz/missing.cfg"));

        mockMvc.perform(get("/api/servers/12345/files/download").param("path", "/games/dayz/missing.cfg"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error", is("NOT_FOUND")))
                .andExpect(jsonPath("$.message", containsString("missing.cfg")));

        verify(nitradoClient).downloadFile(12345, "/games/dayz/missing.cfg");
    }

    // ── POST /api/servers/{id}/files/upload ──

    @Test
    void uploadFile_returns200() throws Exception {
        // Req 12.1: POST /api/servers/{serviceId}/files/upload returns 200 with confirmation
        doNothing().when(nitradoClient).uploadFile(12345, "/games/dayz/config.cfg", "maxPlayers=80");

        mockMvc.perform(post("/api/servers/12345/files/upload")
                        .param("path", "/games/dayz/config.cfg")
                        .contentType(MediaType.TEXT_PLAIN)
                        .content("maxPlayers=80"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", is("success")))
                .andExpect(jsonPath("$.message", notNullValue()));

        verify(nitradoClient).uploadFile(12345, "/games/dayz/config.cfg", "maxPlayers=80");
    }
}
