package com.discord.bot.nitrado.service;

import com.discord.bot.nitrado.config.NitradoConfigProperties;
import com.discord.bot.nitrado.dto.GameServerDto;
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
 * Unit tests for NitradoApiClient.getServers().
 * Validates: Requirements 2.1, 2.2, 2.3, 2.4
 */
class NitradoApiClientGetServersTest {

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
    void getServers_returnsDayZServersOnly() {
        // Req 2.2: Filter services whose game field contains "dayz" (case-insensitive)
        String responseJson = """
            {
              "status": "success",
              "data": {
                "services": [
                  {
                    "id": 12345,
                    "status": "active",
                    "details": {
                      "game": "DayZ (PC)",
                      "name": "My DayZ Server",
                      "address": "1.2.3.4",
                      "port": 2302,
                      "players_current": 10,
                      "players_max": 60,
                      "map": "chernarusplus",
                      "version": "1.25"
                    }
                  },
                  {
                    "id": 67890,
                    "status": "active",
                    "details": {
                      "game": "Minecraft",
                      "name": "My Minecraft Server",
                      "address": "5.6.7.8",
                      "port": 25565,
                      "players_current": 5,
                      "players_max": 20,
                      "map": "world",
                      "version": "1.20"
                    }
                  }
                ]
              }
            }
            """;

        mockServer.expect(requestTo("/services"))
                .andExpect(method(HttpMethod.GET))
                .andExpect(header("Authorization", "Bearer test-token"))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<GameServerDto> servers = client.getServers();

        assertEquals(1, servers.size());
        GameServerDto server = servers.get(0);
        assertEquals(12345, server.id());
        assertEquals("My DayZ Server", server.name());
        assertEquals("1.2.3.4", server.ip());
        assertEquals(2302, server.port());
        assertEquals("active", server.status());
        assertEquals(10, server.currentPlayers());
        assertEquals(60, server.maxPlayers());
        assertEquals("chernarusplus", server.map());
        assertEquals("1.25", server.gameVersion());

        mockServer.verify();
    }

    @Test
    void getServers_filtersCaseInsensitive() {
        // Req 2.2: Case-insensitive filtering for "dayz"
        String responseJson = """
            {
              "status": "success",
              "data": {
                "services": [
                  {
                    "id": 1,
                    "status": "active",
                    "details": { "game": "DAYZ", "name": "S1", "address": "1.1.1.1", "port": 2302, "players_current": 0, "players_max": 60, "map": "chernarusplus", "version": "1.25" }
                  },
                  {
                    "id": 2,
                    "status": "active",
                    "details": { "game": "dayz", "name": "S2", "address": "2.2.2.2", "port": 2302, "players_current": 0, "players_max": 60, "map": "chernarusplus", "version": "1.25" }
                  },
                  {
                    "id": 3,
                    "status": "active",
                    "details": { "game": "DayZ (Xbox)", "name": "S3", "address": "3.3.3.3", "port": 2302, "players_current": 0, "players_max": 60, "map": "chernarusplus", "version": "1.25" }
                  },
                  {
                    "id": 4,
                    "status": "active",
                    "details": { "game": "Rust", "name": "S4", "address": "4.4.4.4", "port": 28015, "players_current": 0, "players_max": 100, "map": "procedural", "version": "2024" }
                  }
                ]
              }
            }
            """;

        mockServer.expect(requestTo("/services"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<GameServerDto> servers = client.getServers();

        assertEquals(3, servers.size());
        assertEquals(1, servers.get(0).id());
        assertEquals(2, servers.get(1).id());
        assertEquals(3, servers.get(2).id());

        mockServer.verify();
    }

    @Test
    void getServers_returnsEmptyListWhenNoDayZServices() {
        // Req 2.4: Return empty list if no DayZ services found
        String responseJson = """
            {
              "status": "success",
              "data": {
                "services": [
                  {
                    "id": 1,
                    "status": "active",
                    "details": { "game": "Minecraft", "name": "MC Server", "address": "1.1.1.1", "port": 25565, "players_current": 0, "players_max": 20, "map": "world", "version": "1.20" }
                  }
                ]
              }
            }
            """;

        mockServer.expect(requestTo("/services"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<GameServerDto> servers = client.getServers();

        assertTrue(servers.isEmpty());
        mockServer.verify();
    }

    @Test
    void getServers_returnsEmptyListWhenNoServices() {
        // Req 2.4: Return empty list when services array is empty
        String responseJson = """
            {
              "status": "success",
              "data": {
                "services": []
              }
            }
            """;

        mockServer.expect(requestTo("/services"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<GameServerDto> servers = client.getServers();

        assertTrue(servers.isEmpty());
        mockServer.verify();
    }

    @Test
    void getServers_mapsAllFieldsCorrectly() {
        // Req 2.3: Map each service to GameServerDto with all fields
        String responseJson = """
            {
              "status": "success",
              "data": {
                "services": [
                  {
                    "id": 99999,
                    "status": "stopped",
                    "details": {
                      "game": "DayZ (PC)",
                      "name": "Test Server Alpha",
                      "address": "192.168.1.100",
                      "port": 2402,
                      "players_current": 42,
                      "players_max": 100,
                      "map": "livonia",
                      "version": "1.26.158456"
                    }
                  }
                ]
              }
            }
            """;

        mockServer.expect(requestTo("/services"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<GameServerDto> servers = client.getServers();

        assertEquals(1, servers.size());
        GameServerDto s = servers.get(0);
        assertEquals(99999, s.id());
        assertEquals("Test Server Alpha", s.name());
        assertEquals("192.168.1.100", s.ip());
        assertEquals(2402, s.port());
        assertEquals("stopped", s.status());
        assertEquals(42, s.currentPlayers());
        assertEquals(100, s.maxPlayers());
        assertEquals("livonia", s.map());
        assertEquals("1.26.158456", s.gameVersion());

        mockServer.verify();
    }

    @Test
    void getServers_handlesServiceWithMissingDetails() {
        // Services without details should be skipped
        String responseJson = """
            {
              "status": "success",
              "data": {
                "services": [
                  {
                    "id": 1,
                    "status": "active"
                  },
                  {
                    "id": 2,
                    "status": "active",
                    "details": {
                      "game": "DayZ (PC)",
                      "name": "Valid Server",
                      "address": "1.1.1.1",
                      "port": 2302,
                      "players_current": 5,
                      "players_max": 60,
                      "map": "chernarusplus",
                      "version": "1.25"
                    }
                  }
                ]
              }
            }
            """;

        mockServer.expect(requestTo("/services"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<GameServerDto> servers = client.getServers();

        assertEquals(1, servers.size());
        assertEquals(2, servers.get(0).id());

        mockServer.verify();
    }

    @Test
    void getServers_handlesServiceWithMissingOptionalFields() {
        // Services with missing optional fields should use defaults
        String responseJson = """
            {
              "status": "success",
              "data": {
                "services": [
                  {
                    "id": 1,
                    "status": "active",
                    "details": {
                      "game": "DayZ (PC)"
                    }
                  }
                ]
              }
            }
            """;

        mockServer.expect(requestTo("/services"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        List<GameServerDto> servers = client.getServers();

        assertEquals(1, servers.size());
        GameServerDto s = servers.get(0);
        assertEquals(1, s.id());
        assertEquals("", s.name());
        assertEquals("", s.ip());
        assertEquals(0, s.port());
        assertEquals("active", s.status());
        assertEquals(0, s.currentPlayers());
        assertEquals(0, s.maxPlayers());
        assertEquals("", s.map());
        assertEquals("", s.gameVersion());

        mockServer.verify();
    }
}
