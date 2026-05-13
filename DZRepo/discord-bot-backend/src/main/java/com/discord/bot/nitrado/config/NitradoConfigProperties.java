package com.discord.bot.nitrado.config;

import jakarta.validation.constraints.NotBlank;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@ConfigurationProperties(prefix = "nitrado")
@Validated
public class NitradoConfigProperties {

    @NotBlank(message = "nitrado.api-token must not be blank")
    private String apiToken;

    private String baseUrl = "https://api.nitrado.net";

    private int connectTimeoutMs = 10_000;

    private int readTimeoutMs = 10_000;

    /**
     * The game server folder ID used for constructing file paths on console servers (Xbox/PS).
     * Format: "ni{number}_{number}" (e.g., "ni11126176_1").
     * Required for downloading logs from Xbox/PlayStation DayZ servers.
     */
    private String gameServerFolderId;

    public String getApiToken() {
        return apiToken;
    }

    public void setApiToken(String apiToken) {
        this.apiToken = apiToken;
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    public int getConnectTimeoutMs() {
        return connectTimeoutMs;
    }

    public void setConnectTimeoutMs(int connectTimeoutMs) {
        this.connectTimeoutMs = connectTimeoutMs;
    }

    public int getReadTimeoutMs() {
        return readTimeoutMs;
    }

    public void setReadTimeoutMs(int readTimeoutMs) {
        this.readTimeoutMs = readTimeoutMs;
    }

    public String getGameServerFolderId() {
        return gameServerFolderId;
    }

    public void setGameServerFolderId(String gameServerFolderId) {
        this.gameServerFolderId = gameServerFolderId;
    }
}
