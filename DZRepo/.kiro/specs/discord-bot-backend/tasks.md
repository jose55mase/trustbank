# Implementation Plan: Discord Bot Backend

## Overview

Implement a Discord bot backend using Spring Boot 3.x and JDA 5.x. The bot authenticates via a bot token, maintains a persistent WebSocket connection with Discord Gateway, processes slash commands (`/ping`, `/status`), sends messages to channels, and exposes a health check endpoint. Uses Gradle as build system and jqwik for property-based testing.

## Tasks

- [x] 1. Set up project structure, Gradle build, and core configuration
  - [x] 1.1 Initialize Spring Boot 3.x project with Gradle, add dependencies for JDA 5.x, Spring Boot Actuator, jqwik, and JUnit 5
    - Create `build.gradle` with all required dependencies
    - Create `settings.gradle` with project name
    - Create main application class with `@SpringBootApplication`
    - _Requirements: 1.1, 1.2, 8.1_

  - [x] 1.2 Implement `BotConfigProperties` with `@ConfigurationProperties`
    - Define fields: `token`, `defaultChannelId`, `logPrefix` (default: "discord-bot"), `maxReconnectAttempts` (default: 5)
    - Add validation for mandatory `token` field (not null, not blank)
    - Create `application.properties` with discord.bot.* properties (token hardcoded for testing)
    - _Requirements: 1.3, 1.4, 8.1, 8.2, 8.3_

  - [x] 1.3 Write property test for configuration validation (Property 1)
    - **Property 1: Validación de configuración obligatoria**
    - Generate random empty/blank/whitespace strings for mandatory params and verify descriptive error + controlled shutdown
    - **Validates: Requirements 1.3, 8.3**

  - [x] 1.4 Write property test for environment variable override (Property 10)
    - **Property 10: Variables de entorno sobreescriben configuración de archivo**
    - Generate random key-value pairs and verify env var takes precedence over file config
    - **Validates: Requirements 8.2**

- [x] 2. Implement SlashCommand interface and concrete commands
  - [x] 2.1 Create `SlashCommand` interface with `getName()`, `getDescription()`, and `execute(SlashCommandInteractionEvent)` methods
    - _Requirements: 3.3, 4.1_

  - [x] 2.2 Implement `PingCommand` that responds with "pong" and gateway latency in ms
    - _Requirements: 4.2_

  - [x] 2.3 Implement `StatusCommand` that responds with uptime and JDA connection status
    - _Requirements: 4.3_

  - [x] 2.4 Write unit tests for PingCommand and StatusCommand
    - Test `/ping` responds with "pong" + numeric latency
    - Test `/status` responds with uptime and connection state
    - _Requirements: 4.2, 4.3_

- [x] 3. Implement command dispatching and registry
  - [x] 3.1 Implement `CommandHandler` with auto-injected `Map<String, SlashCommand>` and `dispatch(event)` method
    - Route events to correct SlashCommand by name
    - Handle unrecognized commands with "comando no reconocido" response
    - Wrap execution in try-catch: generic error response to user, detailed log with stack trace
    - _Requirements: 3.3, 4.1, 4.4, 4.5_

  - [x] 3.2 Implement `CommandRegistry` to register slash commands with Discord REST API on startup
    - Log each successfully registered command
    - On failure for a single command, log error and continue with remaining commands
    - _Requirements: 6.1, 6.2, 6.3_

  - [x] 3.3 Write property test for command dispatch (Property 3)
    - **Property 3: Despacho correcto de comandos registrados**
    - Generate registered command names and verify correct handler is invoked with a response produced
    - **Validates: Requirements 3.3, 4.1**

  - [x] 3.4 Write property test for unrecognized commands (Property 4)
    - **Property 4: Comandos no registrados son rechazados**
    - Generate random strings not in the registered set and verify "no reconocido" response
    - **Validates: Requirements 4.4**

  - [x] 3.5 Write property test for command execution errors (Property 5)
    - **Property 5: Errores en ejecución de comandos producen respuesta genérica**
    - Generate random exceptions and verify generic user response + detailed log
    - **Validates: Requirements 4.5**

  - [x] 3.6 Write property test for resilient command registration (Property 7)
    - **Property 7: Registro parcial de comandos es resiliente**
    - Generate lists of commands with arbitrary failure subsets and verify non-failed commands register, failed ones are logged
    - **Validates: Requirements 6.3**

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Implement MessageSender with message splitting
  - [x] 5.1 Implement `MessageSender` component
    - `send(channelId, content)` method that sends messages via JDA
    - Divide messages > 2000 chars into consecutive chunks
    - Log success with channelId + messageId
    - Log error if channel doesn't exist or insufficient permissions
    - Validate empty messages (log WARN, don't send)
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [x] 5.2 Implement `MessageSendRequest` record with `splitContent(int maxLength)` method
    - _Requirements: 5.3_

  - [x] 5.3 Write property test for message splitting (Property 6)
    - **Property 6: División de mensajes preserva contenido**
    - Generate strings 0-10000 chars, verify: each chunk ≤ 2000, concatenation equals original, chunk count = ceil(length/2000)
    - **Validates: Requirements 5.3**

  - [x] 5.4 Write unit tests for MessageSender
    - Test successful send logs channelId + messageId
    - Test non-existent channel logs error
    - Test insufficient permissions logs error
    - _Requirements: 5.1, 5.2, 5.4_

- [x] 6. Implement event listener and bot initializer
  - [x] 6.1 Implement `DiscordEventListener` extending JDA `ListenerAdapter`
    - Override `onSlashCommandInteraction` to dispatch to CommandHandler
    - Override `onMessageReceived` for message events
    - Override `onGenericEvent` to log unrecognized events as WARN
    - Log command name, user ID, and channel ID for each command received
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 7.1, 7.2_

  - [x] 6.2 Implement `BotInitializer` component
    - Create JDA instance with token from BotConfigProperties
    - Set `autoReconnect(true)` for persistent connection
    - Register DiscordEventListener
    - Trigger CommandRegistry after `awaitReady()`
    - Expose `getJda()` and `getStartTime()` for health checks
    - Handle `LoginException` with error log and shutdown
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.3, 6.1_

  - [x] 6.3 Write property test for command log fields (Property 8)
    - **Property 8: Logs de comandos contienen campos requeridos**
    - Generate events with random command names, user IDs, and channel IDs; verify log contains all 3 fields
    - **Validates: Requirements 7.2**

- [x] 7. Implement monitoring, health check, and error rate tracking
  - [x] 7.1 Implement `ErrorRateMonitor` with circular queue of timestamps
    - `recordError()` adds current timestamp
    - `getErrorsInLastMinute()` filters last 60 seconds
    - Emit ERROR-level alert when count > 10 errors/min
    - _Requirements: 7.4_

  - [x] 7.2 Implement `BotHealthIndicator` implementing Spring Boot `HealthIndicator`
    - Return UP/DOWN based on JDA connection status
    - Include details: discordConnection, gatewayPing, uptime, registeredCommands
    - _Requirements: 7.3_

  - [x] 7.3 Write property test for error rate threshold (Property 9)
    - **Property 9: Umbral de tasa de errores dispara alerta**
    - Generate sequences of 0-50 errors in a 1-minute window; verify alert iff count > 10
    - **Validates: Requirements 7.4**

  - [x] 7.4 Write unit tests for BotHealthIndicator
    - Test health endpoint returns connection state and uptime
    - _Requirements: 7.3_

- [x] 8. Implement reconnection backoff strategy
  - [x] 8.1 Implement exponential backoff logic for reconnection attempts
    - Formula: `min(baseDelay * 2^(n-1), maxDelay)`
    - Track consecutive failed attempts, log critical error after 5 failures
    - _Requirements: 2.2, 2.4_

  - [x] 8.2 Write property test for backoff calculation (Property 2)
    - **Property 2: Cálculo de backoff exponencial**
    - Generate integers n ∈ [1, 20], verify delay = min(base * 2^(n-1), max) with strictly increasing values until cap
    - **Validates: Requirements 2.2**

- [x] 9. Wire all components together and configure logging
  - [x] 9.1 Configure structured logging with SLF4J + Logback
    - Set up log format with timestamp, level, component, and contextual fields
    - Configure INFO, WARN, ERROR levels
    - Wire ErrorRateMonitor into DiscordEventListener for error tracking
    - _Requirements: 7.1, 7.2, 7.4_

  - [x] 9.2 Create `CommandDispatchResult` record for internal tracking
    - Fields: commandName, userId, channelId, success, executionTimeMs, errorMessage
    - Integrate with CommandHandler dispatch flow
    - _Requirements: 7.2_

  - [x] 9.3 Write integration tests for component wiring
    - Test command dispatch end-to-end flow with mocked JDA
    - Test message sending with mocked channels
    - Test health endpoint returns expected structure
    - _Requirements: 3.3, 4.1, 5.1, 7.3_

- [x] 10. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document using jqwik
- Unit tests validate specific examples and edge cases
- The bot token can be hardcoded in `application.properties` for testing; use environment variables for production
