package com.discord.bot.message;

import java.util.List;

import net.jqwik.api.*;

import static org.assertj.core.api.Assertions.assertThat;

// Feature: discord-bot-backend, Property 6: División de mensajes preserva contenido
class MessageSplitPropertyTest {

    private static final int MAX_LENGTH = 2000;

    /**
     * Property 6: For any text string, when split into chunks for Discord:
     * (a) each chunk SHALL have length <= 2000 chars,
     * (b) concatenation of all chunks SHALL equal the original string,
     * (c) chunk count SHALL be ceil(length/2000) for non-empty strings.
     *
     * For empty strings, the result should be an empty list.
     *
     * **Validates: Requirements 5.3**
     */
    @Property(tries = 100)
    void splitContentPreservesContent(@ForAll("contentStrings") String content) {
        List<String> chunks = MessageSender.splitContent(content, MAX_LENGTH);

        if (content.isEmpty()) {
            assertThat(chunks).isEmpty();
            return;
        }

        // (a) Each chunk has length <= 2000
        for (String chunk : chunks) {
            assertThat(chunk.length())
                    .as("Each chunk must be at most %d characters", MAX_LENGTH)
                    .isLessThanOrEqualTo(MAX_LENGTH);
        }

        // (b) Concatenation of all chunks equals the original string
        String concatenated = String.join("", chunks);
        assertThat(concatenated)
                .as("Concatenation of chunks must equal the original content")
                .isEqualTo(content);

        // (c) Chunk count equals ceil(length / 2000)
        int expectedChunks = (int) Math.ceil((double) content.length() / MAX_LENGTH);
        assertThat(chunks.size())
                .as("Chunk count must be ceil(length / %d)", MAX_LENGTH)
                .isEqualTo(expectedChunks);
    }

    /**
     * Provides random strings of 0-10000 characters for testing message splitting.
     * Uses the full printable ASCII range plus some Unicode to exercise the splitter.
     */
    @Provide
    Arbitrary<String> contentStrings() {
        return Arbitraries.strings()
                .all()
                .ofMinLength(0)
                .ofMaxLength(10000);
    }
}
