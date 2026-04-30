package com.discord.bot.message;

import java.util.ArrayList;
import java.util.List;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.exceptions.InsufficientPermissionException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Sends messages to Discord channels via JDA.
 * Handles message splitting for content exceeding Discord's 2000 character limit,
 * validates inputs, and logs success/error outcomes.
 */
@Component
public class MessageSender {

    private static final Logger log = LoggerFactory.getLogger(MessageSender.class);
    static final int MAX_MESSAGE_LENGTH = 2000;

    /**
     * Sends a text message to the specified Discord channel.
     * If the content exceeds 2000 characters, it is split into consecutive chunks.
     * Logs success with channelId and messageId, or logs errors for missing channels
     * and insufficient permissions.
     *
     * @param jda       the JDA instance to use for sending
     * @param channelId the target channel ID
     * @param content   the message content to send
     */
    public void send(JDA jda, String channelId, String content) {
        if (content == null || content.isBlank()) {
            log.warn("Attempted to send empty or blank message to channelId={}", channelId);
            return;
        }

        TextChannel channel = jda.getTextChannelById(channelId);
        if (channel == null) {
            log.error("Channel not found: channelId={}", channelId);
            return;
        }

        List<String> chunks = splitContent(content, MAX_MESSAGE_LENGTH);

        for (String chunk : chunks) {
            try {
                channel.sendMessage(chunk).queue(
                        message -> log.info("Message sent successfully: channelId={}, messageId={}",
                                channelId, message.getId()),
                        failure -> log.error("Failed to send message: channelId={}, error={}",
                                channelId, failure.getMessage())
                );
            } catch (InsufficientPermissionException e) {
                log.error("Insufficient permissions to send message: channelId={}, permission={}",
                        channelId, e.getPermission());
                return;
            }
        }
    }

    /**
     * Splits content into chunks of at most maxLength characters.
     * The concatenation of all chunks equals the original content.
     *
     * @param content   the content to split
     * @param maxLength the maximum length per chunk
     * @return list of content chunks
     */
    static List<String> splitContent(String content, int maxLength) {
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
