# Implementation Plan: Flag Event System

## Overview

Implement the Flag Event System module (`com.discord.bot.flagevent`) following the existing project patterns (Spring Boot services, JPA entities, JDA 5.x slash commands, scheduled polling). The implementation is broken into incremental steps: core parsing logic, position matching, session management, Discord commands, notifications, and the polling scheduler — each wiring into the previous step.

## Tasks

- [x] 1. Set up package structure, configuration, and data models
  - [x] 1.1 Create FlagEventProperties configuration class and FlagEvent record
    - Create `com.discord.bot.flagevent.config.FlagEventProperties` with `@ConfigurationProperties(prefix = "flagevent")` containing `pollIntervalSeconds` (default 30), `nitradoServiceId`, `guildId`, and `defaultTolerance` (default 10.0)
    - Create `com.discord.bot.flagevent.model.FlagEvent` record with fields: action, playerName, playerId, flagName, playerX, playerY, playerZ, flagX, flagY, flagZ, timestamp (LocalTime)
    - Add `flagevent.*` properties to `application.properties` / `application-local.properties`
    - _Requirements: 8.1, 3.2_

  - [x] 1.2 Create JPA entities and repositories
    - Create `FlagLocation` entity (id, guildId, coordX, coordZ, tolerance) with unique constraint on guildId
    - Create `PlayerFlagState` entity (id, guildId, playerName, flagName, accumulatedSeconds)
    - Create `ActiveFlagSession` entity (id, guildId, playerName, flagName, startTime as LocalDateTime) with unique constraint on guildId
    - Create `FlagPollingState` entity (id, guildId, lastLineIndex, lastTimestamp) with unique constraint on guildId
    - Create Spring Data JPA repositories for each entity: `FlagLocationRepository`, `PlayerFlagStateRepository`, `ActiveFlagSessionRepository`, `FlagPollingStateRepository`
    - _Requirements: 2.1, 4.4, 8.2_

- [x] 2. Implement FlagLogParser (stateless parsing logic)
  - [x] 2.1 Implement FlagLogParser with parseLine, parseLines, and format methods
    - Create `com.discord.bot.flagevent.parser.FlagLogParser` as a `@Component`
    - Implement regex for raised pattern: `(\d{2}:\d{2}:\d{2}) \| Player "(.+?)" \(id=([0-9a-fA-F]+) pos=<([\d.-]+), ([\d.-]+), ([\d.-]+)>\) has raised (.+?) on TerritoryFlag at <([\d.-]+), ([\d.-]+), ([\d.-]+)>`
    - Implement regex for lowered pattern (same structure with "lowered")
    - `parseLine(String line)` returns `Optional<FlagEvent>`, logs WARN for malformed data
    - `parseLines(List<String> lines)` returns `List<FlagEvent>` preserving order
    - `format(FlagEvent event)` formats back to log line string for round-trip testing
    - Validate coordinates in range -100000.0 to 100000.0, player name max 128 chars, player ID hex up to 64 chars
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_

  - [ ]* 2.2 Write property test: Parse round-trip (Property 1)
    - **Property 1: Parse round-trip**
    - Generate random valid FlagEvent records (action in {raised, lowered}, player name 1-128 chars, hex player ID up to 64 chars, coordinates in valid range)
    - Assert: `parser.parseLine(parser.format(event))` produces a FlagEvent with identical string fields and coordinates matching within 0.001 tolerance
    - **Validates: Requirements 1.7, 1.5**

  - [ ]* 2.3 Write property test: Valid log line parsing extracts correct fields (Property 2)
    - **Property 2: Valid log line parsing extracts correct fields**
    - Generate random valid flag event log lines with known field values
    - Assert: parsed FlagEvent fields match the embedded values (coordinates within 0.001)
    - **Validates: Requirements 1.1, 1.2**

  - [ ]* 2.4 Write property test: Non-matching lines produce no events (Property 3)
    - **Property 3: Non-matching lines produce no events**
    - Generate arbitrary strings that do NOT match flag event patterns
    - Assert: `parseLine` returns `Optional.empty()` without throwing exceptions
    - **Validates: Requirements 1.3**

  - [ ]* 2.5 Write property test: Sequential parsing preserves order (Property 4)
    - **Property 4: Sequential parsing preserves order**
    - Generate a random list of valid flag event log lines
    - Assert: `parseLines` returns events in the same order as source lines
    - **Validates: Requirements 1.6**

- [x] 3. Implement PositionMatcher (2D distance logic)
  - [x] 3.1 Implement PositionMatcher with distance2D and matches methods
    - Create `com.discord.bot.flagevent.service.PositionMatcher` as a `@Component`
    - `distance2D(double x1, double z1, double x2, double z2)` — returns `Math.sqrt((x1-x2)*(x1-x2) + (z1-z2)*(z1-z2))`
    - `matches(FlagEvent event, FlagLocation location)` — compares event flagX/flagZ with location coordX/coordZ, returns true if distance ≤ tolerance
    - Y coordinates are completely ignored in comparisons
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [ ]* 3.2 Write property test: 2D Euclidean distance and position matching (Property 5)
    - **Property 5: 2D Euclidean distance and position matching**
    - Generate random coordinate pairs and tolerance values
    - Assert: `matches()` returns true iff `sqrt((x1-x2)² + (z1-z2)²) <= tolerance`
    - Assert: distance is non-negative and satisfies triangle inequality
    - **Validates: Requirements 3.1, 3.2, 3.4**

  - [ ]* 3.3 Write property test: Y coordinate does not affect position matching (Property 6)
    - **Property 6: Y coordinate does not affect position matching**
    - Generate FlagEvent/FlagLocation pairs, record `matches()` result, then mutate Y coordinates
    - Assert: result of `matches()` is unchanged regardless of Y values
    - **Validates: Requirements 3.3**

- [x] 4. Checkpoint - Verify parsing and position matching
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Implement FlagSessionManager (session lifecycle and time tracking)
  - [x] 5.1 Implement FlagSessionManager with handleRaise, handleLower, getActiveSession
    - Create `com.discord.bot.flagevent.service.FlagSessionManager` as a `@Service`
    - `handleRaise(FlagEvent event)`: if no active session → create new `ActiveFlagSession`; if active session exists for different player → end session, calculate elapsed seconds, accumulate to `PlayerFlagState`, then create new session
    - `handleLower(FlagEvent event)`: validate event matches active session (player name + flag name), end session, calculate elapsed seconds, accumulate to `PlayerFlagState`; if mismatch → log WARN and ignore
    - `getActiveSession()`: returns `Optional<ActiveFlagSession>` for current guild
    - Persist via repositories; elapsed time = `Duration.between(sessionStart, eventTimestamp).getSeconds()`
    - Handle orphaned session detection: log WARN if session open > 24h during poll cycle check
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

  - [ ]* 5.2 Write property test: Session transitions preserve time accumulation invariant (Property 7)
    - **Property 7: Session transitions preserve time accumulation invariant**
    - Generate sequences of raise/lower events at configured location
    - Assert: sum of all accumulated seconds + current active session elapsed = total wall-clock time from first raise to last event (no gaps/overlaps)
    - **Validates: Requirements 4.1, 4.2, 4.3**

  - [ ]* 5.3 Write property test: Total time includes active session elapsed (Property 8)
    - **Property 8: Total time includes active session elapsed**
    - Generate a PlayerFlagState with accumulatedSeconds S and an ActiveFlagSession starting at time T
    - Query at time Q > T; assert reported total = S + (Q - T) in seconds
    - **Validates: Requirements 4.5, 6.3, 7.2**

- [x] 6. Implement FlagEventService (orchestrator)
  - [x] 6.1 Implement FlagEventService orchestrating parsing, matching, and session management
    - Create `com.discord.bot.flagevent.service.FlagEventService` as a `@Service`
    - `processNewLines(List<String> lines)`: parse lines → filter by position match → for each matched event call session manager → trigger notifications
    - Load `FlagLocation` from repository; if not configured → log WARN, discard all events
    - Load no channel configured state → log WARN, skip notifications
    - Wire `FlagLogParser`, `PositionMatcher`, `FlagSessionManager`, `FlagNotificationService`
    - Provide methods for commands: `getFlagLocation(guildId)`, `setFlagLocation(...)`, `setChannel(...)`, `getLeaderboard(...)`, `getPlayerStatus(...)`
    - _Requirements: 3.4, 3.5, 4.1, 4.2, 4.3, 5.11_

- [x] 7. Implement leaderboard and status query logic
  - [x] 7.1 Implement leaderboard ranking and dominant flag logic in FlagEventService
    - `getLeaderboard(guildId, limit)`: query all PlayerFlagState, add active session elapsed if applicable, sort descending by total time, break ties alphabetically by player name, return top N entries
    - `getDominantFlag(guildId)`: sum accumulatedSeconds by flagName across all players, return flag with highest total; ties broken alphabetically
    - `getPlayerStatus(guildId, playerName)`: return player's total time including active session elapsed, flag name, and whether flag is currently active
    - Format time as HH:MM:SS using `String.format("%02d:%02d:%02d", hours, minutes, seconds)`
    - _Requirements: 5.4, 5.5, 5.6, 5.7, 5.8, 6.1, 6.2, 6.3, 6.5, 7.1, 7.2, 7.3_

  - [ ]* 7.2 Write property test: Top-N leaderboard ranking (Property 9)
    - **Property 9: Top-N leaderboard ranking**
    - Generate random sets of PlayerFlagState entries with various accumulated times
    - Assert: result has at most N entries, sorted descending by total time, ties broken by player name ascending
    - **Validates: Requirements 5.4, 5.7, 6.1, 6.5**

  - [ ]* 7.3 Write property test: Dominant flag identification (Property 10)
    - **Property 10: Dominant flag identification**
    - Generate random PlayerFlagState sets, compute expected dominant flag
    - Assert: returned flag name has highest total across all players; ties broken alphabetically
    - **Validates: Requirements 5.5, 5.8**

  - [ ]* 7.4 Write property test: Leaderboard entry contains all required fields (Property 11)
    - **Property 11: Leaderboard entry contains all required fields**
    - Generate PlayerFlagState entries and format for display
    - Assert: each entry string contains rank position, player name, flag name, and time in HH:MM:SS format
    - **Validates: Requirements 6.2**

- [x] 8. Checkpoint - Verify core logic
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Implement FlagNotificationService (Discord embeds)
  - [x] 9.1 Implement FlagNotificationService for sending Discord embeds
    - Create `com.discord.bot.flagevent.service.FlagNotificationService` as a `@Service`
    - `sendRaiseNotification(FlagEvent event)`: build embed with player name, flag name, timestamp, "flag was raised" message, top 5 leaderboard section, dominant flag section; send to configured channel
    - `sendLowerNotification(FlagEvent event, long elapsedSeconds)`: build embed with player name, flag name, elapsed time formatted as HH:mm:ss, top 5 leaderboard section, dominant flag section; send to configured channel
    - Handle channel not configured (log WARN, skip), channel unavailable/permission error (log WARN with channel ID and reason, discard, continue)
    - Use JDA `EmbedBuilder` for rich embeds, matching existing project patterns
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.10, 5.11_

  - [ ]* 9.2 Write unit tests for FlagNotificationService
    - Test embed content for raise notifications (contains player name, flag name, timestamp, leaderboard)
    - Test embed content for lower notifications (contains elapsed time, leaderboard, dominant flag)
    - Test behavior when no channel configured (logs warning, no exception)
    - Test behavior when channel unavailable (logs warning, discards, continues)
    - Mock JDA TextChannel and EmbedBuilder
    - _Requirements: 5.1, 5.2, 5.10, 5.11_

- [x] 10. Implement Discord slash commands
  - [x] 10.1 Implement FlagLocationCommand (/flag-location set/get)
    - Create `com.discord.bot.flagevent.command.FlagLocationCommand` implementing `SlashCommand`
    - `/flag-location set x:<decimal> z:<decimal> [tolerance:<decimal>]` — validate ranges (X/Z: 0-15360, tolerance: 1-1000), persist FlagLocation, reply with confirmation
    - `/flag-location get` — retrieve and display current FlagLocation and tolerance; reply "no location set" if none configured
    - Return error messages for invalid input without modifying stored data
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [x] 10.2 Implement FlagChannelCommand (/flag-channel set)
    - Create `com.discord.bot.flagevent.command.FlagChannelCommand` implementing `SlashCommand`
    - `/flag-channel set channel:<channel_id>` — validate channel ID is numeric and 17-20 digits, store for guild, reply with confirmation
    - Return error message for invalid channel ID format
    - _Requirements: 5.8 (channel set), 5.9_

  - [x] 10.3 Implement FlagLeaderboardCommand (/flag-leaderboard)
    - Create `com.discord.bot.flagevent.command.FlagLeaderboardCommand` implementing `SlashCommand`
    - `/flag-leaderboard` — call `getLeaderboard(guildId, 10)`, build Discord embed with top 10 entries showing rank, player name, flag name, and time as HH:MM:SS
    - Include current active session elapsed in calculations
    - Handle empty state ("no flag events recorded") and database errors ("temporarily unavailable")
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [x] 10.4 Implement FlagStatusCommand (/flag-status)
    - Create `com.discord.bot.flagevent.command.FlagStatusCommand` implementing `SlashCommand`
    - `/flag-status` — identify player by Discord user, call `getPlayerStatus(guildId, playerName)`, build embed with total time, flag name, active status
    - Include current active session elapsed if player's flag is active
    - Handle no player linked ("no player linked to Discord account") and no history ("no flag event history")
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [ ]* 10.5 Write unit tests for Discord commands
    - Test FlagLocationCommand: valid set, invalid coords, invalid tolerance, get with/without stored location
    - Test FlagChannelCommand: valid channel ID, invalid format
    - Test FlagLeaderboardCommand: normal response, empty state, database error
    - Test FlagStatusCommand: normal response, no history, no linked player
    - Mock `SlashCommandInteractionEvent` and reply hooks
    - _Requirements: 2.1-2.7, 5.8-5.9, 6.1-6.6, 7.1-7.4_

- [x] 11. Implement FlagLogPollScheduler (periodic log processing)
  - [x] 11.1 Implement FlagLogPollScheduler with incremental polling and restart detection
    - Create `com.discord.bot.flagevent.scheduler.FlagLogPollScheduler` as a `@Component` with `@Scheduled(fixedDelayString = "${flagevent.pollIntervalSeconds:30}000")`
    - On each tick: call `NitradoApiClient.getServerLogs()` to download ADM log content
    - Load `FlagPollingState` from DB; if none exists → process entire file from beginning
    - Extract lines from `lastLineIndex + 1` to end of content
    - Detect server restart: if stored `lastLineIndex` exceeds current line count OR stored timestamp is later than first line's timestamp → reset state, process from beginning
    - Pass new lines to `FlagEventService.processNewLines()`
    - Update `FlagPollingState` with new lastLineIndex and lastTimestamp
    - Handle log unavailable/empty: log WARN, retry next cycle, don't modify state
    - Handle connection errors: log WARN, retry next cycle, preserve state
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [ ]* 11.2 Write property test: Incremental log processing (Property 12)
    - **Property 12: Incremental log processing**
    - Generate log content that grows between simulated poll cycles
    - Assert: only lines from `lastLineIndex + 1` to end are processed; earlier lines are NOT re-processed
    - **Validates: Requirements 8.2**

  - [ ]* 11.3 Write property test: Server restart detection (Property 13)
    - **Property 13: Server restart detection**
    - Generate polling states where lastLineIndex exceeds current file line count or lastTimestamp is later than first line
    - Assert: system resets state and processes entire log from beginning
    - **Validates: Requirements 8.6**

- [x] 12. Integration wiring and registration
  - [x] 12.1 Register slash commands and wire module into bot initialization
    - Register `FlagLocationCommand`, `FlagChannelCommand`, `FlagLeaderboardCommand`, `FlagStatusCommand` in the bot's command registry (following existing patterns in `BotInitializer` or command registration mechanism)
    - Add `@EnableConfigurationProperties(FlagEventProperties.class)` to module config or main application class
    - Ensure `@ComponentScan` covers `com.discord.bot.flagevent` package
    - Verify all dependencies are injected (NitradoApiClient, JDA, repositories)
    - _Requirements: 2.1, 5.8, 6.1, 7.1, 8.1_

  - [ ]* 12.2 Write integration test for full poll-parse-match-session-notify pipeline
    - Test complete flow: mock NitradoApiClient returning log content with flag events, verify FlagLogParser extracts events, PositionMatcher filters, FlagSessionManager tracks time, FlagNotificationService sends embed
    - Use H2 in-memory database for persistence verification
    - Verify FlagPollingState updates correctly across multiple poll cycles
    - _Requirements: 1.1, 3.1, 4.1, 5.1, 8.2_

- [x] 13. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using jqwik (already configured in build.gradle)
- Unit tests validate specific examples and edge cases
- The module follows existing patterns: `@Service`, `@Component`, `@Entity`, `SlashCommand` interface, `NitradoApiClient` for log retrieval
- All times are stored and calculated in whole seconds (long) for consistency

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["2.1", "3.1"] },
    { "id": 2, "tasks": ["2.2", "2.3", "2.4", "2.5", "3.2", "3.3"] },
    { "id": 3, "tasks": ["5.1", "6.1"] },
    { "id": 4, "tasks": ["5.2", "5.3", "7.1"] },
    { "id": 5, "tasks": ["7.2", "7.3", "7.4", "9.1"] },
    { "id": 6, "tasks": ["9.2", "10.1", "10.2", "10.3", "10.4"] },
    { "id": 7, "tasks": ["10.5", "11.1"] },
    { "id": 8, "tasks": ["11.2", "11.3", "12.1"] },
    { "id": 9, "tasks": ["12.2"] }
  ]
}
```
