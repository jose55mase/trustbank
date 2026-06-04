package com.discord.bot.nitrado.service;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.discord.bot.nitrado.config.NitradoConfigProperties;
import com.discord.bot.nitrado.exception.NitradoConnectionException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.test.web.client.response.MockRestResponseCreators;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.net.SocketTimeoutException;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

/**
 * Unit tests for NitradoApiClient — error handling and logging.
 * Validates: Requirements 11.2, 13.3, 14.4, 15.1, 15.2, 15.3
 */
class NitradoApiClientErrorHandlingTest {

    private NitradoApiClient client;
    private MockRestServiceServer mockServer;
    private ListAppender<ILoggingEvent> logAppender;
    private Logger nitradoLogger;

    @BeforeEach
    void setUp() {
        RestTemplate restTemplate = new RestTemplate();
        mockServer = MockRestServiceServer.createServer(restTemplate);

        NitradoConfigProperties config = new NitradoConfigProperties();
        config.setApiToken("test-token");

        client = new NitradoApiClient(restTemplate, config);

        // Set up Logback ListAppender to capture log output
        nitradoLogger = (Logger) LoggerFactory.getLogger(NitradoApiClient.class);
        nitradoLogger.setLevel(Level.DEBUG);

        logAppender = new ListAppender<>();
        logAppender.start();
        nitradoLogger.addAppender(logAppender);
    }

    @AfterEach
    void tearDown() {
        nitradoLogger.detachAppender(logAppender);
        logAppender.stop();
    }

    // ── Req 14.4: Connection timeout throws NitradoConnectionException ──

    @Test
    void execute_connectionTimeout_throwsNitradoConnectionException() {
        // Req 14.4: Timeout de conexión devuelve NitradoConnectionException
        mockServer.expect(requestTo("/services"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(request -> {
                    throw new ResourceAccessException(
                            "I/O error on GET request",
                            new SocketTimeoutException("Connect timed out"));
                });

        NitradoConnectionException ex = assertThrows(NitradoConnectionException.class,
                () -> client.getServers());

        assertTrue(ex.getMessage().contains("No se pudo contactar con el servicio de Nitrado"));
    }

    // ── Req 13.3: Fallback log path when DayZ folder not found ──

    @Test
    void getServerLogs_fallbackPath_whenNoDayZFolderFound() {
        // Req 13.3: Fallback to /games/ni{serviceId}_dayz/logs/server_log.ADM
        String listGamesResponse = """
            {
              "status": "success",
              "data": {
                "entries": [
                  {"name": "minecraft_server", "path": "/games/minecraft_server", "type": "dir", "size": null}
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

        mockServer.expect(requestTo("/services/11111/gameservers/file_server/list?dir=/games"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(listGamesResponse, MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("/services/11111/gameservers/file_server/download?file=/games/ni11111_dayz/logs/server_log.ADM"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(downloadTokenResponse, MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("https://temp-download.nitrado.net/fallback-log"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(logContent, MediaType.TEXT_PLAIN));

        String result = client.getServerLogs(11111);

        assertEquals(logContent, result);

        // Verify fallback log message was emitted
        boolean hasFallbackLog = logAppender.list.stream()
                .anyMatch(event -> event.getLevel() == Level.INFO
                        && event.getFormattedMessage().contains("DayZ folder not found")
                        && event.getFormattedMessage().contains("fallback")
                        && event.getFormattedMessage().contains("11111"));
        assertTrue(hasFallbackLog, "Expected INFO log about DayZ folder fallback with serviceId");

        mockServer.verify();
    }

    // ── Req 11.2: Two-step file download (temporary URL + content) ──

    @Test
    void downloadFile_twoStepProcess_getsTemporaryUrlThenDownloadsContent() {
        // Req 11.2: Download in two steps — get temporary URL, then download content
        String downloadTokenResponse = """
            {
              "status": "success",
              "data": {
                "token": {
                  "url": "https://temp-download.nitrado.net/file-abc123"
                }
              }
            }
            """;

        String fileContent = "server_name = \"My DayZ Server\"\nmaxPlayers = 60";

        // Step 1: Request temporary download URL from Nitrado API
        mockServer.expect(requestTo("/services/5555/gameservers/file_server/download?file=/games/dayz/config.cfg"))
                .andExpect(method(HttpMethod.GET))
                .andExpect(header("Authorization", "Bearer test-token"))
                .andRespond(withSuccess(downloadTokenResponse, MediaType.APPLICATION_JSON));

        // Step 2: Download actual content from temporary URL
        mockServer.expect(requestTo("https://temp-download.nitrado.net/file-abc123"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(fileContent, MediaType.TEXT_PLAIN));

        String result = client.downloadFile(5555, "/games/dayz/config.cfg");

        assertEquals(fileContent, result);
        mockServer.verify();
    }

    // ── Req 15.1: INFO logs contain HTTP method, URL, and serviceId ──

    @Test
    void infoLogs_containHttpMethodUrlAndServiceId() {
        // Req 15.1: INFO logs contain HTTP method, URL, and serviceId
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

        client.getServers();

        List<ILoggingEvent> infoLogs = logAppender.list.stream()
                .filter(event -> event.getLevel() == Level.INFO)
                .toList();

        assertFalse(infoLogs.isEmpty(), "Expected at least one INFO log");

        // Verify the request log contains method, URL, and serviceId
        boolean hasRequestLog = infoLogs.stream()
                .anyMatch(event -> {
                    String msg = event.getFormattedMessage();
                    return msg.contains("GET")
                            && msg.contains("/services")
                            && msg.contains("serviceId");
                });
        assertTrue(hasRequestLog,
                "INFO log should contain HTTP method (GET), URL (/services), and serviceId");

        mockServer.verify();
    }

    @Test
    void infoLogs_containServiceIdForSpecificServer() {
        // Req 15.1: INFO logs include the specific serviceId
        String responseJson = """
            {
              "status": "success",
              "data": {
                "gameserver": {
                  "status": "started",
                  "ip": "1.2.3.4",
                  "port": 2302,
                  "query": {
                    "server_name": "Test",
                    "player_current": 5,
                    "player_max": 60,
                    "map": "chernarusplus",
                    "version": "1.25"
                  }
                }
              }
            }
            """;

        mockServer.expect(requestTo("/services/9876/gameservers"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON));

        client.getServerStatus(9876);

        boolean hasServiceIdLog = logAppender.list.stream()
                .filter(event -> event.getLevel() == Level.INFO)
                .anyMatch(event -> event.getFormattedMessage().contains("9876"));
        assertTrue(hasServiceIdLog,
                "INFO log should contain the specific serviceId (9876)");

        mockServer.verify();
    }

    // ── Req 15.2: ERROR logs contain response code, message, and serviceId ──

    @Test
    void errorLogs_containResponseCodeMessageAndServiceId() {
        // Req 15.2: ERROR logs contain response code, message, and serviceId
        mockServer.expect(requestTo("/services/4444/gameservers"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(MockRestResponseCreators.withResourceNotFound()
                        .body("{\"message\": \"Server not found\"}"));

        assertThrows(Exception.class, () -> client.getServerStatus(4444));

        List<ILoggingEvent> errorLogs = logAppender.list.stream()
                .filter(event -> event.getLevel() == Level.ERROR)
                .toList();

        assertFalse(errorLogs.isEmpty(), "Expected at least one ERROR log");

        boolean hasErrorDetails = errorLogs.stream()
                .anyMatch(event -> {
                    String msg = event.getFormattedMessage();
                    return msg.contains("404")
                            && msg.contains("Server not found")
                            && msg.contains("4444");
                });
        assertTrue(hasErrorDetails,
                "ERROR log should contain response code (404), message (Server not found), and serviceId (4444)");

        mockServer.verify();
    }

    @Test
    void errorLogs_containServiceIdOnAuthError() {
        // Req 15.2: ERROR logs for 401 errors include serviceId
        mockServer.expect(requestTo("/services/7777/gameservers"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withUnauthorizedRequest()
                        .body("{\"message\": \"Invalid token\"}"));

        assertThrows(Exception.class, () -> client.getServerStatus(7777));

        boolean hasErrorWithServiceId = logAppender.list.stream()
                .filter(event -> event.getLevel() == Level.ERROR)
                .anyMatch(event -> {
                    String msg = event.getFormattedMessage();
                    return msg.contains("401")
                            && msg.contains("7777");
                });
        assertTrue(hasErrorWithServiceId,
                "ERROR log should contain response code (401) and serviceId (7777)");

        mockServer.verify();
    }

    @Test
    void errorLogs_containServiceIdOnServerError() {
        // Req 15.2: ERROR logs for 5xx errors include serviceId
        mockServer.expect(requestTo("/services/3333/gameservers"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withServerError());

        assertThrows(Exception.class, () -> client.getServerStatus(3333));

        boolean hasServerErrorLog = logAppender.list.stream()
                .filter(event -> event.getLevel() == Level.ERROR)
                .anyMatch(event -> {
                    String msg = event.getFormattedMessage();
                    return msg.contains("500")
                            && msg.contains("3333");
                });
        assertTrue(hasServerErrorLog,
                "ERROR log should contain response code (500) and serviceId (3333)");

        mockServer.verify();
    }

    // ── Req 15.3: DEBUG logs contain response time in ms ──

    @Test
    void debugLogs_containResponseTimeInMs() {
        // Req 15.3: DEBUG logs contain response time in milliseconds
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

        client.getServers();

        List<ILoggingEvent> debugLogs = logAppender.list.stream()
                .filter(event -> event.getLevel() == Level.DEBUG)
                .toList();

        assertFalse(debugLogs.isEmpty(), "Expected at least one DEBUG log");

        boolean hasResponseTime = debugLogs.stream()
                .anyMatch(event -> {
                    String msg = event.getFormattedMessage();
                    return msg.contains("ms") && msg.contains("OK");
                });
        assertTrue(hasResponseTime,
                "DEBUG log should contain response time in ms (e.g., 'Response OK in Xms')");

        mockServer.verify();
    }

    @Test
    void debugLogs_containResponseTimeForDownloadFile() {
        // Req 15.3: DEBUG logs for downloadFile also contain response time
        String downloadTokenResponse = """
            {
              "status": "success",
              "data": {
                "token": {
                  "url": "https://temp-download.nitrado.net/test-file"
                }
              }
            }
            """;

        mockServer.expect(requestTo("/services/2222/gameservers/file_server/download?file=/test.txt"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(downloadTokenResponse, MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("https://temp-download.nitrado.net/test-file"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess("file content", MediaType.TEXT_PLAIN));

        client.downloadFile(2222, "/test.txt");

        List<ILoggingEvent> debugLogs = logAppender.list.stream()
                .filter(event -> event.getLevel() == Level.DEBUG)
                .toList();

        // Should have at least 2 DEBUG logs: one for the API call, one for the file download
        assertTrue(debugLogs.size() >= 2,
                "Expected at least 2 DEBUG logs (API call + file download), got " + debugLogs.size());

        boolean allContainMs = debugLogs.stream()
                .allMatch(event -> event.getFormattedMessage().contains("ms"));
        assertTrue(allContainMs,
                "All DEBUG logs should contain response time in ms");

        mockServer.verify();
    }

    // ── Req 14.4: Connection error on downloadFile step 2 ──

    @Test
    void downloadFile_connectionErrorOnTemporaryUrl_throwsNitradoConnectionException() {
        // Req 14.4: Connection error during step 2 of download also throws NitradoConnectionException
        String downloadTokenResponse = """
            {
              "status": "success",
              "data": {
                "token": {
                  "url": "https://temp-download.nitrado.net/unreachable"
                }
              }
            }
            """;

        mockServer.expect(requestTo("/services/6666/gameservers/file_server/download?file=/test.txt"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(downloadTokenResponse, MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("https://temp-download.nitrado.net/unreachable"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(request -> {
                    throw new ResourceAccessException(
                            "I/O error on GET request",
                            new SocketTimeoutException("Read timed out"));
                });

        NitradoConnectionException ex = assertThrows(NitradoConnectionException.class,
                () -> client.downloadFile(6666, "/test.txt"));

        assertTrue(ex.getMessage().contains("URL temporal"));
        mockServer.verify();
    }
}
