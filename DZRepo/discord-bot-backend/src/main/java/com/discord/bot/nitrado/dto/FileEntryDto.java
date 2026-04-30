package com.discord.bot.nitrado.dto;

/**
 * Represents a file or directory entry on the game server's file system.
 *
 * @param name the file or directory name
 * @param path the full path to the entry
 * @param type the entry type (e.g., "file", "dir")
 * @param size the file size in bytes, or null for directories
 */
public record FileEntryDto(
    String name,
    String path,
    String type,
    Long size
) {}
