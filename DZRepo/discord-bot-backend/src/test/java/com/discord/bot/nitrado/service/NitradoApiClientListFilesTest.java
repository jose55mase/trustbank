package com.discord.bot.nitrado.service;

import com.discord.bot.nitrado.config.NitradoConfigProperties;
import com.discord.bot.nitrado.dto.FileEntryDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

/**
 * Unit tests for NitradoApiClient.listFiles().
 * Validates: Requirements 10.1, 10.2, 10.3, 10.4
 */
class NitradoApiClientListFilesTest {

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
    void listFiles_returnsFileAndDirectoryEntries() {
        // Req 10.1, 10.2: List files at a given path and map to FileEntryDto
        String responseJson = """
            {
              "status": "success",
              "data": {
                "entries": [
                  {
                    "name": "config.json",
                    "path": "/games/ni12345_dayz/config.json",
                    "type": "file",
                    "size": 1024
                  },
                  {
                    "name": "logs",
                    "path": "/games/ni12345_dayz/logs",
                    "type": "dir",
                    "size": null
                  }
                ]
              }
            }
            """;

        mockServer.expect(requestTo("/services/12345/gameservers/file_server/list?dir=/games/ni12345_dayz"))
                .andExpect(method(HttpMethod.GET))
                .andExpect(header("Authorization", "Bearer test-token"))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<FileEntryDto> files = client.listFiles(12345, "/games/ni12345_dayz");

        assertEquals(2, files.size());

        FileEntryDto file = files.get(0);
        assertEquals("config.json", file.name());
        assertEquals("/games/ni12345_dayz/config.json", file.path());
        assertEquals("file", file.type());
        assertEquals(1024L, file.size());

        FileEntryDto dir = files.get(1);
        assertEquals("logs", dir.name());
        assertEquals("/games/ni12345_dayz/logs", dir.path());
        assertEquals("dir", dir.type());
        assertNull(dir.size());

        mockServer.verify();
    }

    @Test
    void listFiles_returnsEmptyListWhenNoEntries() {
        // Req 10.1: Return empty list when directory is empty
        String responseJson = """
            {
              "status": "success",
              "data": {
                "entries": []
              }
            }
            """;

        mockServer.expect(requestTo("/services/12345/gameservers/file_server/list?dir=/"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<FileEntryDto> files = client.listFiles(12345, "/");

        assertTrue(files.isEmpty());
        mockServer.verify();
    }

    @Test
    void listFiles_returnsEmptyListWhenEntriesFieldMissing() {
        // Handles missing entries field gracefully
        String responseJson = """
            {
              "status": "success",
              "data": {}
            }
            """;

        mockServer.expect(requestTo("/services/12345/gameservers/file_server/list?dir=/"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<FileEntryDto> files = client.listFiles(12345, "/");

        assertTrue(files.isEmpty());
        mockServer.verify();
    }

    @Test
    void listFiles_passesDirectoryAsQueryParameter() {
        // Req 10.2: The dir query parameter is sent correctly
        String responseJson = """
            {
              "status": "success",
              "data": {
                "entries": [
                  {
                    "name": "server_log.ADM",
                    "path": "/games/ni12345_dayz/logs/server_log.ADM",
                    "type": "file",
                    "size": 51200
                  }
                ]
              }
            }
            """;

        mockServer.expect(requestTo("/services/99999/gameservers/file_server/list?dir=/games/ni99999_dayz/logs"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<FileEntryDto> files = client.listFiles(99999, "/games/ni99999_dayz/logs");

        assertEquals(1, files.size());
        assertEquals("server_log.ADM", files.get(0).name());
        assertEquals(51200L, files.get(0).size());

        mockServer.verify();
    }

    @Test
    void listFiles_handlesEntriesWithMissingOptionalFields() {
        // Entries with missing fields should use defaults
        String responseJson = """
            {
              "status": "success",
              "data": {
                "entries": [
                  {
                    "name": "unknown",
                    "path": "/unknown",
                    "type": "file"
                  }
                ]
              }
            }
            """;

        mockServer.expect(requestTo("/services/12345/gameservers/file_server/list?dir=/"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<FileEntryDto> files = client.listFiles(12345, "/");

        assertEquals(1, files.size());
        FileEntryDto entry = files.get(0);
        assertEquals("unknown", entry.name());
        assertEquals("/unknown", entry.path());
        assertEquals("file", entry.type());
        assertNull(entry.size());

        mockServer.verify();
    }
}
