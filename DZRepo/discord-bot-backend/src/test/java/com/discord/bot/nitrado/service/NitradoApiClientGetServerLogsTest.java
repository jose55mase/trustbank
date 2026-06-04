package com.discord.bot.nitrado.service;

import com.discord.bot.nitrado.config.NitradoConfigProperties;
import com.discord.bot.nitrado.exception.NitradoNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

/**
 * Unit tests for NitradoApiClient.getServerLogs().
 * Validates: Requirements 13.1, 13.2, 13.3, 13.4
 */
class NitradoApiClientGetServerLogsTest {

    private NitradoApiClient client;
    private MockRestServiceServer mockServer;

    @BeforeEach
    void setUp() {
        RestTemplate restTemplate = new RestTemplate();
        mockServer = MockRestServiceServer.createServer(restTemplate);

        NitradoConfigProperties config = new NitradoConfigProperties();
        config.setApiToken("test-token");

        client = new NitradoApiClient(restTemplate, config);
    }

    @Test
    void getServerLogs_findsDayZFolderAndDownloadsLog() {
        // Req 13.1, 13.2: List /games, find DayZ folder, download log
        String listGamesResponse = """
            {
              "status": "success",
              "data": {
                "entries": [
                  {"name": "ni12345_dayz", "path": "/games/ni12345_dayz", "type": "dir", "size": null},
                  {"name": "other_game", "path": "/games/other_game", "type": "dir", "size": null}
                ]
              }
            }
            """;

        String downloadTokenResponse = """
            {
              "status": "success",
              "data": {
                "token": {
                  "url": "https://temp-download.nitrado.net/log-file-content"
                }
              }
            }
            """;

        String logContent = "[2024-01-15 10:30:00] Server started\n[2024-01-15 10:31:00] Player connected";

        // Expect: list files in /games
        mockServer.expect(requestTo("/services/12345/gameservers/file_server/list?dir=/games"))
                .andExpect(method(HttpMethod.GET))
                .andExpect(header("Authorization", "Bearer test-token"))
                .andRespond(withSuccess(listGamesResponse, MediaType.APPLICATION_JSON));

        // Expect: request download URL for the log file
        mockServer.expect(requestTo("/services/12345/gameservers/file_server/download?file=/games/ni12345_dayz/logs/server_log.ADM"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(downloadTokenResponse, MediaType.APPLICATION_JSON));

        // Expect: download from temporary URL
        mockServer.expect(requestTo("https://temp-download.nitrado.net/log-file-content"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(logContent, MediaType.TEXT_PLAIN));

        String result = client.getServerLogs(12345);

        assertEquals(logContent, result);
        mockServer.verify();
    }

    @Test
    void getServerLogs_findsDayZFolderCaseInsensitive() {
        // Req 13.2: DayZ folder detection is case-insensitive
        String listGamesResponse = """
            {
              "status": "success",
              "data": {
                "entries": [
                  {"name": "MyDayZServer", "path": "/games/MyDayZServer", "type": "dir", "size": null}
                ]
              }
            }
            """;

        String downloadTokenResponse = """
            {
              "status": "success",
              "data": {
                "token": {
                  "url": "https://temp-download.nitrado.net/log-content"
                }
              }
            }
            """;

        String logContent = "Log content here";

        mockServer.expect(requestTo("/services/99/gameservers/file_server/list?dir=/games"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(listGamesResponse, MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("/services/99/gameservers/file_server/download?file=/games/MyDayZServer/logs/server_log.ADM"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(downloadTokenResponse, MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("https://temp-download.nitrado.net/log-content"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(logContent, MediaType.TEXT_PLAIN));

        String result = client.getServerLogs(99);

        assertEquals(logContent, result);
        mockServer.verify();
    }

    @Test
    void getServerLogs_usesFallbackWhenDayZFolderNotFound() {
        // Req 13.3: Fallback to /games/ni{serviceId}_dayz/logs/server_log.ADM
        String listGamesResponse = """
            {
              "status": "success",
              "data": {
                "entries": [
                  {"name": "minecraft_server", "path": "/games/minecraft_server", "type": "dir", "size": null},
                  {"name": "rust_server", "path": "/games/rust_server", "type": "dir", "size": null}
                ]
              }
            }
            """;

        String downloadTokenResponse = """
            {
              "status": "success",
              "data": {
                "token": {
                  "url": "https://temp-download.nitrado.net/fallback-log"
                }
              }
            }
            """;

        String logContent = "Fallback log content";

        mockServer.expect(requestTo("/services/54321/gameservers/file_server/list?dir=/games"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(listGamesResponse, MediaType.APPLICATION_JSON));

        // Fallback path: /games/ni54321_dayz/logs/server_log.ADM
        mockServer.expect(requestTo("/services/54321/gameservers/file_server/download?file=/games/ni54321_dayz/logs/server_log.ADM"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(downloadTokenResponse, MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("https://temp-download.nitrado.net/fallback-log"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(logContent, MediaType.TEXT_PLAIN));

        String result = client.getServerLogs(54321);

        assertEquals(logContent, result);
        mockServer.verify();
    }

    @Test
    void getServerLogs_usesFallbackWhenGamesDirectoryEmpty() {
        // Req 13.3: Fallback when /games has no entries
        String listGamesResponse = """
            {
              "status": "success",
              "data": {
                "entries": []
              }
            }
            """;

        String downloadTokenResponse = """
            {
              "status": "success",
              "data": {
                "token": {
                  "url": "https://temp-download.nitrado.net/empty-fallback"
                }
              }
            }
            """;

        String logContent = "Log from fallback";

        mockServer.expect(requestTo("/services/777/gameservers/file_server/list?dir=/games"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(listGamesResponse, MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("/services/777/gameservers/file_server/download?file=/games/ni777_dayz/logs/server_log.ADM"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(downloadTokenResponse, MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("https://temp-download.nitrado.net/empty-fallback"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(logContent, MediaType.TEXT_PLAIN));

        String result = client.getServerLogs(777);

        assertEquals(logContent, result);
        mockServer.verify();
    }

    @Test
    void getServerLogs_throwsNotFoundWhenLogFileDoesNotExist() {
        // Req 13.4: Throw NitradoNotFoundException when log file doesn't exist
        String listGamesResponse = """
            {
              "status": "success",
              "data": {
                "entries": [
                  {"name": "ni12345_dayz", "path": "/games/ni12345_dayz", "type": "dir", "size": null}
                ]
              }
            }
            """;

        mockServer.expect(requestTo("/services/12345/gameservers/file_server/list?dir=/games"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(listGamesResponse, MediaType.APPLICATION_JSON));

        // Download request returns 404
        mockServer.expect(requestTo("/services/12345/gameservers/file_server/download?file=/games/ni12345_dayz/logs/server_log.ADM"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withResourceNotFound().body("{\"message\": \"File not found\"}"));

        NitradoNotFoundException ex = assertThrows(NitradoNotFoundException.class,
                () -> client.getServerLogs(12345));

        assertTrue(ex.getMessage().contains("log"));
        mockServer.verify();
    }

    @Test
    void getServerLogs_ignoresFilesOnlyMatchesDirectories() {
        // Only directories with "dayz" in the name should be matched, not files
        String listGamesResponse = """
            {
              "status": "success",
              "data": {
                "entries": [
                  {"name": "dayz_config.txt", "path": "/games/dayz_config.txt", "type": "file", "size": 512},
                  {"name": "other_dir", "path": "/games/other_dir", "type": "dir", "size": null}
                ]
              }
            }
            """;

        String downloadTokenResponse = """
            {
              "status": "success",
              "data": {
                "token": {
                  "url": "https://temp-download.nitrado.net/fallback-file"
                }
              }
            }
            """;

        String logContent = "Fallback because no dir matched";

        mockServer.expect(requestTo("/services/42/gameservers/file_server/list?dir=/games"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(listGamesResponse, MediaType.APPLICATION_JSON));

        // Should use fallback since "dayz_config.txt" is a file, not a dir
        mockServer.expect(requestTo("/services/42/gameservers/file_server/download?file=/games/ni42_dayz/logs/server_log.ADM"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(downloadTokenResponse, MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("https://temp-download.nitrado.net/fallback-file"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(logContent, MediaType.TEXT_PLAIN));

        String result = client.getServerLogs(42);

        assertEquals(logContent, result);
        mockServer.verify();
    }
}
