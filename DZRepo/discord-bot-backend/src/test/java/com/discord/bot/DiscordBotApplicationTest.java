package com.discord.bot;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertNotNull;

class DiscordBotApplicationTest {

    @Test
    void mainClassExists() {
        DiscordBotApplication app = new DiscordBotApplication();
        assertNotNull(app);
    }
}
