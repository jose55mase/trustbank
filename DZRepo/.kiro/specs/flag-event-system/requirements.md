# Requirements Document

## Introduction

Sistema de eventos de bandera para un servidor DayZ integrado con un bot de Discord (Java Spring Boot). El sistema parsea logs del servidor para detectar eventos de izado y bajada de banderas en una ubicación configurada, rastrea el tiempo acumulado por jugador mientras su bandera está izada, envía notificaciones mediante embeds de Discord, y genera un resumen/leaderboard con el tiempo total por jugador.

## Glossary

- **Flag_Event_System**: Módulo del backend Spring Boot responsable de parsear logs de banderas, rastrear tiempo y enviar notificaciones a Discord.
- **Flag_Log_Parser**: Componente que extrae eventos de izado y bajada de bandera desde el contenido del archivo de log del servidor DayZ.
- **Flag_Event**: Registro de un evento de izado ("raised") o bajada ("lowered") de bandera, incluyendo nombre del jugador, nombre de la bandera, posición y timestamp.
- **Flag_Location**: Posición configurada (coordenadas X, Z) donde se monitorean los eventos de bandera. La coordenada Y (altura) se ignora en la comparación.
- **Player_Flag_State**: Estado actual de un jugador en el evento de bandera: bandera activa, nombre de la bandera, y tiempo acumulado.
- **Position_Tolerance**: Radio en unidades de mapa (configurable) dentro del cual se considera que un evento de bandera coincide con la Flag_Location configurada.
- **Flag_Leaderboard**: Resumen clasificado por tiempo total acumulado que cada jugador ha mantenido su bandera izada.
- **Discord_Embed**: Mensaje enriquecido enviado a un canal de Discord con información visual sobre eventos de bandera.
- **Active_Flag_Session**: Período de tiempo que comienza cuando un jugador iza su bandera y termina cuando otro jugador baja esa bandera en la misma ubicación.

## Requirements

### Requirement 1: Parseo de Logs de Bandera

**User Story:** Como administrador del servidor, quiero que el sistema parsee automáticamente los logs del servidor DayZ para detectar eventos de izado y bajada de banderas, para poder rastrear la actividad de banderas sin intervención manual.

#### Acceptance Criteria

1. WHEN a log line matches the pattern `HH:mm:ss | Player "NAME" (id=ID pos=<X, Y, Z>) has raised FLAG_NAME on TerritoryFlag at <X, Y, Z>`, THE Flag_Log_Parser SHALL extract a Flag_Event with action "raised", player name (string between double quotes, max 128 characters), player ID (hexadecimal string of up to 64 characters), flag name (string between "raised " and " on"), player position (three decimal coordinates), flag position (three decimal coordinates), and timestamp (parsed from HH:mm:ss).
2. WHEN a log line matches the pattern `HH:mm:ss | Player "NAME" (id=ID pos=<X, Y, Z>) has lowered FLAG_NAME on TerritoryFlag at <X, Y, Z>`, THE Flag_Log_Parser SHALL extract a Flag_Event with action "lowered", player name (string between double quotes, max 128 characters), player ID (hexadecimal string of up to 64 characters), flag name (string between "lowered " and " on"), player position (three decimal coordinates), flag position (three decimal coordinates), and timestamp (parsed from HH:mm:ss).
3. WHEN a log line does not match any flag event pattern, THE Flag_Log_Parser SHALL skip the line without producing an error and without modifying any internal state.
4. IF a log line matches the flag event pattern but contains malformed data (non-numeric coordinates, missing player ID, or empty player name), THEN THE Flag_Log_Parser SHALL log a warning that includes the line number or content reference, and skip the line without producing a Flag_Event.
5. THE Flag_Log_Parser SHALL parse coordinate values as decimal numbers in the range -100000.0 to 100000.0 with up to 6 decimal places of precision.
6. WHEN multiple log lines are provided as input, THE Flag_Log_Parser SHALL process them sequentially and return Flag_Events in the same order as their source lines.
7. FOR ALL valid Flag_Events, parsing then formatting then parsing SHALL produce an equivalent Flag_Event (round-trip property), where equivalence means all fields are identical and coordinate values match within a tolerance of 0.001.

### Requirement 2: Configuración de Ubicación de Bandera

**User Story:** Como administrador del servidor, quiero configurar la ubicación donde se monitorean los eventos de bandera mediante un comando de Discord, para poder definir el punto de captura del evento.

#### Acceptance Criteria

1. WHEN an administrator executes the `/flag-location set` command with parameters X (decimal number in the range 0 to 15360) and Z (decimal number in the range 0 to 15360), THE Flag_Event_System SHALL store the Flag_Location with the specified coordinates and respond with a confirmation message indicating the saved X and Z values.
2. WHEN an administrator executes the `/flag-location set` command, THE Flag_Event_System SHALL ignore the Y coordinate and store only X and Z as the Flag_Location.
3. WHEN an administrator executes the `/flag-location get` command, THE Flag_Event_System SHALL respond within 3 seconds with the currently configured Flag_Location coordinates (X, Z) and the Position_Tolerance value in meters.
4. WHEN an administrator executes the `/flag-location set` command with a tolerance parameter (decimal number in the range 1 to 1000 meters), THE Flag_Event_System SHALL update the Position_Tolerance to the specified value.
5. IF the `/flag-location set` command is executed with non-numeric values for X or Z, or with values outside the range 0 to 15360, THEN THE Flag_Event_System SHALL respond with an error message indicating that valid numeric X and Z coordinates within map bounds are required, and SHALL NOT modify the existing Flag_Location.
6. IF the `/flag-location set` command is executed with a tolerance value that is non-numeric or outside the range 1 to 1000, THEN THE Flag_Event_System SHALL respond with an error message indicating the valid tolerance range, and SHALL NOT modify the existing Position_Tolerance.
7. IF the `/flag-location get` command is executed and no Flag_Location has been previously configured, THEN THE Flag_Event_System SHALL respond with a message indicating that no flag location has been set.

### Requirement 3: Comparación de Posición

**User Story:** Como administrador del servidor, quiero que el sistema compare la posición del evento de bandera con la ubicación configurada usando solo coordenadas X y Z, para que las diferencias de altura no afecten la detección.

#### Acceptance Criteria

1. WHEN a Flag_Event is detected, THE Flag_Event_System SHALL compare the flag position X and Z coordinates against the configured Flag_Location X and Z coordinates using the 2D Euclidean distance formula: sqrt((eventX - locationX)² + (eventZ - locationZ)²).
2. THE Flag_Event_System SHALL consider a Flag_Event as matching the configured Flag_Location when the 2D Euclidean distance is less than or equal to the Position_Tolerance (default: 10 meters).
3. THE Flag_Event_System SHALL ignore the Y coordinate of both the flag position and the player position when comparing against the Flag_Location.
4. WHEN a Flag_Event position does not match the configured Flag_Location (distance exceeds Position_Tolerance), THE Flag_Event_System SHALL discard the event without further processing and without logging.
5. IF no Flag_Location has been configured when a Flag_Event is detected, THEN THE Flag_Event_System SHALL discard all Flag_Events and log a warning indicating that no flag location is set.

### Requirement 4: Rastreo de Tiempo por Jugador

**User Story:** Como administrador del servidor, quiero que el sistema rastree cuánto tiempo cada jugador mantiene su bandera izada en la ubicación configurada, para poder determinar quién domina el punto de captura.

#### Acceptance Criteria

1. WHEN a player raises a flag at the configured Flag_Location and no other flag is currently active, THE Flag_Event_System SHALL create a new Active_Flag_Session with the player name, flag name, and the Flag_Event timestamp as start time.
2. WHEN a player raises a flag at the configured Flag_Location while a different player's flag is currently active, THE Flag_Event_System SHALL end the current Active_Flag_Session, calculate the elapsed time using the difference between the new event's timestamp and the session start timestamp in seconds, add the elapsed time to the previous player's accumulated time in Player_Flag_State, and create a new Active_Flag_Session for the new player.
3. WHEN a player lowers the currently active flag at the configured Flag_Location and no new flag is raised in the same log batch, THE Flag_Event_System SHALL end the Active_Flag_Session, calculate the elapsed time as the difference in seconds between the lowered event timestamp and the session start timestamp, and add the elapsed time to the player's accumulated time in Player_Flag_State.
4. THE Flag_Event_System SHALL persist each Player_Flag_State with the player name, flag name, and total accumulated time stored in whole seconds.
5. WHILE an Active_Flag_Session exists, THE Flag_Event_System SHALL calculate the current session elapsed time as the difference in seconds between the current system time and the session start timestamp when queried via `/flag-status` or `/flag-leaderboard`.
6. IF a poll cycle detects no matching lowered event for an Active_Flag_Session that has been open for more than 24 hours, THEN THE Flag_Event_System SHALL log a warning indicating a potentially orphaned session without automatically ending it.
7. WHEN a player lowers a flag at the configured Flag_Location and the flag name or player name does not match the current Active_Flag_Session, THE Flag_Event_System SHALL ignore the lowered event and log a warning.

### Requirement 5: Notificaciones de Discord

**User Story:** Como jugador, quiero ver en un canal de Discord cuándo alguien iza o baja una bandera en la ubicación configurada, incluyendo quién lidera en tiempo y cuál bandera domina, para estar informado del estado del evento en tiempo real.

#### Acceptance Criteria

1. WHEN a flag is raised at the configured Flag_Location, THE Flag_Event_System SHALL send a Discord_Embed to the configured channel within 5 seconds of detecting the event, containing: player name, flag name, timestamp of the raise, and a message indicating the flag was raised.
2. WHEN a flag is lowered at the configured Flag_Location, THE Flag_Event_System SHALL send a Discord_Embed to the configured channel within 5 seconds of detecting the event, containing: player name who lowered the flag, the flag name that was lowered, and the elapsed time the flag was active formatted as hours, minutes, and seconds (HH:mm:ss).
3. WHILE an Active_Flag_Session exists, THE Discord_Embed sent upon lowering (criterion 2) SHALL display the elapsed time calculated as the difference between the raise timestamp and the lower timestamp of the Active_Flag_Session.
4. WHEN a Discord_Embed is sent for a flag raise or lower event, THE Flag_Event_System SHALL include in the embed a top 5 ranking section showing the 5 players with the highest total accumulated time, each entry displaying rank position, player name, flag name, and accumulated time formatted as HH:mm:ss, including any current active session time in the calculation.
5. WHEN a Discord_Embed is sent for a flag raise or lower event, THE Flag_Event_System SHALL include in the embed the name of the flag (e.g., Flag_Chedaki, Flag_APA) with the highest total accumulated time across all players and its total time formatted as HH:mm:ss.
6. IF fewer than 5 players have recorded flag events when generating the embed, THEN THE Flag_Event_System SHALL display only the available players in the top ranking section.
7. IF multiple players are tied in accumulated time within the top 5 ranking, THEN THE Flag_Event_System SHALL order those tied entries by player name in alphabetical ascending order.
8. IF multiple flags are tied for the highest accumulated time when generating the embed, THEN THE Flag_Event_System SHALL display the flag whose name comes first alphabetically.
8. WHEN an administrator executes the `/flag-channel set` command with a valid Discord channel ID (numeric, 17-20 digits), THE Flag_Event_System SHALL store the channel ID for flag event notifications and respond with a confirmation message indicating the channel was set.
9. IF the `/flag-channel set` command is executed with an invalid channel ID (non-numeric or outside the 17-20 digit range), THEN THE Flag_Event_System SHALL respond with an error message indicating that a valid Discord channel ID is required.
10. IF the configured Discord channel is unavailable or the bot lacks permissions when sending a notification, THEN THE Flag_Event_System SHALL log a warning including the channel ID and the failure reason, discard the notification without retrying, and continue processing subsequent events without failing.
11. IF no Discord channel has been configured when a flag event is detected at the configured Flag_Location, THEN THE Flag_Event_System SHALL log a warning indicating no notification channel is set and skip sending the Discord_Embed without failing.

### Requirement 6: Leaderboard y Resumen

**User Story:** Como administrador o jugador, quiero ver un resumen clasificado de quién ha acumulado más tiempo con su bandera izada, para conocer el estado de la competencia.

#### Acceptance Criteria

1. WHEN an administrator or player executes the `/flag-leaderboard` command, THE Flag_Event_System SHALL respond within 3 seconds with a Discord_Embed showing the top 10 entries of the Flag_Leaderboard sorted by total accumulated time in descending order.
2. THE Flag_Leaderboard SHALL include for each entry: rank position (1st, 2nd, etc.), player name, flag name, and total accumulated time formatted as `HH:MM:SS`.
3. WHILE an Active_Flag_Session exists for a player, THE Flag_Leaderboard SHALL include the current session elapsed time added to the player's previously accumulated time when calculating the ranking.
4. WHEN the `/flag-leaderboard` command is executed with no stored Player_Flag_State data, THE Flag_Event_System SHALL respond with a Discord_Embed indicating that no flag events have been recorded.
5. IF two or more players have identical total accumulated time, THEN THE Flag_Event_System SHALL order those tied entries by player name in alphabetical ascending order.
6. IF the Flag_Event_System cannot retrieve the leaderboard data due to a database error, THEN THE Flag_Event_System SHALL respond with an error message indicating that the leaderboard is temporarily unavailable.

### Requirement 7: Consulta de Estado del Jugador

**User Story:** Como jugador, quiero poder ver mi tiempo acumulado y el estado de mi bandera actual, para saber cuánto tiempo he dominado el punto de captura.

#### Acceptance Criteria

1. WHEN a player executes the `/flag-status` command, THE Flag_Event_System SHALL identify the player by their Discord user and respond within 3 seconds with a Discord_Embed containing the player's Player_Flag_State: total accumulated time formatted as hours, minutes, and seconds, flag name, and whether the player's flag is currently active.
2. WHILE the player has an Active_Flag_Session, WHEN the player executes the `/flag-status` command, THE Flag_Event_System SHALL include the current session elapsed time (calculated as the difference between current time and session start time) added to the accumulated time in the response.
3. IF a player executes the `/flag-status` command and has no recorded Player_Flag_State, THEN THE Flag_Event_System SHALL respond with a message indicating that the player has no flag event history.
4. IF a player executes the `/flag-status` command and the system cannot match the Discord user to a known player name, THEN THE Flag_Event_System SHALL respond with a message indicating that no player is linked to the Discord account.

### Requirement 8: Procesamiento Periódico de Logs

**User Story:** Como administrador del servidor, quiero que el sistema procese automáticamente los logs de forma periódica, para detectar eventos de bandera sin intervención manual.

#### Acceptance Criteria

1. THE Flag_Event_System SHALL poll the DayZ server log file at a configurable interval defined via Spring application property, with a default of 30 seconds and an allowed range of 10 to 300 seconds.
2. THE Flag_Event_System SHALL process only new log lines since the last successful poll, using the last processed timestamp and line index as reference, and SHALL persist this reference so that it survives system restarts.
3. IF the system starts for the first time or has no stored polling state, THEN THE Flag_Event_System SHALL process the entire current log file from the beginning.
4. IF the log file is unavailable or empty during a poll cycle, THEN THE Flag_Event_System SHALL log a warning and retry in the next poll cycle without failing and without modifying the last processed state.
5. IF a connection error occurs while downloading the log file, THEN THE Flag_Event_System SHALL log a warning and retry in the next cycle without losing the last processed state.
6. IF the log file content indicates a server restart (the stored line index exceeds the current file length, or stored timestamp is later than the first line's timestamp), THEN THE Flag_Event_System SHALL reset the polling state and process the log file from the beginning.
