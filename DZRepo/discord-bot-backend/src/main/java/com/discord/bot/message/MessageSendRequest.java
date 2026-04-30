package com.discord.bot.message;

import java.util.ArrayList;
import java.util.List;

/**
 * Represents a request to send a message to a Discord channel.
 * Provides utility to split content into chunks that respect Discord's character limit.
 *
 * @param channelId the target channel ID
 * @param content   the message content to send
 */
public record MessageSendRequest(
    String channelId,
    String content
) {

    /**
     * Splits the content into chunks of at most {@code maxLength} characters.
     * <ul>
     *   <li>For null or empty content, returns an empty list.</li>
     *   <li>Each chunk is at most {@code maxLength} characters.</li>
     *   <li>The concatenation of all chunks equals the original content.</li>
     *   <li>The number of chunks is {@code ceil(length / maxLength)} for non-empty strings.</li>
     * </ul>
     *
     * @param maxLength the maximum number of characters per chunk
     * @return an ordered list of content chunks
     */
    public List<String> splitContent(int maxLength) {
        if (content == null || content.isEmpty()) {
            return List.of();
        }

        List<String> chunks = new ArrayList<>();
        int length = content.length();
        int offset = 0;

        while (offset < length) {
            int end = Math.min(offset + maxLength, length);
            chunks.add(content.substring(offset, end));
            offset = end;
        }

        return chunks;
    }
}
