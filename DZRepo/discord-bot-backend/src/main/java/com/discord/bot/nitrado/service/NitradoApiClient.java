package com.discord.bot.nitrado.service;

import com.discord.bot.nitrado.config.NitradoConfigProperties;
import com.discord.bot.nitrado.dto.BannedPlayerDto;
import com.discord.bot.nitrado.dto.FileEntryDto;
import com.discord.bot.nitrado.dto.GameServerDto;
import com.discord.bot.nitrado.dto.PlayerDto;
import com.discord.bot.nitrado.dto.ServerAction;
import com.discord.bot.nitrado.exception.NitradoApiException;
import com.discord.bot.nitrado.exception.NitradoAuthException;
import com.discord.bot.nitrado.exception.NitradoConnectionException;
import com.discord.bot.nitrado.exception.NitradoNotFoundException;
import com.discord.bot.nitrado.exception.NitradoServerException;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Central service that encapsulates all communication with the Nitrado API.
 * Handles authentication headers, error translation, and logging for every request.
 */
@Service
public class NitradoApiClient {

    private static final Logger log = LoggerFactory.getLogger(NitradoApiClient.class);

    private final RestTemplate restTemplate;
    private final NitradoConfigProperties config;
    private final ObjectMapper objectMapper;

    public NitradoApiClient(
            @Qualifier("nitradoRestTemplate") RestTemplate restTemplate,
            NitradoConfigProperties config) {
        this.restTemplate = restTemplate;
        this.config = config;
        this.objectMapper = new ObjectMapper();
    }

    // ── Server operations (to be implemented in task 3.2) ──

    /**
     * Retrieves all DayZ game servers from the Nitrado API.
     *
     * <p>Calls {@code GET /services}, filters services whose {@code details.game}
     * field contains "dayz" (case-insensitive), and maps each matching service
     * to a {@link GameServerDto}.
     *
     * @return a list of DayZ game servers, or an empty list if none are found
     */
    @SuppressWarnings("unchecked")
    public List<GameServerDto> getServers() {
        ResponseEntity<Map> response = execute(HttpMethod.GET, "/services", 0, null);

        Map<String, Object> body = response.getBody();
        if (body == null) {
            return Collections.emptyList();
        }

        Map<String, Object> data = (Map<String, Object>) body.get("data");
        if (data == null) {
            return Collections.emptyList();
        }

        List<Map<String, Object>> services = (List<Map<String, Object>>) data.get("services");
        if (services == null) {
            return Collections.emptyList();
        }

        List<GameServerDto> result = new ArrayList<>();
        for (Map<String, Object> service : services) {
            Map<String, Object> details = (Map<String, Object>) service.get("details");
            if (details == null) {
                continue;
            }

            String game = (String) details.get("game");
            if (game == null || !game.toLowerCase().contains("dayz")) {
                continue;
            }

            result.add(mapToGameServerDto(service, details));
        }

        return result;
    }

    /**
     * Retrieves the detailed status of a specific game server from the Nitrado API.
     *
     * <p>Calls {@code GET /services/{serviceId}/gameservers}, navigates through
     * {@code data.gameserver}, and maps the response fields to a {@link GameServerDto}.
     *
     * @param serviceId the Nitrado service ID
     * @return a GameServerDto with the server's detailed status
     * @throws NitradoNotFoundException if the service ID does not exist (404)
     */
    @SuppressWarnings("unchecked")
    public GameServerDto getServerStatus(int serviceId) {
        ResponseEntity<Map> response = execute(HttpMethod.GET, "/services/" + serviceId + "/gameservers", serviceId, null);

        Map<String, Object> body = response.getBody();
        if (body == null) {
            throw new NitradoNotFoundException("Servidor no encontrado: " + serviceId);
        }

        Map<String, Object> data = (Map<String, Object>) body.get("data");
        if (data == null) {
            throw new NitradoNotFoundException("Servidor no encontrado: " + serviceId);
        }

        Map<String, Object> gameserver = (Map<String, Object>) data.get("gameserver");
        if (gameserver == null) {
            throw new NitradoNotFoundException("Servidor no encontrado: " + serviceId);
        }

        return mapGameserverToDto(serviceId, gameserver);
    }

    /**
     * Executes a control action (start, stop, restart) on a game server.
     *
     * <p>For {@link ServerAction#START} and {@link ServerAction#RESTART}, sends a POST
     * to {@code /services/{serviceId}/gameservers/restart}. For {@link ServerAction#STOP},
     * sends a POST to {@code /services/{serviceId}/gameservers/stop}.
     *
     * @param serviceId the Nitrado service ID
     * @param action    the server action to perform
     */
    public void serverAction(int serviceId, ServerAction action) {
        String endpoint = switch (action) {
            case START, RESTART -> "/services/" + serviceId + "/gameservers/restart";
            case STOP -> "/services/" + serviceId + "/gameservers/stop";
        };
        execute(HttpMethod.POST, endpoint, serviceId, null);
    }

    // ── Player operations (to be implemented in tasks 4.1-4.4) ──

    /**
     * Retrieves the list of players currently connected to a game server.
     *
     * <p>Calls {@code GET /services/{serviceId}/gameservers/games/players},
     * navigates through {@code data.players}, and maps each player entry
     * to a {@link PlayerDto}.
     *
     * @param serviceId the Nitrado service ID
     * @return a list of connected players, or an empty list if none are connected
     */
    @SuppressWarnings("unchecked")
    public List<PlayerDto> getPlayers(int serviceId) {
        ResponseEntity<Map> response = execute(HttpMethod.GET,
                "/services/" + serviceId + "/gameservers/games/players", serviceId, null);

        Map<String, Object> body = response.getBody();
        if (body == null) {
            return Collections.emptyList();
        }

        Map<String, Object> data = (Map<String, Object>) body.get("data");
        if (data == null) {
            return Collections.emptyList();
        }

        List<Map<String, Object>> players = (List<Map<String, Object>>) data.get("players");
        if (players == null) {
            return Collections.emptyList();
        }

        List<PlayerDto> result = new ArrayList<>();
        for (Map<String, Object> player : players) {
            String id = player.get("id") instanceof String s ? s : "";
            String name = player.get("name") instanceof String s ? s : "";
            boolean online = player.get("online") instanceof Boolean b ? b : false;
            result.add(new PlayerDto(id, name, online));
        }

        return result;
    }

    /**
     * Kicks a player from a game server.
     *
     * <p>Sends a POST to {@code /services/{serviceId}/gameservers/games/players/kick}
     * with the {@code player_id} field in the request body.
     *
     * @param serviceId the Nitrado service ID
     * @param playerId  the ID of the player to kick
     */
    public void kickPlayer(int serviceId, String playerId) {
        Map<String, String> body = Map.of("player_id", playerId);
        execute(HttpMethod.POST, "/services/" + serviceId + "/gameservers/games/players/kick", serviceId, body);
    }

    /**
     * Bans a player from a game server with an optional reason.
     *
     * <p>Sends a POST to {@code /services/{serviceId}/gameservers/games/players/ban}
     * with the {@code player_id} field in the request body. If a non-null {@code reason}
     * is provided, it is also included in the body.
     *
     * @param serviceId the Nitrado service ID
     * @param playerId  the ID of the player to ban
     * @param reason    the reason for the ban, or null if no reason is provided
     */
    public void banPlayer(int serviceId, String playerId, String reason) {
        HashMap<String, String> body = new HashMap<>();
        body.put("player_id", playerId);
        if (reason != null) {
            body.put("reason", reason);
        }
        execute(HttpMethod.POST, "/services/" + serviceId + "/gameservers/games/players/ban", serviceId, body);
    }

    /**
     * Retrieves the list of banned players for a game server.
     *
     * <p>Calls {@code GET /services/{serviceId}/gameservers/games/banlist},
     * navigates through {@code data.banlist}, and maps each entry to a
     * {@link BannedPlayerDto}. The {@code banned_at} field is parsed as an
     * {@link Instant}; null or unparseable values result in a null {@code bannedAt}.
     *
     * @param serviceId the Nitrado service ID
     * @return a list of banned players, or an empty list if none are banned
     */
    @SuppressWarnings("unchecked")
    public List<BannedPlayerDto> getBanList(int serviceId) {
        ResponseEntity<Map> response = execute(HttpMethod.GET,
                "/services/" + serviceId + "/gameservers/games/banlist", serviceId, null);

        Map<String, Object> body = response.getBody();
        if (body == null) {
            return Collections.emptyList();
        }

        Map<String, Object> data = (Map<String, Object>) body.get("data");
        if (data == null) {
            return Collections.emptyList();
        }

        List<Map<String, Object>> banlist = (List<Map<String, Object>>) data.get("banlist");
        if (banlist == null) {
            return Collections.emptyList();
        }

        List<BannedPlayerDto> result = new ArrayList<>();
        for (Map<String, Object> entry : banlist) {
            String id = entry.get("id") instanceof String s ? s : "";
            String name = entry.get("name") instanceof String s ? s : "";
            String reason = entry.get("reason") instanceof String s ? s : null;
            Instant bannedAt = parseBannedAt(entry.get("banned_at"));
            result.add(new BannedPlayerDto(id, name, reason, bannedAt));
        }

        return result;
    }

    /**
     * Unbans a player from a game server.
     *
     * <p>Sends a DELETE to {@code /services/{serviceId}/gameservers/games/banlist}
     * with the {@code player_id} field in the request body.
     *
     * @param serviceId the Nitrado service ID
     * @param playerId  the ID of the player to unban
     */
    public void unbanPlayer(int serviceId, String playerId) {
        Map<String, String> body = Map.of("player_id", playerId);
        execute(HttpMethod.DELETE, "/services/" + serviceId + "/gameservers/games/banlist", serviceId, body);
    }

    // ── File operations (to be implemented in tasks 6.1-6.3) ──

    /**
     * Lists files and directories at the specified path on a game server.
     *
     * <p>Calls {@code GET /services/{serviceId}/gameservers/file_server/list}
     * with the {@code dir} query parameter, navigates through {@code data.entries},
     * and maps each entry to a {@link FileEntryDto}.
     *
     * @param serviceId the Nitrado service ID
     * @param path      the directory path to list (e.g., "/" or "/games")
     * @return a list of file and directory entries, or an empty list if none are found
     */
    @SuppressWarnings("unchecked")
    public List<FileEntryDto> listFiles(int serviceId, String path) {
        String url = "/services/" + serviceId + "/gameservers/file_server/list?dir=" + path;
        ResponseEntity<Map> response = execute(HttpMethod.GET, url, serviceId, null);

        Map<String, Object> body = response.getBody();
        log.info("[NitradoClient] listFiles response body for path='{}': {}", path, body);
        if (body == null) {
            return Collections.emptyList();
        }

        Map<String, Object> data = (Map<String, Object>) body.get("data");
        if (data == null) {
            log.warn("[NitradoClient] listFiles: 'data' key is null. Body keys: {}", body.keySet());
            return Collections.emptyList();
        }

        List<Map<String, Object>> entries = (List<Map<String, Object>>) data.get("entries");
        if (entries == null) {
            log.warn("[NitradoClient] listFiles: 'entries' key is null. Data keys: {}", data.keySet());
            return Collections.emptyList();
        }

        List<FileEntryDto> result = new ArrayList<>();
        for (Map<String, Object> entry : entries) {
            String name = entry.get("name") instanceof String s ? s : "";
            String entryPath = entry.get("path") instanceof String s ? s : "";
            String type = entry.get("type") instanceof String s ? s : "";
            Long size = entry.get("size") instanceof Number n ? n.longValue() : null;
            result.add(new FileEntryDto(name, entryPath, type, size));
        }

        return result;
    }

    /**
     * Downloads a file from a game server using Nitrado's two-step download process.
     *
     * <p>Step 1: Calls {@code GET /services/{serviceId}/gameservers/file_server/download?file={filePath}}
     * to obtain a temporary download URL from the Nitrado API.
     * <p>Step 2: Downloads the actual file content from the temporary URL (no auth headers needed).
     *
     * @param serviceId the Nitrado service ID
     * @param filePath  the path of the file to download on the server
     * @return the file content as a String
     * @throws NitradoApiException if the temporary download URL is not found in the response
     *                             or if the download from the temporary URL fails
     */
    @SuppressWarnings("unchecked")
    public String downloadFile(int serviceId, String filePath) {
        // Step 1: Get temporary download URL
        String url = "/services/" + serviceId + "/gameservers/file_server/download?file=" + filePath;
        ResponseEntity<Map> response = execute(HttpMethod.GET, url, serviceId, null);

        Map<String, Object> body = response.getBody();
        if (body == null) {
            throw new NitradoApiException("No se recibió respuesta al solicitar URL de descarga", 500);
        }

        Map<String, Object> data = (Map<String, Object>) body.get("data");
        if (data == null) {
            throw new NitradoApiException("Respuesta de descarga sin campo 'data'", 500);
        }

        Map<String, Object> token = (Map<String, Object>) data.get("token");
        if (token == null) {
            throw new NitradoApiException("Respuesta de descarga sin campo 'token'", 500);
        }

        String temporaryUrl = token.get("url") instanceof String s ? s : null;
        if (temporaryUrl == null || temporaryUrl.isBlank()) {
            throw new NitradoApiException("URL temporal de descarga no encontrada en la respuesta", 500);
        }

        // Step 2: Download actual file content from temporary URL
        try {
            log.info("[NitradoClient] Downloading file from temporary URL (serviceId={})", serviceId);
            long startTime = System.currentTimeMillis();

            String content = restTemplate.getForObject(temporaryUrl, String.class);

            long elapsed = System.currentTimeMillis() - startTime;
            log.debug("[NitradoClient] File downloaded in {}ms", elapsed);

            return content;
        } catch (ResourceAccessException e) {
            log.error("[NitradoClient] Error downloading file from temporary URL (serviceId={}): {}",
                    serviceId, e.getMessage());
            throw new NitradoConnectionException(
                    "No se pudo descargar el archivo desde la URL temporal", e);
        } catch (HttpClientErrorException e) {
            int status = e.getStatusCode().value();
            log.error("[NitradoClient] Error {}: downloading file from temporary URL (serviceId={})",
                    status, serviceId);
            throw new NitradoApiException("Error al descargar archivo desde URL temporal", status);
        } catch (HttpServerErrorException e) {
            int status = e.getStatusCode().value();
            log.error("[NitradoClient] Error {}: downloading file from temporary URL (serviceId={})",
                    status, serviceId);
            throw new NitradoServerException(
                    "Error del servidor al descargar archivo desde URL temporal", status);
        }
    }

    /**
     * Uploads a file to a game server via the Nitrado API.
     *
     * <p>Sends a POST to {@code /services/{serviceId}/gameservers/file_server/upload?path={filePath}}
     * with the file content as the request body using {@code Content-Type: application/octet-stream}.
     *
     * @param serviceId the Nitrado service ID
     * @param filePath  the destination path on the server (e.g., "/games/dayz/config.cfg")
     * @param content   the file content to upload
     */
    public void uploadFile(int serviceId, String filePath, String content) {
        String url = "/services/" + serviceId + "/gameservers/file_server/upload?path=" + filePath;
        log.info("[NitradoClient] POST {} (serviceId={})", url, serviceId);
        long startTime = System.currentTimeMillis();

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(config.getApiToken());
            headers.set(HttpHeaders.CONTENT_TYPE, "application/octet-stream");

            HttpEntity<String> entity = new HttpEntity<>(content, headers);

            restTemplate.exchange(url, HttpMethod.POST, entity, Map.class);

            long elapsed = System.currentTimeMillis() - startTime;
            log.debug("[NitradoClient] Response OK in {}ms", elapsed);
        } catch (HttpClientErrorException e) {
            int status = e.getStatusCode().value();
            String message = extractMessage(e.getResponseBodyAsString());

            log.error("[NitradoClient] Error {}: {} (serviceId={})", status, message, serviceId);

            if (status == 401 || status == 403) {
                throw new NitradoAuthException(message != null ? message : "Token inválido o expirado");
            }
            if (status == 404) {
                throw new NitradoNotFoundException(message != null ? message : "Recurso no encontrado");
            }
            throw new NitradoApiException(message != null ? message : "Error en la solicitud", status);
        } catch (HttpServerErrorException e) {
            int status = e.getStatusCode().value();

            log.error("[NitradoClient] Error {}: Servicio de Nitrado no disponible temporalmente (serviceId={})",
                    status, serviceId);

            throw new NitradoServerException(
                    "Servicio de Nitrado no disponible temporalmente", status);
        } catch (ResourceAccessException e) {
            log.error("[NitradoClient] Error de conexión: {} (serviceId={})", e.getMessage(), serviceId);

            throw new NitradoConnectionException(
                    "No se pudo contactar con el servicio de Nitrado", e);
        }
    }

    // ── Log operations ──

    /**
     * Downloads the server log file from a DayZ game server.
     *
     * <p>The method follows this strategy to locate the log file:
     * <ol>
     *   <li>Lists files in {@code /games} to find the DayZ folder (a directory whose name
     *       contains "dayz", case-insensitive).</li>
     *   <li>If found, downloads the log from {@code {dayzFolder}/logs/server_log.ADM}.</li>
     *   <li>If no DayZ folder is found (Req 13.3), falls back to the path
     *       {@code /games/ni{serviceId}_dayz/logs/server_log.ADM}.</li>
     * </ol>
     *
     * @param serviceId the Nitrado service ID
     * @return the log file content as a String
     * @throws NitradoNotFoundException if the log file does not exist (Req 13.4)
     */
    @SuppressWarnings("unchecked")
    public String getServerLogs(int serviceId) {
        // Step 1: List files in /games to find the DayZ folder
        List<FileEntryDto> entries = listFiles(serviceId, "/games");

        // Step 2: Find a directory whose name contains "dayz" (case-insensitive)
        String logPath = null;
        for (FileEntryDto entry : entries) {
            if ("dir".equalsIgnoreCase(entry.type())
                    && entry.name() != null
                    && entry.name().toLowerCase().contains("dayz")) {
                logPath = entry.path() + "/logs/server_log.ADM";
                break;
            }
        }

        // Step 3: If file server has entries with a DayZ folder, download from there (PC servers)
        if (logPath != null) {
            try {
                return downloadFile(serviceId, logPath);
            } catch (NitradoNotFoundException e) {
                throw new NitradoNotFoundException(
                        "Archivo de log no encontrado: " + logPath + " (serviceId=" + serviceId + ")");
            }
        }

        // Step 4: File server empty (console servers like Xbox/PS)
        // Xbox path structure: /games/{folderId}/noftp/dayzxb/config/DayZServer_X1_x64.ADM
        // The folderId (e.g. "ni9508869_1") comes from the gameservers endpoint
        log.info("[NitradoClient] No DayZ folder found via file listing, trying Xbox/PS console paths (serviceId={})", serviceId);

        // First, try the configured folder ID (from application properties)
        String configuredFolderId = config.getGameServerFolderId();

        // Then try to get it dynamically from the gameservers endpoint
        String folderId = (configuredFolderId != null && !configuredFolderId.isBlank())
                ? configuredFolderId
                : getGameServerFolderId(serviceId);
        log.info("[NitradoClient] Resolved folderId: {} (serviceId={})", folderId, serviceId);

        // Build paths to try - with folderId first, then fallbacks
        java.util.List<String> paths = new java.util.ArrayList<>();
        if (folderId != null && !folderId.isBlank()) {
            // For Xbox/PS, ADM files have timestamps in their names (e.g. DayZServer_X1_x64_2026-05-11_20-12-39.ADM)
            // We need to list the config directory and find the most recent .ADM file
            String configDir = "/games/" + folderId + "/noftp/dayzxb/config";
            String admFile = findMostRecentAdmFile(serviceId, configDir);
            if (admFile != null) {
                paths.add(admFile);
            }
            // Also try the static name as fallback
            paths.add(configDir + "/DayZServer_X1_x64.ADM");

            // Try PS path too
            String psConfigDir = "/games/" + folderId + "/noftp/dayzps/config";
            String psAdmFile = findMostRecentAdmFile(serviceId, psConfigDir);
            if (psAdmFile != null) {
                paths.add(psAdmFile);
            }
        }

        for (String path : paths) {
            try {
                log.info("[NitradoClient] Trying console path: {} (serviceId={})", path, serviceId);
                String content = downloadFile(serviceId, path);
                if (content != null && !content.isBlank()) {
                    log.info("[NitradoClient] Found logs at: {} (serviceId={})", path, serviceId);
                    return content;
                }
            } catch (NitradoNotFoundException e) {
                log.debug("[NitradoClient] Path not found: {} (serviceId={})", path, serviceId);
            } catch (Exception e) {
                log.info("[NitradoClient] Error trying path {}: {} (serviceId={})", path, e.getMessage(), serviceId);
            }
        }

        throw new NitradoNotFoundException(
                "Logs no disponibles para este servidor de consola (serviceId=" + serviceId + "). " +
                "Ningún path de log conocido fue encontrado.");
    }

    /**
     * Lists files in a directory and finds the most recent .ADM file by name.
     * Xbox/PS DayZ servers create timestamped ADM files like: DayZServer_X1_x64_2026-05-11_20-12-39.ADM
     *
     * @param serviceId the Nitrado service ID
     * @param configDir the directory path to search
     * @return the full path to the most recent .ADM file, or null if none found
     */
    private String findMostRecentAdmFile(int serviceId, String configDir) {
        try {
            List<FileEntryDto> files = listFiles(serviceId, configDir);
            String mostRecentName = null;
            String mostRecentPath = null;

            for (FileEntryDto file : files) {
                if ("file".equalsIgnoreCase(file.type())
                        && file.name() != null
                        && file.name().toUpperCase().endsWith(".ADM")) {
                    // Pick the one with the latest name (timestamps sort lexicographically)
                    if (mostRecentName == null || file.name().compareTo(mostRecentName) > 0) {
                        mostRecentName = file.name();
                        mostRecentPath = file.path();
                    }
                }
            }

            if (mostRecentPath != null) {
                log.info("[NitradoClient] Found most recent ADM file: {} (serviceId={})", mostRecentPath, serviceId);
            } else {
                log.info("[NitradoClient] No .ADM files found in {} (serviceId={})", configDir, serviceId);
            }

            return mostRecentPath;
        } catch (Exception e) {
            log.debug("[NitradoClient] Error listing files in {}: {} (serviceId={})", configDir, e.getMessage(), serviceId);
            return null;
        }
    }

    /**
     * Gets the game server folder ID (e.g. "ni9508869_1") from the gameservers endpoint.
     * This is needed to construct file paths for console servers.
     */
    @SuppressWarnings("unchecked")
    private String getGameServerFolderId(int serviceId) {
        try {
            ResponseEntity<Map> response = execute(HttpMethod.GET,
                    "/services/" + serviceId + "/gameservers", serviceId, null);

            Map<String, Object> body = response.getBody();
            if (body == null) return null;

            Map<String, Object> data = (Map<String, Object>) body.get("data");
            if (data == null) return null;

            Map<String, Object> gameserver = (Map<String, Object>) data.get("gameserver");
            if (gameserver == null) return null;

            // Log all keys for debugging
            log.info("[NitradoClient] Gameserver response keys: {} (serviceId={})", gameserver.keySet(), serviceId);

            // The folder ID is typically in "folder_short" or can be derived from "id"
            // Common patterns: "ni{number}_{number}" like "ni9508869_1"
            Object folderShort = gameserver.get("folder_short");
            if (folderShort != null && !folderShort.toString().isBlank()) {
                return folderShort.toString();
            }

            // Try "game_specific.path" or similar nested fields
            Object gameSpecific = gameserver.get("game_specific");
            if (gameSpecific instanceof Map<?, ?> gsMap) {
                Object gsPath = gsMap.get("path");
                if (gsPath != null) return gsPath.toString();
            }

            return null;
        } catch (Exception e) {
            log.warn("[NitradoClient] Could not get folder ID: {} (serviceId={})", e.getMessage(), serviceId);
            return null;
        }
    }

    // ── Private mapping helpers ──

    /**
     * Parses the {@code banned_at} field from a Nitrado API response into an {@link Instant}.
     *
     * @param value the raw value from the JSON response (expected to be a String in ISO-8601 format)
     * @return the parsed Instant, or null if the value is null, not a String, or cannot be parsed
     */
    private Instant parseBannedAt(Object value) {
        if (!(value instanceof String s) || s.isBlank()) {
            return null;
        }
        try {
            return Instant.parse(s);
        } catch (DateTimeParseException e) {
            log.debug("[NitradoClient] Could not parse banned_at value: {}", s);
            return null;
        }
    }

    /**
     * Maps a Nitrado service object to a {@link GameServerDto}.
     *
     * @param service the raw service map from the Nitrado API
     * @param details the {@code details} sub-map of the service
     * @return a populated GameServerDto
     */
    @SuppressWarnings("unchecked")
    private GameServerDto mapToGameServerDto(Map<String, Object> service, Map<String, Object> details) {
        int id = service.get("id") instanceof Number n ? n.intValue() : 0;
        String name = details.get("name") instanceof String s ? s : "";
        String ip = details.get("address") instanceof String s ? s : "";
        int port = details.get("port") instanceof Number n ? n.intValue() : 0;
        String status = service.get("status") instanceof String s ? s : "unknown";
        int currentPlayers = details.get("players_current") instanceof Number n ? n.intValue() : 0;
        int maxPlayers = details.get("players_max") instanceof Number n ? n.intValue() : 0;
        String map = details.get("map") instanceof String s ? s : "";
        String gameVersion = details.get("version") instanceof String s ? s : "";

        return new GameServerDto(id, name, ip, port, status, currentPlayers, maxPlayers, map, gameVersion);
    }

    /**
     * Maps a Nitrado gameserver detail object (from {@code /services/{id}/gameservers})
     * to a {@link GameServerDto}.
     *
     * <p>Uses the {@code query} sub-object for player counts, server name, map, and version,
     * following the same field mapping as the Dart implementation.
     *
     * @param serviceId the Nitrado service ID
     * @param gameserver the {@code data.gameserver} map from the Nitrado API
     * @return a populated GameServerDto
     */
    @SuppressWarnings("unchecked")
    private GameServerDto mapGameserverToDto(int serviceId, Map<String, Object> gameserver) {
        Map<String, Object> query = gameserver.get("query") instanceof Map<?, ?> m
                ? (Map<String, Object>) m : Collections.emptyMap();

        String name = query.get("server_name") instanceof String s ? s : "";
        String ip = gameserver.get("ip") instanceof String s ? s : "";
        int port = gameserver.get("port") instanceof Number n ? n.intValue() : 0;
        String status = gameserver.get("status") instanceof String s ? s : "unknown";
        int currentPlayers = query.get("player_current") instanceof Number n ? n.intValue() : 0;
        int maxPlayers = query.get("player_max") instanceof Number n ? n.intValue() : 0;
        String map = query.get("map") instanceof String s ? s : "";
        String gameVersion = query.get("version") instanceof String s ? s : "";

        return new GameServerDto(serviceId, name, ip, port, status, currentPlayers, maxPlayers, map, gameVersion);
    }

    // ── Infrastructure: execute helper, headers, error handling, logging ──

    /**
     * Executes an HTTP request against the Nitrado API with authentication,
     * error handling, and logging.
     *
     * @param method    the HTTP method (GET, POST, DELETE, etc.)
     * @param url       the relative URL path (e.g., "/services")
     * @param serviceId the service ID for logging context (use 0 for non-service requests)
     * @param body      the request body, or null for bodyless requests
     * @return the response entity with the parsed Map body
     */
    protected ResponseEntity<Map> execute(HttpMethod method, String url, int serviceId, Object body) {
        log.info("[NitradoClient] {} {} (serviceId={})", method, url, serviceId);
        long startTime = System.currentTimeMillis();

        try {
            HttpEntity<?> entity = (body != null)
                    ? new HttpEntity<>(body, buildHeaders())
                    : new HttpEntity<>(buildHeaders());

            ResponseEntity<Map> response = restTemplate.exchange(url, method, entity, Map.class);

            long elapsed = System.currentTimeMillis() - startTime;
            log.debug("[NitradoClient] Response OK in {}ms", elapsed);

            return response;
        } catch (HttpClientErrorException e) {
            int status = e.getStatusCode().value();
            String message = extractMessage(e.getResponseBodyAsString());

            log.error("[NitradoClient] Error {}: {} (serviceId={})", status, message, serviceId);

            if (status == 401 || status == 403) {
                throw new NitradoAuthException(message != null ? message : "Token inválido o expirado");
            }
            if (status == 404) {
                throw new NitradoNotFoundException(message != null ? message : "Recurso no encontrado");
            }
            throw new NitradoApiException(message != null ? message : "Error en la solicitud", status);
        } catch (HttpServerErrorException e) {
            int status = e.getStatusCode().value();

            log.error("[NitradoClient] Error {}: Servicio de Nitrado no disponible temporalmente (serviceId={})",
                    status, serviceId);

            throw new NitradoServerException(
                    "Servicio de Nitrado no disponible temporalmente", status);
        } catch (ResourceAccessException e) {
            log.error("[NitradoClient] Error de conexión: {} (serviceId={})", e.getMessage(), serviceId);

            throw new NitradoConnectionException(
                    "No se pudo contactar con el servicio de Nitrado", e);
        }
    }

    /**
     * Builds HTTP headers with the Bearer token for Nitrado API authentication.
     *
     * @return HttpHeaders with Authorization header set
     */
    private HttpHeaders buildHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(config.getApiToken());
        return headers;
    }

    /**
     * Extracts the error message from a Nitrado API error response body.
     * The Nitrado API returns errors as {@code {"message": "..."}}.
     *
     * @param responseBody the raw JSON response body
     * @return the extracted message, or null if parsing fails
     */
    private String extractMessage(String responseBody) {
        if (responseBody == null || responseBody.isBlank()) {
            return null;
        }
        try {
            JsonNode node = objectMapper.readTree(responseBody);
            JsonNode messageNode = node.get("message");
            if (messageNode != null && !messageNode.isNull()) {
                return messageNode.asText();
            }
            return null;
        } catch (JsonProcessingException e) {
            log.debug("[NitradoClient] Could not parse error response body: {}", responseBody);
            return null;
        }
    }
}
