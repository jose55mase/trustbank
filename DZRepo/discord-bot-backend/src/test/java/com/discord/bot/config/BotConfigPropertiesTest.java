package com.discord.bot.config;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

class BotConfigPropertiesTest {

    private static Validator validator;

    @BeforeAll
    static void setUpValidator() {
        try (ValidatorFactory factory = Validation.buildDefaultValidatorFactory()) {
            validator = factory.getValidator();
        }
    }

    @Test
    void validTokenPassesValidation() {
        BotConfigProperties props = new BotConfigProperties();
        props.setToken("valid-bot-token");

        Set<ConstraintViolation<BotConfigProperties>> violations = validator.validate(props);
        assertTrue(violations.isEmpty());
    }

    @Test
    void nullTokenFailsValidation() {
        BotConfigProperties props = new BotConfigProperties();
        props.setToken(null);

        Set<ConstraintViolation<BotConfigProperties>> violations = validator.validate(props);
        assertFalse(violations.isEmpty());
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("token")));
    }

    @Test
    void blankTokenFailsValidation() {
        BotConfigProperties props = new BotConfigProperties();
        props.setToken("   ");

        Set<ConstraintViolation<BotConfigProperties>> violations = validator.validate(props);
        assertFalse(violations.isEmpty());
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("token")));
    }

    @Test
    void emptyTokenFailsValidation() {
        BotConfigProperties props = new BotConfigProperties();
        props.setToken("");

        Set<ConstraintViolation<BotConfigProperties>> violations = validator.validate(props);
        assertFalse(violations.isEmpty());
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("token")));
    }

    @Test
    void defaultLogPrefixIsDiscordBot() {
        BotConfigProperties props = new BotConfigProperties();
        assertEquals("discord-bot", props.getLogPrefix());
    }

    @Test
    void defaultMaxReconnectAttemptsIsFive() {
        BotConfigProperties props = new BotConfigProperties();
        assertEquals(5, props.getMaxReconnectAttempts());
    }

    @Test
    void defaultChannelIdIsNull() {
        BotConfigProperties props = new BotConfigProperties();
        assertNull(props.getDefaultChannelId());
    }

    @Test
    void settersAndGettersWork() {
        BotConfigProperties props = new BotConfigProperties();
        props.setToken("my-token");
        props.setDefaultChannelId("123456789");
        props.setLogPrefix("custom-prefix");
        props.setMaxReconnectAttempts(10);

        assertEquals("my-token", props.getToken());
        assertEquals("123456789", props.getDefaultChannelId());
        assertEquals("custom-prefix", props.getLogPrefix());
        assertEquals(10, props.getMaxReconnectAttempts());
    }
}
