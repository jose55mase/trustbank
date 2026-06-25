package com.discord.bot.shop.service;

import com.discord.bot.nitrado.service.NitradoApiClient;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.List;

/**
 * Service that maintains a local cache of server logs, appending only new lines
 * on each poll cycle. This ensures player position data is never lost when the
 * DayZ server restarts and its log file resets.
 *
 * <p>Works like a "tail -f" that persists across server restarts:
 * <ul>
 *   <li>Downloads the current server log every 2 minutes</li>
 *   <li>Compares with previously seen content to find new lines</li>
 *   <li>Appends only the new lines to a local cache file</li>
 *   <li>If the server log is shorter than before (restart detected), treats all content as new</li>
 * </ul>
 */
@Service
public class LogCacheService {

    private static final Logger log = LoggerFactory.getLogger(LogCacheService.class);

    private final NitradoApiClient nitradoApiClient;

    @Value("${shop.nitrado.service-id:0}")
    private int serviceId;

    @Value("${shop.log-cache.file-path:./data/server-log-cache.txt}")
    private String cacheFilePath;

    @Value("${shop.log-cache.max-lines:50000}")
    private int maxLines;

    /** The last known content from the server log (to detect new lines) */
    private String lastKnownContent = "";

    /** The last line count we saw from the server */
    private int lastLineCount = 0;

    public LogCacheService(NitradoApiClient nitradoApiClient) {
        this.nitradoApiClient = nitradoApiClient;
    }

    /**
     * Polls the server log every 2 minutes and appends new lines to the cache.
     */
    @Scheduled(fixedRate = 120000, initialDelay = 10000)
    public void pollAndCache() {
        if (serviceId <= 0) {
            return;
        }

        try {
            String currentLog = nitradoApiClient.getServerLogs(serviceId);
            if (currentLog == null || currentLog.isBlank()) {
                return;
            }

            String[] currentLines = currentLog.split("\\r?\\n");
            int currentLineCount = currentLines.length;

            // Detect server restart: if current log is shorter than what we had before
            if (currentLineCount < lastLineCount) {
                log.info("[LogCache] Server log reset detected (was {} lines, now {}). Treating all as new.",
                        lastLineCount, currentLineCount);
                appendToCache(currentLog);
                lastLineCount = currentLineCount;
                lastKnownContent = currentLog;
                return;
            }

            // Find new lines (everything after what we already saw)
            if (lastKnownContent.isEmpty()) {
                // First run — cache everything
                appendToCache(currentLog);
                log.info("[LogCache] Initial cache populated with {} lines.", currentLineCount);
            } else if (currentLineCount > lastLineCount) {
                // New lines appended — extract only the new ones
                String[] newLines = new String[currentLineCount - lastLineCount];
                System.arraycopy(currentLines, lastLineCount, newLines, 0, newLines.length);
                String newContent = String.join("\n", newLines);
                appendToCache(newContent);
                log.debug("[LogCache] Appended {} new lines to cache.", newLines.length);
            }

            lastLineCount = currentLineCount;
            lastKnownContent = currentLog;

        } catch (Exception e) {
            log.warn("[LogCache] Failed to poll server logs: {}", e.getMessage());
        }
    }

    /**
     * Returns the full cached log content for position lookups.
     *
     * @return the accumulated log content, or empty string if cache doesn't exist
     */
    public String getCachedLog() {
        Path path = Path.of(cacheFilePath);
        if (!Files.exists(path)) {
            return "";
        }

        try {
            return Files.readString(path, StandardCharsets.UTF_8);
        } catch (IOException e) {
            log.error("[LogCache] Failed to read cache file: {}", e.getMessage());
            return "";
        }
    }

    /**
     * Appends content to the cache file. Creates the file and parent directories if needed.
     * If the cache exceeds maxLines, trims the oldest lines.
     */
    private void appendToCache(String content) {
        if (content == null || content.isBlank()) {
            return;
        }

        try {
            Path path = Path.of(cacheFilePath);
            Files.createDirectories(path.getParent());

            // Append new content
            Files.writeString(path, content + "\n",
                    StandardCharsets.UTF_8,
                    StandardOpenOption.CREATE,
                    StandardOpenOption.APPEND);

            // Trim if too large
            trimCache(path);

        } catch (IOException e) {
            log.error("[LogCache] Failed to write to cache file: {}", e.getMessage());
        }
    }

    /**
     * Trims the cache file to keep only the last maxLines lines.
     */
    private void trimCache(Path path) {
        try {
            List<String> allLines = Files.readAllLines(path, StandardCharsets.UTF_8);
            if (allLines.size() > maxLines) {
                // Keep only the last maxLines
                List<String> trimmed = allLines.subList(allLines.size() - maxLines, allLines.size());
                Files.write(path, trimmed, StandardCharsets.UTF_8);
                log.info("[LogCache] Trimmed cache from {} to {} lines.", allLines.size(), maxLines);
            }
        } catch (IOException e) {
            log.warn("[LogCache] Failed to trim cache: {}", e.getMessage());
        }
    }
}
