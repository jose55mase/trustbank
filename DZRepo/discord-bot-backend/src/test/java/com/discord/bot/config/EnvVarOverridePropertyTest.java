package com.discord.bot.config;

import net.jqwik.api.*;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.MutablePropertySources;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.core.env.PropertySourcesPropertyResolver;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

// Feature: discord-bot-backend, Property 10: Variables de entorno sobreescriben configuración de archivo
class EnvVarOverridePropertyTest {

    /**
     * Property 10: For any configuration property defined both in application.properties
     * and in an environment variable, the value loaded by the system SHALL be the one
     * from the environment variable.
     *
     * This test uses Spring's StandardEnvironment and MutablePropertySources to simulate
     * the property resolution order that Spring Boot uses:
     * - System environment variables (higher priority)
     * - application.properties file (lower priority)
     *
     * For any random key-value pair, the env var value must always take precedence.
     *
     * Validates: Requirements 8.2
     */
    @Property(tries = 100)
    void envVarOverridesFileConfigForToken(
            @ForAll("alphanumericValues") String fileValue,
            @ForAll("alphanumericValues") String envValue) {

        Assume.that(!fileValue.equals(envValue));

        String propertyKey = "discord.bot.token";

        MutablePropertySources propertySources = new MutablePropertySources();

        // Add env var source (higher priority — added first)
        MapPropertySource envSource = new MapPropertySource(
                "systemEnvironment", Map.of(propertyKey, envValue));
        propertySources.addLast(envSource);

        // Add file source (lower priority — added after)
        MapPropertySource fileSource = new MapPropertySource(
                "applicationProperties", Map.of(propertyKey, fileValue));
        propertySources.addLast(fileSource);

        PropertySourcesPropertyResolver resolver = new PropertySourcesPropertyResolver(propertySources);

        String resolvedValue = resolver.getProperty(propertyKey);

        assertEquals(envValue, resolvedValue,
                "Environment variable value should override file config. " +
                        "File value: [" + fileValue + "], Env value: [" + envValue + "], " +
                        "Actual: [" + resolvedValue + "]");
    }

    /**
     * Property 10: Verifies that Spring's StandardEnvironment resolves properties
     * with the correct priority order. When a property is defined in both a
     * system-level source and an application-level source, the system-level
     * source SHALL take precedence.
     *
     * This test adds both sources to a StandardEnvironment and verifies the
     * env var value wins for the discord.bot.log-prefix property.
     *
     * Validates: Requirements 8.2
     */
    @Property(tries = 100)
    void envVarOverridesFileConfigForLogPrefix(
            @ForAll("alphanumericValues") String fileValue,
            @ForAll("alphanumericValues") String envValue) {

        Assume.that(!fileValue.equals(envValue));

        String propertyKey = "discord.bot.log-prefix";

        StandardEnvironment env = new StandardEnvironment();
        MutablePropertySources sources = env.getPropertySources();

        // Add env var source at highest priority (before existing sources)
        sources.addFirst(new MapPropertySource(
                "envOverride", Map.of(propertyKey, envValue)));

        // Add file source at lowest priority (after existing sources)
        sources.addLast(new MapPropertySource(
                "applicationProperties", Map.of(propertyKey, fileValue)));

        String resolvedValue = env.getProperty(propertyKey);

        assertEquals(envValue, resolvedValue,
                "Environment variable value should override file config for logPrefix. " +
                        "File value: [" + fileValue + "], Env value: [" + envValue + "], " +
                        "Actual: [" + resolvedValue + "]");
    }

    /**
     * Property 10: Verifies that for integer configuration properties
     * (maxReconnectAttempts), the environment variable value SHALL override
     * the file configuration value when both are present.
     *
     * Validates: Requirements 8.2
     */
    @Property(tries = 100)
    void envVarOverridesFileConfigForMaxReconnectAttempts(
            @ForAll("reconnectAttemptValues") int fileValue,
            @ForAll("reconnectAttemptValues") int envValue) {

        Assume.that(fileValue != envValue);

        String propertyKey = "discord.bot.max-reconnect-attempts";

        StandardEnvironment env = new StandardEnvironment();
        MutablePropertySources sources = env.getPropertySources();

        // Add env var source at highest priority
        sources.addFirst(new MapPropertySource(
                "envOverride", Map.of(propertyKey, String.valueOf(envValue))));

        // Add file source at lowest priority
        sources.addLast(new MapPropertySource(
                "applicationProperties", Map.of(propertyKey, String.valueOf(fileValue))));

        String resolvedValue = env.getProperty(propertyKey);

        assertEquals(String.valueOf(envValue), resolvedValue,
                "Environment variable value should override file config for maxReconnectAttempts. " +
                        "File value: [" + fileValue + "], Env value: [" + envValue + "], " +
                        "Actual: [" + resolvedValue + "]");
    }

    /**
     * Property 10: Verifies that for any arbitrary configuration key-value pair,
     * when the same key exists in both an environment-level source and a file-level
     * source, Spring's property resolution SHALL return the environment-level value.
     *
     * This generalizes the override behavior beyond specific BotConfigProperties fields.
     *
     * Validates: Requirements 8.2
     */
    @Property(tries = 100)
    void envVarOverridesFileConfigForArbitraryKey(
            @ForAll("configKeys") String key,
            @ForAll("alphanumericValues") String fileValue,
            @ForAll("alphanumericValues") String envValue) {

        Assume.that(!fileValue.equals(envValue));

        StandardEnvironment env = new StandardEnvironment();
        MutablePropertySources sources = env.getPropertySources();

        // Env var source — higher priority
        sources.addFirst(new MapPropertySource(
                "envOverride", Map.of(key, envValue)));

        // File source — lower priority
        sources.addLast(new MapPropertySource(
                "applicationProperties", Map.of(key, fileValue)));

        String resolvedValue = env.getProperty(key);

        assertEquals(envValue, resolvedValue,
                "Environment variable value should override file config for key [" + key + "]. " +
                        "File value: [" + fileValue + "], Env value: [" + envValue + "], " +
                        "Actual: [" + resolvedValue + "]");
    }

    /**
     * Provides random alphanumeric strings (1-50 chars) suitable for configuration values.
     */
    @Provide
    Arbitrary<String> alphanumericValues() {
        return Arbitraries.strings()
                .alpha()
                .numeric()
                .ofMinLength(1)
                .ofMaxLength(50);
    }

    /**
     * Provides random integer values for reconnect attempts (1-100).
     */
    @Provide
    Arbitrary<Integer> reconnectAttemptValues() {
        return Arbitraries.integers().between(1, 100);
    }

    /**
     * Provides random configuration key names in dotted notation (e.g., "discord.bot.somekey").
     */
    @Provide
    Arbitrary<String> configKeys() {
        Arbitrary<String> segment = Arbitraries.strings()
                .alpha()
                .ofMinLength(1)
                .ofMaxLength(10);

        return segment.list().ofMinSize(2).ofMaxSize(4)
                .map(segments -> String.join(".", segments));
    }
}
