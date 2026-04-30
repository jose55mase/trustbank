package com.discord.bot.nitrado.service;

import com.discord.bot.nitrado.config.NitradoConfigProperties;
import com.discord.bot.nitrado.exception.NitradoApiException;
import com.discord.bot.nitrado.exception.NitradoAuthException;
import com.discord.bot.nitrado.exception.NitradoNotFoundException;
import com.discord.bot.nitrado.exception.NitradoServerException;
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
 * Unit tests for NitradoApiClient.uploadFile().
 * Validates: Requirements 12.1, 12.2, 12.3
 */
class NitradoApiClientUploadFileTest {

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
    void uploadFile_sendsPostWithCorrectUrlAndHeaders() {
        // Req 12.1, 12.2: POST to upload endpoint with path as query param and octet-stream content type
        String responseJson = """
            {
              "status": "success",
              "message": "File uploaded"
            }
            """;

        mockServer.expect(requestTo("/services/12345/gameservers/file_server/upload?path=/games/dayz/config.cfg"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("Authorization", "Bearer test-token"))
                .andExpect(header("Content-Type", "application/octet-stream"))
                .andExpect(content().string("file content here"))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        assertDoesNotThrow(() -> client.uploadFile(12345, "/games/dayz/config.cfg", "file content here"));

        mockServer.verify();
    }

    @Test
    void uploadFile_sendsContentAsRequestBody() {
        // Req 12.2: Content is sent as the request body
        String fileContent = "{\n  \"maxPlayers\": 60,\n  \"serverName\": \"My DayZ Server\"\n}";

        String responseJson = """
            {
              "status": "success"
            }
            """;

        mockServer.expect(requestTo("/services/99999/gameservers/file_server/upload?path=/config/serverDZ.cfg"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(content().string(fileContent))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        assertDoesNotThrow(() -> client.uploadFile(99999, "/config/serverDZ.cfg", fileContent));

        mockServer.verify();
    }

    @Test
    void uploadFile_throwsNitradoAuthExceptionOn401() {
        // Req 12.3: Auth errors are propagated
        mockServer.expect(requestTo("/services/12345/gameservers/file_server/upload?path=/test.txt"))
                .andExpect(method(HttpMethod.POST))
                .andRespond(withUnauthorizedRequest().body("{\"message\":\"Invalid token\"}"));

        assertThrows(NitradoAuthException.class, () ->
                client.uploadFile(12345, "/test.txt", "content"));

        mockServer.verify();
    }

    @Test
    void uploadFile_throwsNitradoNotFoundExceptionOn404() {
        // Req 12.3: 404 errors are propagated
        mockServer.expect(requestTo("/services/12345/gameservers/file_server/upload?path=/nonexistent/path.txt"))
                .andExpect(method(HttpMethod.POST))
                .andRespond(withResourceNotFound().body("{\"message\":\"Path not found\"}"));

        NitradoNotFoundException ex = assertThrows(NitradoNotFoundException.class, () ->
                client.uploadFile(12345, "/nonexistent/path.txt", "content"));

        assertEquals("Path not found", ex.getMessage());

        mockServer.verify();
    }

    @Test
    void uploadFile_throwsNitradoServerExceptionOn500() {
        // Req 12.3: Server errors are propagated
        mockServer.expect(requestTo("/services/12345/gameservers/file_server/upload?path=/test.txt"))
                .andExpect(method(HttpMethod.POST))
                .andRespond(withServerError());

        assertThrows(NitradoServerException.class, () ->
                client.uploadFile(12345, "/test.txt", "content"));

        mockServer.verify();
    }
}
