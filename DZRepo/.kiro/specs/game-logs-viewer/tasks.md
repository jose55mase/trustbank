# Plan de Implementación: Game Logs Viewer

## Resumen

Implementación del módulo Game Logs Viewer que extiende el backend Spring Boot y la app Flutter para parsear, categorizar y visualizar eventos del servidor DayZ desde el archivo `server_log.ADM`. El backend introduce un parser unificado con sub-parsers por categoría y un endpoint REST, mientras que la app Flutter agrega modelo de datos, state management con Riverpod y una pantalla dedicada con filtros.

## Tareas

- [x] 1. Crear modelos y estructura base del parser en el backend
  - [x] 1.1 Crear el enum `GameLogCategory` y el record `GameLogEvent`
    - Crear paquete `com.discord.bot.gamelogs.model`
    - Definir `GameLogCategory` con valores: CONNECTION, DISCONNECTION, PLAYER_KILL, ZOMBIE_KILL, CHAT, HIT, UNKNOWN
    - Definir record `GameLogEvent(String timestamp, GameLogCategory category, String playerName, String message, Map<String, Object> details, int lineIndex)`
    - _Requisitos: 1.7, 2.2_

  - [x] 1.2 Crear la interfaz `EventLineParser`
    - Crear paquete `com.discord.bot.gamelogs.parser`
    - Definir interfaz con métodos: `Optional<GameLogEvent> parseLine(String line, int lineIndex)`, `String formatEvent(GameLogEvent event)`, `boolean canFormat(GameLogEvent event)`
    - _Requisitos: 1.7, 6.1_

  - [x] 1.3 Implementar `ConnectionLineParser`
    - Regex para patrón: `HH:mm:ss | Player "NAME" is connected (id=ID)`
    - Extraer timestamp, playerName, playerId en details
    - Implementar `formatEvent` para round-trip
    - _Requisitos: 1.1, 6.1_

  - [x] 1.4 Implementar `DisconnectionLineParser`
    - Regex para patrón: `HH:mm:ss | Player "NAME" has been disconnected`
    - Extraer timestamp y playerName
    - Implementar `formatEvent` para round-trip
    - _Requisitos: 1.2, 6.1_

  - [x] 1.5 Implementar `PlayerKillLineParser`
    - Regex para patrón: `HH:mm:ss | Player "VICTIMA" (...) killed by Player "KILLER" (...) with ARMA from DISTANCIA meters`
    - Reutilizar lógica del `LogParser` existente adaptada a la interfaz `EventLineParser`
    - Extraer victimName, killerName, weapon, distance, posiciones en details
    - Implementar `formatEvent` para round-trip
    - _Requisitos: 1.3, 6.1_

  - [x] 1.6 Implementar `ZombieKillLineParser`
    - Adaptar lógica del `ZombieKillParser` existente a la interfaz `EventLineParser`
    - Extraer playerName, zombieType, weapon, posición en details
    - Implementar `formatEvent` para round-trip
    - _Requisitos: 1.4, 6.1_

  - [x] 1.7 Implementar `ChatLineParser`
    - Regex para patrón: `HH:mm:ss | Player "NAME" (id=...) placed Chat: MESSAGE`
    - Extraer playerName, playerId, chatMessage en details
    - Implementar `formatEvent` para round-trip
    - _Requisitos: 1.5, 6.1_

  - [x] 1.8 Implementar `UnknownLineParser`
    - Fallback que siempre hace match
    - Clasificar como UNKNOWN, preservar rawLine en details
    - playerName vacío, message = texto original
    - _Requisitos: 1.6_

- [x] 2. Implementar el orquestador `GameLogParser`
  - [x] 2.1 Crear `GameLogParser` como componente Spring
    - Inyectar lista ordenada de `EventLineParser` (UnknownLineParser al final)
    - Implementar `parseAll(String logContent)`: iterar líneas, delegar al primer parser que haga match
    - Implementar `formatEvent(GameLogEvent event)`: delegar al parser que pueda formatear el evento
    - Ignorar líneas vacías
    - _Requisitos: 1.7, 6.1, 6.3_

  - [ ]* 2.2 Escribir test de propiedad: Round-trip del parser ADM
    - **Propiedad 1: Round-trip del parser ADM**
    - Generar líneas ADM válidas de cada categoría → parse → format → re-parse → assertEquals campos semánticos
    - Usar jqwik con mínimo 100 iteraciones
    - **Valida: Requisitos 6.2, 1.1, 1.2, 1.3, 1.4, 1.5**

  - [ ]* 2.3 Escribir test de propiedad: Líneas no reconocidas como unknown
    - **Propiedad 2: Líneas no reconocidas se clasifican como unknown**
    - Generar strings aleatorios que no coincidan con patrones ADM → parse → assertCategory(UNKNOWN) + assertRawLine
    - **Valida: Requisitos 1.6**

  - [ ]* 2.4 Escribir test de propiedad: Invariante estructural
    - **Propiedad 3: Invariante estructural de eventos parseados**
    - Generar líneas mixtas → parse → assertNotNull en timestamp, category, playerName, message
    - **Valida: Requisitos 1.7, 2.2**

  - [ ]* 2.5 Escribir test de propiedad: Resiliencia ante contenido mixto
    - **Propiedad 10: Resiliencia del parser ante contenido mixto**
    - Generar contenido con mezcla de líneas válidas e inválidas → parse → assertNoException + verificar que válidas se categorizan correctamente e inválidas como UNKNOWN
    - **Valida: Requisitos 6.3**

  - [ ]* 2.6 Escribir test de propiedad: Metamórfica — eventos ≤ líneas
    - **Propiedad 11: Metamórfica — eventos ≤ líneas**
    - Generar contenido ADM → parse → assertCount <= número de líneas no vacías
    - **Valida: Requisitos 6.4**

- [x] 3. Checkpoint - Verificar parsers del backend
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 4. Implementar servicio y controlador REST en el backend
  - [x] 4.1 Crear `GameLogService`
    - Inyectar `NitradoApiClient` y `GameLogParser`
    - Implementar `getGameEvents(int serviceId, String category, String search)`
    - Obtener logs crudos de Nitrado, parsear con `GameLogParser`
    - Filtrar por categoría si se proporciona
    - Filtrar por búsqueda case-insensitive si se proporciona (buscar en message y playerName)
    - Ordenar descendente por timestamp (más reciente primero), desempatar por lineIndex descendente
    - Manejar errores de Nitrado: lanzar excepción que resulte en HTTP 502
    - _Requisitos: 2.1, 2.3, 2.4, 2.5, 2.6_

  - [x] 4.2 Crear `GameLogEventDto` y mapper
    - Record DTO con campos: timestamp, category (lowercase string), playerName, message, details
    - Mapper de `GameLogEvent` a `GameLogEventDto`
    - _Requisitos: 2.2_

  - [x] 4.3 Crear `GameEventsController`
    - Endpoint: `GET /api/servers/{serviceId}/game-events`
    - Query params opcionales: `category`, `search`
    - Delegar a `GameLogService`
    - Manejar excepciones: devolver 502 si Nitrado falla
    - _Requisitos: 2.1, 2.3, 2.4, 2.6_

  - [ ]* 4.4 Escribir test de propiedad: Filtrado por categoría
    - **Propiedad 4: Filtrado por categoría**
    - Generar lista de eventos y una categoría → filtrar → assertAll(category == selected) + assertCount correcto
    - **Valida: Requisitos 2.3, 4.3, 5.3**

  - [ ]* 4.5 Escribir test de propiedad: Búsqueda case-insensitive
    - **Propiedad 5: Búsqueda case-insensitive**
    - Generar lista de eventos y término de búsqueda → filtrar → assertAll(contiene término ignorando case)
    - **Valida: Requisitos 2.4, 4.4**

  - [ ]* 4.6 Escribir test de propiedad: Composición de filtros
    - **Propiedad 6: Composición de filtros (categoría + búsqueda)**
    - Generar eventos + categoría + término → aplicar ambos filtros → assertAll(cumple ambos criterios)
    - **Valida: Requisitos 5.5**

  - [ ]* 4.7 Escribir test de propiedad: Ordenamiento cronológico descendente
    - **Propiedad 7: Ordenamiento cronológico descendente**
    - Generar lista de eventos → ordenar → assert evento[i].timestamp >= evento[i+1].timestamp
    - **Valida: Requisitos 2.5**

  - [ ]* 4.8 Escribir tests unitarios y de integración del endpoint
    - Test unitario: GameLogService filtra correctamente
    - Test de integración con MockMvc: endpoint responde 200 con JSON válido
    - Test de integración: endpoint responde 502 cuando Nitrado falla
    - Test: parámetros de filtro vacíos devuelven todos los eventos
    - _Requisitos: 2.1, 2.6_

- [x] 5. Checkpoint - Verificar backend completo
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 6. Implementar modelo de datos y cliente API en Flutter
  - [x] 6.1 Crear enum `GameLogCategory` en Flutter
    - Definir valores: connection, disconnection, playerKill, zombieKill, chat, hit, unknown
    - Implementar `fromString(String value)` con fallback a unknown
    - Implementar `toApiString()` para convertir a formato snake_case del backend
    - _Requisitos: 3.1, 3.4_

  - [x] 6.2 Crear modelo `GameLogEvent` en Flutter
    - Campos: timestamp (String), category (GameLogCategory), playerName (String), message (String), details (Map<String, dynamic>)
    - Implementar `factory GameLogEvent.fromJson(Map<String, dynamic> json)`
    - Implementar `Map<String, dynamic> toJson()`
    - Manejar categoría desconocida asignando `unknown` sin excepciones
    - _Requisitos: 3.1, 3.2, 3.4_

  - [x] 6.3 Extender `BackendApiClient` con método `getGameEvents`
    - Agregar método: `Future<List<GameLogEvent>> getGameEvents(int serverId, {String? category, String? search})`
    - Realizar GET a `/api/servers/$serverId/game-events` con query params opcionales
    - Deserializar respuesta JSON a `List<GameLogEvent>`
    - _Requisitos: 3.2_

  - [ ]* 6.4 Escribir test de propiedad: Round-trip serialización Flutter
    - **Propiedad 8: Round-trip de serialización Flutter (GameLogEvent)**
    - Generar instancias aleatorias de GameLogEvent → toJson → fromJson → assertEquals
    - Mínimo 100 iteraciones con Random(42)
    - **Valida: Requisitos 3.3, 3.2**

  - [ ]* 6.5 Escribir test de propiedad: Categoría no reconocida en deserialización
    - **Propiedad 9: Categoría no reconocida en deserialización Flutter**
    - Generar strings aleatorios no válidos → GameLogCategory.fromString → assertEquals(unknown)
    - **Valida: Requisitos 3.4**

  - [ ]* 6.6 Escribir tests unitarios del modelo y cliente API
    - Test: deserialización de cada tipo de evento desde JSON de ejemplo
    - Test: BackendApiClient.getGameEvents parsea respuesta correctamente
    - Test: categoría desconocida no lanza excepción
    - _Requisitos: 3.1, 3.2, 3.4_

- [x] 7. Implementar pantalla de Game Logs en Flutter
  - [x] 7.1 Crear `GameLogsState` y `GameLogsNotifier` con Riverpod
    - State con campos: events, selectedCategory, searchQuery, isLoading, error
    - Métodos: loadEvents(), selectCategory(), updateSearch(), refresh()
    - Getter `filteredEvents` que aplica filtros locales de categoría y búsqueda
    - Usar BackendApiClient para obtener eventos
    - _Requisitos: 4.1, 4.3, 4.4, 4.5, 5.3, 5.5_

  - [x] 7.2 Crear `GameLogsScreen` con AppBar y lista de eventos
    - AppBar con título "Game Logs" y botón de refresh
    - ListView.builder con tiles diferenciados por categoría (iconos y colores distintos)
    - Indicador de progreso durante carga
    - Mensaje de error con botón "Reintentar" si falla la carga
    - Mensaje "No hay eventos" si la lista está vacía
    - _Requisitos: 4.1, 4.2, 4.5, 4.6, 4.7_

  - [x] 7.3 Implementar filtros por categoría con FilterChips
    - Fila de FilterChip para cada categoría: Todos, Conexiones, Desconexiones, Kills PvP, Kills Zombies, Chat, Otros
    - Indicar visualmente la categoría seleccionada
    - Chip "Todos" muestra todos los eventos sin filtrar
    - _Requisitos: 5.1, 5.2, 5.3, 5.4_

  - [x] 7.4 Implementar campo de búsqueda
    - TextField con decoración de búsqueda
    - Filtrado case-insensitive en tiempo real
    - Combinación con filtro de categoría activo
    - _Requisitos: 4.4, 5.5_

  - [x] 7.5 Registrar ruta en auto_route y navegación
    - Agregar `GameLogsRoute` en el router de la app
    - Conectar navegación desde la pantalla del servidor
    - _Requisitos: 4.1_

  - [ ]* 7.6 Escribir widget tests de la pantalla
    - Test: pantalla muestra lista de eventos
    - Test: chips de filtro renderizan todas las categorías
    - Test: búsqueda filtra eventos visualmente
    - Test: estado de carga muestra indicador de progreso
    - Test: estado de error muestra mensaje con botón reintentar
    - _Requisitos: 4.1, 4.2, 4.3, 4.4, 4.6, 4.7_

- [x] 8. Checkpoint final - Verificar integración completa
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia requisitos específicos para trazabilidad
- Los checkpoints aseguran validación incremental
- Los tests de propiedad validan propiedades universales de correctitud definidas en el diseño
- Los tests unitarios validan ejemplos específicos y casos borde
- El backend usa Java 17 + Spring Boot 3.4 + jqwik para PBT
- La app Flutter usa Dart + Riverpod + auto_route + Dio
