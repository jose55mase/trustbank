# Plan de Implementación: Integración Nitrado Server

## Resumen

Implementación de la integración con la API de Nitrado en el backend Spring Boot (`discord-bot-backend`). Se crearán los componentes en el paquete `com.discord.bot.nitrado`: configuración, cliente HTTP, controladores REST, DTOs, excepciones y tests. Cada tarea construye sobre las anteriores de forma incremental, terminando con la integración completa de todos los componentes.

## Tareas

- [x] 1. Configurar dependencias y propiedades de Nitrado
  - Añadir `spring-boot-starter-web` a `build.gradle` (necesario para los controladores REST)
  - Crear la clase `NitradoConfigProperties` en `com.discord.bot.nitrado.config` con las propiedades: `apiToken` (`@NotBlank`), `baseUrl` (default `https://api.nitrado.net`), `connectTimeoutMs` (default 10000), `readTimeoutMs` (default 10000)
  - Añadir las propiedades de Nitrado a `application.properties`: `nitrado.api-token`, `nitrado.base-url`, `nitrado.connect-timeout-ms`, `nitrado.read-timeout-ms`
  - Crear la clase `NitradoRestTemplateConfig` en `com.discord.bot.nitrado.config` con un `@Bean("nitradoRestTemplate")` que configure timeouts y URL base desde `NitradoConfigProperties`
  - _Requisitos: 1.1, 1.3_

- [x] 2. Crear DTOs, enumeraciones y jerarquía de excepciones
  - [x] 2.1 Crear los DTOs como Java Records en `com.discord.bot.nitrado.dto`
    - `GameServerDto(int id, String name, String ip, int port, String status, int currentPlayers, int maxPlayers, String map, String gameVersion)`
    - `PlayerDto(String id, String name, boolean online)`
    - `BannedPlayerDto(String id, String name, String reason, Instant bannedAt)`
    - `FileEntryDto(String name, String path, String type, Long size)`
    - `ErrorResponse(String error, String message)`
    - `ActionResponse(String status, String message)`
    - `BanRequest(String reason)`
    - `FileContentResponse(String content)`
    - `LogResponse(String content)`
    - _Requisitos: 2.3, 3.2, 5.2, 8.2, 10.2, 14.5_

  - [x] 2.2 Crear la enumeración `ServerAction` en `com.discord.bot.nitrado.dto`
    - Valores: `START`, `STOP`, `RESTART`
    - Método estático `fromString(String value)` que convierte case-insensitive y lanza `IllegalArgumentException` con mensaje descriptivo para valores inválidos
    - _Requisitos: 4.2, 4.3, 4.4_

  - [ ]* 2.3 Escribir test de propiedad para `ServerAction.fromString()` — acciones inválidas rechazadas
    - **Propiedad 6: Acciones inválidas son rechazadas**
    - Generar strings aleatorios que no sean "start", "stop" ni "restart" (case-insensitive) y verificar que se lanza `IllegalArgumentException` con las acciones permitidas en el mensaje
    - **Valida: Requisitos 4.4**

  - [x] 2.4 Crear la jerarquía de excepciones en `com.discord.bot.nitrado.exception`
    - `NitradoApiException extends RuntimeException` (con campo `statusCode`)
    - `NitradoAuthException extends NitradoApiException` (para 401/403)
    - `NitradoServerException extends NitradoApiException` (para 5xx)
    - `NitradoConnectionException extends RuntimeException` (para timeout/red)
    - `NitradoNotFoundException extends NitradoApiException` (para 404/recurso no encontrado)
    - _Requisitos: 14.1, 14.2, 14.3, 14.4_

- [x] 3. Implementar `NitradoApiClient` — operaciones de servidor
  - [x] 3.1 Crear la clase `NitradoApiClient` en `com.discord.bot.nitrado.service` con inyección de `RestTemplate` (qualifier `nitradoRestTemplate`) y `NitradoConfigProperties`
    - Implementar método privado para construir `HttpHeaders` con `Authorization: Bearer {token}`
    - Implementar método privado `extractMessage()` para parsear mensajes de error de la API de Nitrado
    - Implementar bloque de manejo de errores que traduzca `HttpClientErrorException` (401/403 → `NitradoAuthException`, 404 → `NitradoNotFoundException`, otros 4xx → `NitradoApiException`), `HttpServerErrorException` (5xx → `NitradoServerException`) y `ResourceAccessException` (→ `NitradoConnectionException`)
    - Implementar logging con prefijo `[NitradoClient]`: INFO para solicitudes (método, URL, serviceId), ERROR para errores (código, mensaje, serviceId), DEBUG para respuestas exitosas (tiempo en ms)
    - _Requisitos: 1.2, 1.4, 14.1, 14.2, 14.3, 14.4, 15.1, 15.2, 15.3, 15.4_

  - [x] 3.2 Implementar `getServers()` en `NitradoApiClient`
    - Consultar `GET /services` en la API de Nitrado
    - Filtrar servicios cuyo campo `details.game` contenga "dayz" (case-insensitive)
    - Mapear cada servicio a `GameServerDto`
    - _Requisitos: 2.1, 2.2, 2.3, 2.4_

  - [x] 3.3 Implementar `getServerStatus(int serviceId)` en `NitradoApiClient`
    - Consultar `GET /services/{serviceId}/gameservers`
    - Parsear respuesta y construir `GameServerDto` con todos los campos
    - _Requisitos: 3.1, 3.2, 3.3_

  - [x] 3.4 Implementar `serverAction(int serviceId, ServerAction action)` en `NitradoApiClient`
    - Para `START` y `RESTART`: POST a `/services/{serviceId}/gameservers/restart`
    - Para `STOP`: POST a `/services/{serviceId}/gameservers/stop`
    - _Requisitos: 4.1, 4.2, 4.3, 4.5_

  - [ ]* 3.5 Escribir test de propiedad para cabecera de autenticación
    - **Propiedad 1: Cabecera de autenticación siempre presente**
    - Generar tokens aleatorios no vacíos, configurar `NitradoApiClient` con cada token, y verificar que toda solicitud incluye `Authorization: Bearer {token}`
    - Usar `MockRestServiceServer` para interceptar las solicitudes
    - **Valida: Requisitos 1.2**

  - [ ]* 3.6 Escribir test de propiedad para filtrado de servidores DayZ
    - **Propiedad 3: Filtrado de servidores DayZ (case-insensitive)**
    - Generar listas de servicios con nombres de juego aleatorios (algunos con "dayz" en distintas casings)
    - Verificar que solo los servicios DayZ aparecen en el resultado
    - **Valida: Requisitos 2.2**

  - [ ]* 3.7 Escribir test de propiedad para mapeo de acciones a endpoints
    - **Propiedad 5: Mapeo de acciones a endpoints de Nitrado**
    - Generar serviceIds aleatorios y las 3 acciones válidas
    - Verificar que start/restart → `/services/{id}/gameservers/restart` y stop → `/services/{id}/gameservers/stop`
    - **Valida: Requisitos 4.2, 4.3**

- [x] 4. Implementar `NitradoApiClient` — operaciones de jugadores
  - [x] 4.1 Implementar `getPlayers(int serviceId)` en `NitradoApiClient`
    - Consultar `GET /services/{serviceId}/gameservers/games/players`
    - Parsear respuesta y construir lista de `PlayerDto`
    - _Requisitos: 5.1, 5.2, 5.3_

  - [x] 4.2 Implementar `kickPlayer(int serviceId, String playerId)` en `NitradoApiClient`
    - POST a `/services/{serviceId}/gameservers/games/players/kick` con `player_id` en el cuerpo
    - _Requisitos: 6.1, 6.2, 6.3_

  - [x] 4.3 Implementar `banPlayer(int serviceId, String playerId, String reason)` en `NitradoApiClient`
    - POST a `/services/{serviceId}/gameservers/games/players/ban` con `player_id` y opcionalmente `reason`
    - _Requisitos: 7.1, 7.2, 7.3_

  - [x] 4.4 Implementar `getBanList(int serviceId)` y `unbanPlayer(int serviceId, String playerId)` en `NitradoApiClient`
    - `getBanList`: GET a `/services/{serviceId}/gameservers/games/banlist`, parsear a `BannedPlayerDto`
    - `unbanPlayer`: DELETE a `/services/{serviceId}/gameservers/games/banlist` con `player_id` en el cuerpo
    - _Requisitos: 8.1, 8.2, 8.3, 9.1, 9.2, 9.3_

  - [ ]* 4.5 Escribir test de propiedad para cuerpo de solicitudes de jugadores
    - **Propiedad 7: Construcción correcta del cuerpo de solicitudes de jugadores**
    - Generar serviceIds, playerIds aleatorios y reasons opcionales
    - Verificar que `player_id` siempre está presente y `reason` solo cuando no es null
    - **Valida: Requisitos 6.2, 7.2, 9.2**

- [x] 5. Checkpoint — Verificar compilación y tests del cliente
  - Asegurar que el proyecto compila correctamente y todos los tests pasan. Preguntar al usuario si surgen dudas.

- [x] 6. Implementar `NitradoApiClient` — operaciones de archivos y logs
  - [x] 6.1 Implementar `listFiles(int serviceId, String path)` en `NitradoApiClient`
    - GET a `/services/{serviceId}/gameservers/file_server/list` con parámetro `dir`
    - Parsear respuesta y construir lista de `FileEntryDto`
    - _Requisitos: 10.1, 10.2, 10.3, 10.4_

  - [x] 6.2 Implementar `downloadFile(int serviceId, String filePath)` en `NitradoApiClient`
    - GET a `/services/{serviceId}/gameservers/file_server/download` para obtener URL temporal
    - Descargar contenido del archivo desde la URL temporal
    - _Requisitos: 11.1, 11.2, 11.3_

  - [x] 6.3 Implementar `uploadFile(int serviceId, String filePath, String content)` en `NitradoApiClient`
    - POST a `/services/{serviceId}/gameservers/file_server/upload` con `path` en query string y contenido como `application/octet-stream`
    - _Requisitos: 12.1, 12.2, 12.3_

  - [x] 6.4 Implementar `getServerLogs(int serviceId)` en `NitradoApiClient`
    - Listar archivos en `/games` para localizar la carpeta DayZ
    - Descargar log desde `{carpeta_dayz}/logs/server_log.ADM`
    - Implementar fallback a `/games/ni{serviceId}_dayz/logs/server_log.ADM` si no se encuentra la carpeta
    - _Requisitos: 13.1, 13.2, 13.3, 13.4_

  - [ ]* 6.5 Escribir test de propiedad para content-type de subida de archivos
    - **Propiedad 8: Subida de archivos usa content-type correcto**
    - Generar contenidos de archivo y rutas aleatorias
    - Verificar que la solicitud usa `application/octet-stream` y el parámetro `path` está en la query string
    - **Valida: Requisitos 12.2**

  - [ ]* 6.6 Escribir test de propiedad para mapeo JSON-a-DTO
    - **Propiedad 4: Mapeo JSON-a-DTO preserva todos los campos**
    - Generar objetos JSON con campos aleatorios para cada tipo de DTO
    - Verificar que todos los campos se preservan sin pérdida ni alteración
    - **Valida: Requisitos 2.3, 3.2, 5.2, 8.2, 10.2**

- [x] 7. Implementar `NitradoExceptionHandler` y controladores REST
  - [x] 7.1 Crear `NitradoExceptionHandler` en `com.discord.bot.nitrado.exception`
    - `@RestControllerAdvice(basePackages = "com.discord.bot.nitrado")`
    - Manejar `NitradoAuthException` → 401, `NitradoApiException` → 400, `NitradoServerException` → 502, `NitradoConnectionException` → 504, `NitradoNotFoundException` → 404, `IllegalArgumentException` → 400
    - Todas las respuestas como `ErrorResponse(error, message)`
    - _Requisitos: 14.1, 14.2, 14.3, 14.4, 14.5_

  - [x] 7.2 Crear `ServerController` en `com.discord.bot.nitrado.controller`
    - `@RestController @RequestMapping("/api/servers")`
    - `GET /` → `getServers()` devuelve `List<GameServerDto>`
    - `GET /{serviceId}/status` → `getServerStatus()` devuelve `GameServerDto`
    - `POST /{serviceId}/actions/{action}` → `serverAction()` convierte action con `ServerAction.fromString()`, devuelve `ActionResponse`
    - `GET /{serviceId}/logs` → `getServerLogs()` devuelve `LogResponse`
    - `GET /{serviceId}/banlist` → `getBanList()` devuelve `List<BannedPlayerDto>` (mapeo alternativo para Req 8.1)
    - `DELETE /{serviceId}/banlist/{playerId}` → `unbanPlayer()` devuelve `ActionResponse` (mapeo alternativo para Req 9.1)
    - _Requisitos: 2.1, 2.5, 3.1, 3.3, 4.1, 4.4, 8.1, 9.1, 13.1_

  - [x] 7.3 Crear `PlayerController` en `com.discord.bot.nitrado.controller`
    - `@RestController @RequestMapping("/api/servers/{serviceId}/players")`
    - `GET /` → `getPlayers()` devuelve `List<PlayerDto>`
    - `POST /{playerId}/kick` → `kickPlayer()` devuelve `ActionResponse`
    - `POST /{playerId}/ban` → `banPlayer()` con `@RequestBody(required = false) BanRequest` devuelve `ActionResponse`
    - _Requisitos: 5.1, 5.3, 6.1, 7.1_

  - [x] 7.4 Crear `FileController` en `com.discord.bot.nitrado.controller`
    - `@RestController @RequestMapping("/api/servers/{serviceId}/files")`
    - `GET /` → `listFiles()` con `@RequestParam(defaultValue = "/") String path` devuelve `List<FileEntryDto>`
    - `GET /download` → `downloadFile()` con `@RequestParam String path` devuelve `FileContentResponse`
    - `POST /upload` → `uploadFile()` con `@RequestParam String path` y `@RequestBody String content` devuelve `ActionResponse`
    - _Requisitos: 10.1, 10.3, 10.4, 11.1, 11.3, 12.1_

  - [ ]* 7.5 Escribir tests de propiedad para clasificación de errores
    - **Propiedad 9: Errores de autenticación de Nitrado se clasifican correctamente**
    - Generar respuestas con códigos 401 y 403, verificar que se lanza `NitradoAuthException` y el handler devuelve HTTP 401
    - **Valida: Requisitos 1.4, 14.1**
    - **Propiedad 10: Errores de cliente de Nitrado se clasifican correctamente**
    - Generar respuestas con códigos 4xx (excluyendo 401/403), verificar `NitradoApiException` → HTTP 400 con mensaje original
    - **Valida: Requisitos 14.2**
    - **Propiedad 11: Errores de servidor de Nitrado se clasifican correctamente**
    - Generar respuestas con códigos 5xx, verificar `NitradoServerException` → HTTP 502
    - **Valida: Requisitos 14.3**

  - [ ]* 7.6 Escribir test de propiedad para formato consistente de errores
    - **Propiedad 12: Formato consistente de respuestas de error**
    - Generar todas las excepciones tipadas del sistema y verificar que la respuesta JSON contiene exactamente los campos `error` y `message`
    - **Valida: Requisitos 14.5**

  - [ ]* 7.7 Escribir test de propiedad para tokens vacíos rechazados
    - **Propiedad 2: Tokens vacíos o en blanco son rechazados**
    - Generar strings de whitespace, vacíos y null como tokens
    - Verificar que la validación de `@NotBlank` en `NitradoConfigProperties` rechaza el valor con mensaje descriptivo
    - **Valida: Requisitos 1.3**

- [x] 8. Escribir tests unitarios para controladores y cliente
  - [x] 8.1 Escribir tests unitarios para `ServerController`
    - `GET /api/servers` devuelve lista de `GameServerDto` (Req 2.1)
    - `GET /api/servers/{id}/status` devuelve `GameServerDto` detallado (Req 3.1)
    - `GET /api/servers/{id}/status` con id inexistente devuelve 404 (Req 3.3)
    - `POST /api/servers/{id}/actions/start` devuelve 200 (Req 4.1)
    - `POST /api/servers/{id}/actions/invalid` devuelve 400 (Req 4.4)
    - `GET /api/servers/{id}/logs` devuelve contenido de log (Req 13.1)
    - _Requisitos: 2.1, 2.5, 3.1, 3.3, 4.1, 4.4, 13.1_

  - [x] 8.2 Escribir tests unitarios para `PlayerController`
    - `GET /api/servers/{id}/players` devuelve lista vacía con 200 (Req 5.3)
    - `POST /api/servers/{id}/players/{pid}/kick` devuelve 200 (Req 6.1)
    - `POST /api/servers/{id}/players/{pid}/ban` con y sin reason devuelve 200 (Req 7.1)
    - `GET /api/servers/{id}/banlist` devuelve lista vacía con 200 (Req 8.3)
    - `DELETE /api/servers/{id}/banlist/{pid}` devuelve 200 (Req 9.1)
    - _Requisitos: 5.1, 5.3, 6.1, 7.1, 8.1, 8.3, 9.1_

  - [x] 8.3 Escribir tests unitarios para `FileController`
    - `GET /api/servers/{id}/files` sin parámetro path usa "/" por defecto (Req 10.4)
    - `GET /api/servers/{id}/files/download` devuelve contenido de archivo (Req 11.1)
    - `POST /api/servers/{id}/files/upload` devuelve 200 (Req 12.1)
    - `GET /api/servers/{id}/files` con directorio inexistente devuelve 404 (Req 10.3)
    - `GET /api/servers/{id}/files/download` con archivo inexistente devuelve 404 (Req 11.3)
    - _Requisitos: 10.1, 10.3, 10.4, 11.1, 11.3, 12.1_

  - [x] 8.4 Escribir tests unitarios para `NitradoApiClient` — manejo de errores y logs
    - Timeout de conexión devuelve `NitradoConnectionException` (Req 14.4)
    - Fallback de ruta de logs cuando no se encuentra carpeta DayZ (Req 13.3)
    - Descarga de archivo en dos pasos: obtener URL temporal + descargar contenido (Req 11.2)
    - Verificar que logs INFO contienen método HTTP, URL y serviceId (Req 15.1)
    - Verificar que logs ERROR contienen código de respuesta, mensaje y serviceId (Req 15.2)
    - Verificar que logs DEBUG contienen tiempo de respuesta en ms (Req 15.3)
    - _Requisitos: 11.2, 13.3, 14.4, 15.1, 15.2, 15.3_

- [x] 9. Checkpoint final — Verificar compilación y todos los tests
  - Asegurar que el proyecto compila correctamente y todos los tests pasan. Preguntar al usuario si surgen dudas.

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia los requisitos específicos para trazabilidad
- Los checkpoints aseguran validación incremental
- Los tests de propiedades validan propiedades universales de corrección definidas en el diseño
- Los tests unitarios validan ejemplos específicos y edge cases
- Todos los componentes se crean en el paquete `com.discord.bot.nitrado` y sus subpaquetes
- Se usa Java 17 con Spring Boot 3.x, RestTemplate, y jqwik para PBT
