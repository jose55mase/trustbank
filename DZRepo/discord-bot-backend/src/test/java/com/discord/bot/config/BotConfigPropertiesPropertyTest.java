package com.discord.bot.config;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import net.jqwik.api.*;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

// Feature: discord-bot-backend, Property 1: Validación de configuración obligatoria
class BotConfigPropertiesPropertyTest {

    private static final Validator validator;

    static {
        try (ValidatorFactory factory = Validation.buildDefaultValidatorFactory()) {
            validator = factory.getValidator();
        }
    }

    /**
     * Property 1: For any mandatory configuration parameter (token, etc.),
     * if that parameter is absent, empty, or contains only whitespace,
     * the system SHALL log a descriptive error including the parameter name
     * and terminate execution in a controlled manner.
     *
     * This test generates random blank/empty/whitespace-only strings and verifies
     * that Jakarta Validation produces constraint violations on the token field
     * with a descriptive message that includes the parameter name.
     *
     * Validates: Requirements 1.3, 8.3
     */
    @Property(tries = 100)
    void blankOrWhitespaceTokenProducesDescriptiveValidationError(
            @ForAll("blankOrWhitespaceStrings") String invalidToken) {

        BotConfigProperties props = new BotConfigProperties();
        props.setToken(invalidToken);

        Set<ConstraintViolation<BotConfigProperties>> violations = validator.validate(props);

        // Must produce at least one violation
        assertFalse(violations.isEmpty(),
                "Expected validation violations for token value: [" + invalidToken + "]");

        // At least one violation must be on the 'token' property path
        boolean hasTokenViolation = violations.stream()
                .anyMatch(v -> v.getPropertyPath().toString().equals("token"));
        assertTrue(hasTokenViolation,
                "Expected a violation on 'token' field for value: [" + invalidToken + "]");

        // The violation message must be descriptive and include the parameter name
        boolean hasDescriptiveMessage = violations.stream()
                .filter(v -> v.getPropertyPath().toString().equals("token"))
                .anyMatch(v -> v.getMessage() != null
                        && !v.getMessage().isBlank()
                        && v.getMessage().contains("token"));
        assertTrue(hasDescriptiveMessage,
                "Expected violation message to include parameter name 'token', but got: "
                        + violations.stream()
                        .filter(v -> v.getPropertyPath().toString().equals("token"))
                        .map(ConstraintViolation::getMessage)
                        .toList());
    }

    /**
     * Property 1 (null case): When the mandatory token parameter is null,
     * the system SHALL produce a descriptive validation error including the parameter name.
     *
     * Validates: Requirements 1.3, 8.3
     */
    @Property(tries = 100)
    void nullTokenProducesDescriptiveValidationError(
            @ForAll("nullProvider") String nullToken) {

        BotConfigProperties props = new BotConfigProperties();
        props.setToken(nullToken);

        Set<ConstraintViolation<BotConfigProperties>> violations = validator.validate(props);

        assertFalse(violations.isEmpty(),
                "Expected validation violations for null token");

        boolean hasTokenViolation = violations.stream()
                .anyMatch(v -> v.getPropertyPath().toString().equals("token"));
        assertTrue(hasTokenViolation,
                "Expected a violation on 'token' field for null value");

        boolean hasDescriptiveMessage = violations.stream()
                .filter(v -> v.getPropertyPath().toString().equals("token"))
                .anyMatch(v -> v.getMessage() != null && !v.getMessage().isBlank());
        assertTrue(hasDescriptiveMessage,
                "Expected a non-blank violation message for null token");
    }

    /**
     * Provides random blank or whitespace-only strings.
     * Generates: empty strings, strings of spaces, tabs, newlines, and mixed whitespace.
     */
    @Provide
    Arbitrary<String> blankOrWhitespaceStrings() {
        return Arbitraries.oneOf(
                // Empty string
                Arbitraries.just(""),
                // Strings of only spaces (1 to 20 spaces)
                Arbitraries.integers().between(1, 20)
                        .map(n -> " ".repeat(n)),
                // Strings of only tabs (1 to 10 tabs)
                Arbitraries.integers().between(1, 10)
                        .map(n -> "\t".repeat(n)),
                // Strings of only newlines (1 to 5 newlines)
                Arbitraries.integers().between(1, 5)
                        .map(n -> "\n".repeat(n)),
                // Mixed whitespace characters
                Arbitraries.integers().between(1, 15).flatMap(length ->
                        Arbitraries.of(' ', '\t', '\n', '\r')
                                .list().ofSize(length)
                                .map(chars -> {
                                    StringBuilder sb = new StringBuilder();
                                    chars.forEach(sb::append);
                                    return sb.toString();
                                })
                )
        );
    }

    /**
     * Provides null values for the null token test case.
     */
    @Provide
    Arbitrary<String> nullProvider() {
        return Arbitraries.just(null);
    }
}
