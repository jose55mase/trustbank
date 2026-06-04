# Plan de Implementación: Sistema de Economía y Estadísticas de Jugadores

## Resumen

Este plan convierte el diseño del sistema de economía y estadísticas en tareas incrementales de codificación. El orden sigue las dependencias: primero persistencia y configuración de base de datos, luego modelos/entidades, repositorios, servicios, parser de zombies, scheduler, comandos de Discord, controladores REST, y finalmente las pantallas Flutter. Cada tarea construye sobre las anteriores y no deja código huérfano.

## Tareas

- [x] 1. Configurar dependencias y persistencia con base de datos
  - [x] 1.1 Agregar dependencias de JPA, H2 y MySQL al build.gradle
    - Agregar `spring-boot-starter-data-jpa`, `h2` (runtimeOnly), y `mysql-connector-j` (runtimeOnly) al bloque de dependencias
    - _Requisitos: 1.1, 1.2_
  - [x] 1.2 Configurar propiedades de base de datos para perfiles dev y producción
    - Agregar configuración de H2 embebido en `application.properties` (perfil local/dev): `spring.datasource.url=jdbc:h2:file:./data/economy-dev`, `spring.jpa.hibernate.ddl-auto=update`, `spring.h2.console.enabled=true`
    - Crear `application-prod.properties` con configuración de MySQL usando variables de entorno (`MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_DB`, `MYSQL_USER`, `MYSQL_PASSWORD`)
    - _Requisitos: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Crear entidades JPA, enumeraciones y excepciones del dominio
  - [x] 2.1 Crear la enumeración TransactionType y las excepciones del dominio
    - Crear `TransactionType` enum con valores `ZOMBIE_KILL_REWARD`, `ADMIN_CREDIT`, `ADMIN_DEBIT` en paquete `economy.model`
    - Crear excepciones: `PlayerNotLinkedException`, `InsufficientBalanceException` (con campos `currentBalance` y `requestedAmount`), `InvalidAmountException`, `DayzNameAlreadyLinkedException` (con campo `dayzName`) en paquete `economy.exception`
    - _Requisitos: 5.5, 7.4, 7.5, 2.2_
  - [x] 2.2 Crear la entidad JPA PlayerProfile
    - Crear clase `PlayerProfile` con campos: `id` (Long, auto-generado), `discordId` (String, unique, not null), `dayzPlayerName` (String, unique, not null), `balance` (long), `playerKills` (int), `deaths` (int), `zombieKills` (int), `zombieMeleeKills` (int), `linkedAt` (LocalDateTime, not null), `lastActivity` (LocalDateTime)
    - Incluir anotaciones JPA: `@Entity`, `@Table(name = "player_profiles")`, `@Id`, `@GeneratedValue`, `@Column`
    - _Requisitos: 2.5, 13.3_
  - [x] 2.3 Crear la entidad JPA CurrencyTransaction
    - Crear clase `CurrencyTransaction` con campos: `id` (Long, auto-generado), `playerProfile` (ManyToOne, LAZY), `type` (TransactionType, EnumType.STRING), `amount` (long), `balanceAfter` (long), `description` (String), `createdAt` (LocalDateTime)
    - _Requisitos: 5.5, 9.2_
  - [x] 2.4 Crear la entidad JPA EconomyConfig
    - Crear clase `EconomyConfig` con campos: `id` (Long, auto-generado), `guildId` (String, unique, not null), `coinsPerZombieKill` (int, default 10), `meleeWeapons` (String, length 2000, CSV), `enabled` (boolean, default true)
    - _Requisitos: 5.4, 11.1_

- [x] 3. Crear repositorios Spring Data JPA
  - [x] 3.1 Crear PlayerProfileRepository
    - Extender `JpaRepository<PlayerProfile, Long>` con métodos: `findByDiscordId`, `findByDayzPlayerName`, `findByDayzPlayerNameIgnoreCase`, `findTop10ByOrderByPlayerKillsDesc`, `findTop10ByOrderByZombieKillsDesc`, `findTop10ByOrderByBalanceDesc`, y query personalizada `findTop10ByKdRatio` con `@Query` y `Pageable`
    - _Requisitos: 2.1, 10.1, 10.2, 10.3, 10.4_
  - [x] 3.2 Crear CurrencyTransactionRepository
    - Extender `JpaRepository<CurrencyTransaction, Long>` con métodos: `findTop10ByPlayerProfileOrderByCreatedAtDesc`, `findAllByOrderByCreatedAtDesc` con `Pageable`
    - _Requisitos: 9.1, 12.3_
  - [x] 3.3 Crear EconomyConfigRepository
    - Extender `JpaRepository<EconomyConfig, Long>` con método `findByGuildId`
    - _Requisitos: 11.3_

- [x] 4. Implementar servicios del dominio
  - [x] 4.1 Implementar PlayerLinkService
    - Crear servicio con métodos: `linkPlayer(discordId, dayzName)` (verifica unicidad de nombre DayZ, reemplaza vinculación existente), `unlinkPlayer(discordId)`, `findByDiscordId(discordId)`, `findByDayzName(dayzName)`, `isDayzNameTaken(dayzName)`
    - Lanzar `DayzNameAlreadyLinkedException` cuando el nombre DayZ ya está vinculado a otro Discord ID
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5_
  - [ ]* 4.2 Escribir tests de propiedades para PlayerLinkService
    - **Propiedad 4: Unicidad de vinculación de nombre DayZ** — Para dos Discord IDs distintos y un mismo nombre DayZ, el segundo intento debe ser rechazado
    - **Propiedad 5: Round-trip vincular/desvincular** — Vincular y desvincular resulta en ninguna asociación
    - **Propiedad 6: Re-vinculación reemplaza la anterior** — Vincular dos nombres distintos resulta en solo el segundo asociado
    - **Valida: Requisitos 2.2, 2.1, 2.3, 2.4**
  - [ ]* 4.3 Escribir tests unitarios para PlayerLinkService
    - Test de vinculación exitosa, rechazo por nombre duplicado, desvinculación, re-vinculación, búsqueda por Discord ID y por nombre DayZ
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5_
  - [x] 4.4 Implementar EconomyService
    - Crear servicio con métodos `@Transactional`: `creditCoins(profile, amount, type, description)` y `debitCoins(profile, amount, type, description)` que actualizan balance y crean transacción atómicamente
    - Implementar `getBalance(discordId)`, `getRecentTransactions(profile)`, `getAllTransactions(pageable)`
    - Implementar `getConfig(guildId)` (con creación de config por defecto si no existe), `updateConfig(guildId, dto)` con validación de `coinsPerZombieKill > 0`
    - Implementar `isMeleeWeapon(weapon, guildId)` que consulta la lista CSV de armas melee de la config
    - Lanzar `InvalidAmountException` para cantidades ≤ 0, `InsufficientBalanceException` para débitos que exceden balance
    - _Requisitos: 5.1, 5.4, 5.5, 7.1, 7.2, 7.4, 7.5, 8.1, 9.1, 11.3, 11.4, 11.5, 14.4_
  - [ ]* 4.5 Escribir tests de propiedades para EconomyService
    - **Propiedad 8: Clasificación correcta de armas melee** — `isMeleeWeapon` retorna true sii el arma está en la lista configurada
    - **Propiedad 11: Crédito incrementa balance correctamente** — Balance final = B + A
    - **Propiedad 12: Débito decrementa balance correctamente** — Balance final = B - A (cuando A ≤ B)
    - **Propiedad 13: Débito rechazado cuando excede balance** — Balance permanece en B cuando A > B
    - **Propiedad 14: Cantidades no positivas son rechazadas** — Crédito y débito rechazan cantidades ≤ 0
    - **Propiedad 18: Transacciones en orden cronológico descendente** — Máximo 10, ordenadas de más reciente a más antigua
    - **Propiedad 19: Atomicidad de operaciones** — `balanceAfter` de la transacción coincide con el balance actual del jugador
    - **Valida: Requisitos 5.4, 7.1, 7.2, 7.4, 7.5, 9.1, 9.2, 11.5, 14.4**
  - [ ]* 4.6 Escribir tests unitarios para EconomyService
    - Test de crédito exitoso, débito exitoso, débito rechazado por balance insuficiente, cantidad inválida, obtener config por defecto, actualizar config, clasificación de armas melee
    - _Requisitos: 7.1, 7.2, 7.4, 7.5, 11.3, 11.4, 11.5_
  - [x] 4.7 Implementar PlayerStatsService
    - Crear servicio con métodos: `incrementPlayerKills(killerName)`, `incrementDeaths(victimName)`, `incrementZombieKills(playerName)`, `incrementZombieMeleeKills(playerName)` — buscan por nombre DayZ (case-insensitive) y actualizan `lastActivity`
    - Implementar `getStats(discordId)`, `getTopKills()`, `getTopZombieKills()`, `getTopBalance()`, `getTopKd()`, `getAllLinkedPlayers()`
    - Implementar cálculo de K/D ratio: `kills/deaths` con 2 decimales si deaths > 0, "N/A" si deaths = 0
    - _Requisitos: 3.4, 10.1, 10.2, 10.3, 10.4, 12.1, 12.2, 13.1, 13.2, 13.3, 13.4_
  - [ ]* 4.8 Escribir tests de propiedades para PlayerStatsService
    - **Propiedad 7: Cálculo correcto de K/D ratio** — kills/deaths con 2 decimales si deaths > 0, "N/A" si deaths = 0
    - **Propiedad 16: Leaderboards retornan top 10 correctamente ordenados** — Máximo 10 jugadores, ordenados de mayor a menor
    - **Propiedad 17: Leaderboard K/D filtra por mínimo de muertes** — Solo jugadores con ≥ 5 muertes
    - **Propiedad 20: Incremento correcto de estadísticas por kill de jugador** — playerKills del atacante +1, deaths de la víctima +1
    - **Valida: Requisitos 3.4, 10.1, 10.2, 10.3, 10.4, 13.1**
  - [ ]* 4.9 Escribir tests unitarios para PlayerStatsService
    - Test de incremento de kills, muertes, zombie kills, cálculo K/D, leaderboards con menos de 10 jugadores, jugador no encontrado
    - _Requisitos: 13.1, 13.2, 13.3, 10.1, 10.2, 10.3, 10.4_

- [x] 5. Checkpoint — Verificar que la capa de persistencia y servicios funciona
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 6. Implementar parser de kills de zombies y servicio de recompensas
  - [x] 6.1 Crear el record ZombieKillEvent
    - Crear record `ZombieKillEvent(String playerName, String zombieType, String weapon, double playerX, double playerY, double playerZ, String timestamp, int lineIndex)` en paquete `economy.model`
    - _Requisitos: 4.2_
  - [x] 6.2 Implementar ZombieKillParser
    - Crear componente `@Component` con regex para detectar líneas de kill de zombie: `^(\d{2}:\d{2}:\d{2}) \| Player "(.+?)" \(id=.+? pos=<([\d.]+), ([\d.]+), ([\d.]+)>\) killed (Zmb\w+)` con extensión opcional para arma `with (.+)`
    - Implementar `parseZombieKills(String logContent)` que retorna `List<ZombieKillEvent>`, omitiendo líneas malformadas con log WARN
    - Implementar `parseLine(String line, int lineIndex)` que retorna `Optional<ZombieKillEvent>`
    - Implementar `formatZombieKillEvent(ZombieKillEvent event)` para validar round-trip
    - _Requisitos: 4.1, 4.2, 4.3, 4.4, 4.5_
  - [ ]* 6.3 Escribir tests de propiedades para ZombieKillParser
    - **Propiedad 1: Round-trip del ZombieKillParser** — Formatear y parsear de vuelta produce evento equivalente
    - **Propiedad 2: No confunde kills de jugadores con kills de zombies** — Líneas de player kill no producen ZombieKillEvent, y viceversa con LogParser
    - **Propiedad 3: Líneas malformadas no interrumpen el parsing** — Strings aleatorios retornan Optional.empty() sin excepciones
    - **Valida: Requisitos 4.2, 4.3, 4.4, 4.5**
  - [ ]* 6.4 Escribir tests unitarios para ZombieKillParser
    - Test con líneas válidas de zombie kill, líneas de player kill (no deben matchear), líneas vacías, campos numéricos malformados, log con mezcla de líneas válidas e inválidas
    - _Requisitos: 4.1, 4.2, 4.4, 4.5_
  - [x] 6.5 Implementar ZombieKillRewardService
    - Crear servicio con método `processZombieKills(List<ZombieKillEvent> events, String guildId)` que para cada evento: incrementa zombie kills en stats, verifica si jugador está vinculado, verifica si arma es melee, acredita monedas si aplica
    - Usar `PlayerLinkService`, `EconomyService`, y `PlayerStatsService` como dependencias
    - _Requisitos: 5.1, 5.2, 5.3, 5.4, 5.5_
  - [ ]* 6.6 Escribir tests de propiedades para ZombieKillRewardService
    - **Propiedad 9: Recompensa zombie melee acredita monedas y crea transacción** — Balance incrementa en `coinsPerZombieKill`, transacción tipo ZOMBIE_KILL_REWARD
    - **Propiedad 10: Kill con arma no-melee no otorga monedas** — Balance sin cambios, zombieKills +1
    - **Propiedad 21: Configuración actualizada se aplica inmediatamente** — Cambiar `coinsPerZombieKill` a N, siguiente kill otorga N monedas
    - **Valida: Requisitos 5.1, 5.2, 5.5, 11.4**
  - [ ]* 6.7 Escribir tests unitarios para ZombieKillRewardService
    - Test de recompensa con melee, sin melee, jugador no vinculado, sistema deshabilitado
    - _Requisitos: 5.1, 5.2, 5.3_

- [x] 7. Implementar ZombieKillScheduler
  - [x] 7.1 Crear ZombieKillScheduler
    - Crear componente `@Component` con `@Scheduled(fixedRate = 300000)` que descarga logs ADM via `NitradoApiClient`, parsea con `ZombieKillParser`, filtra duplicados usando estado de último evento procesado (timestamp + lineIndex), y delega a `ZombieKillRewardService`
    - Manejar errores de Nitrado (connection, auth, server) con log WARN sin re-throw
    - Omitir ciclo si log content es null o vacío
    - Procesar eventos en orden cronológico
    - _Requisitos: 6.1, 6.2, 6.3, 6.4, 6.5, 14.1, 14.3_
  - [ ]* 7.2 Escribir tests de propiedades para ZombieKillScheduler
    - **Propiedad 15: No se procesan duplicados entre ciclos de polling** — Mismo contenido procesado dos veces no genera recompensas duplicadas
    - **Valida: Requisitos 6.2**
  - [ ]* 7.3 Escribir tests unitarios para ZombieKillScheduler
    - Test de ciclo exitoso, log vacío, error de Nitrado (no interrumpe), filtrado de duplicados, procesamiento en orden cronológico
    - _Requisitos: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 8. Checkpoint — Verificar parser, recompensas y scheduler
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 9. Implementar comandos de Discord
  - [x] 9.1 Implementar VincularCommand y DesvincularCommand
    - Crear `VincularCommand` implementando `SlashCommand`: comando `/vincular` con opción `nombre` (STRING, required). Usa `PlayerLinkService.linkPlayer()`. Maneja `DayzNameAlreadyLinkedException` con mensaje de error
    - Crear `DesvincularCommand` implementando `SlashCommand`: comando `/desvincular`. Usa `PlayerLinkService.unlinkPlayer()`. Maneja caso de no vinculado con `PlayerNotLinkedException`
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 14.2_
  - [x] 9.2 Implementar EstatusCommand
    - Crear `EstatusCommand` implementando `SlashCommand`: comando `/estatus` con opción opcional `usuario` (USER). Muestra embed con: nombre DayZ, kills, muertes, K/D ratio, zombie kills, balance TNT Coins
    - Manejar caso sin cuenta vinculada, y consulta de stats de otro usuario mencionado
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 14.2_
  - [x] 9.3 Implementar BalanceCommand y TransaccionesCommand
    - Crear `BalanceCommand`: comando `/balance`. Muestra balance formateado con separador de miles. Maneja caso sin cuenta vinculada
    - Crear `TransaccionesCommand`: comando `/transacciones`. Muestra últimas 10 transacciones con tipo, cantidad, fecha/hora, descripción. Maneja caso sin transacciones y sin cuenta vinculada
    - _Requisitos: 8.1, 8.2, 8.3, 9.1, 9.2, 9.3, 9.4, 14.2_
  - [x] 9.4 Implementar TopCommand
    - Crear `TopCommand` implementando `SlashCommand`: comando `/top` con subcomandos `kills`, `zombies`, `ricos`, `kd`. Muestra embed con top 10 jugadores para cada categoría
    - Incluir posición del usuario que ejecuta el comando si no aparece en el top 10
    - _Requisitos: 10.1, 10.2, 10.3, 10.4, 10.5, 14.2_
  - [x] 9.5 Implementar EconomiaCommand
    - Crear `EconomiaCommand` implementando `SlashCommand`: comando `/economia` con subcomandos `dar` y `quitar`, opciones `usuario` (USER, required) y `cantidad` (INTEGER, required)
    - Verificar permisos de administrador. Manejar: usuario no vinculado, cantidad ≤ 0, balance insuficiente para débito
    - _Requisitos: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 14.2_
  - [x] 9.6 Registrar los nuevos comandos en el CommandRegistry/BotInitializer
    - Asegurar que todos los nuevos comandos se registran como beans de Spring y se incluyen en la lista de comandos slash del bot
    - _Requisitos: 2.1, 3.1, 7.1, 8.1, 9.1, 10.1_
  - [ ]* 9.7 Escribir tests unitarios para los comandos de Discord
    - Tests con mocking de JDA `SlashCommandInteractionEvent` para cada comando: respuestas correctas para jugador vinculado, no vinculado, permisos insuficientes, errores internos
    - _Requisitos: 2.1, 2.2, 3.1, 3.2, 7.1, 7.3, 8.1, 8.2, 9.1, 9.4, 10.1, 14.2_

- [x] 10. Implementar controladores REST y DTOs
  - [x] 10.1 Crear DTOs para la API REST
    - Crear records: `PlayerStatsDto`, `TransactionDto`, `EconomyConfigDto`, `EconomyConfigUpdateDto` (con validación `@Positive` en `coinsPerZombieKill`)
    - _Requisitos: 11.1, 12.1, 12.2, 12.3_
  - [x] 10.2 Implementar EconomyConfigController
    - Crear `@RestController` con `@RequestMapping("/api/economy")`: `GET /config` (con `@RequestParam guildId`), `PUT /config` (con `@RequestBody @Valid EconomyConfigUpdateDto`), `GET /transactions` (con paginación `page` y `size`)
    - _Requisitos: 11.3, 11.4, 11.5, 12.3_
  - [x] 10.3 Implementar PlayerStatsController
    - Crear `@RestController` con `@RequestMapping("/api/players")`: `GET /stats` (lista todos los jugadores vinculados), `GET /{discordId}/stats` (estadísticas de un jugador específico)
    - _Requisitos: 12.1, 12.2_
  - [x] 10.4 Implementar manejo global de errores con @ControllerAdvice
    - Crear `EconomyExceptionHandler` con `@ControllerAdvice` que maneje `PlayerNotLinkedException` (404), `InsufficientBalanceException` (400), `InvalidAmountException` (400), `DayzNameAlreadyLinkedException` (409), y excepciones genéricas (500)
    - _Requisitos: 14.2_
  - [ ]* 10.5 Escribir tests unitarios para controladores REST
    - Tests con `@WebMvcTest` y `MockMvc` para cada endpoint: respuestas correctas, validación de DTOs, manejo de errores HTTP
    - _Requisitos: 11.3, 11.5, 12.1, 12.2, 12.3_

- [x] 11. Checkpoint — Verificar backend completo
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 12. Implementar pantallas Flutter para economía y estadísticas
  - [x] 12.1 Crear modelos Dart para economía y estadísticas
    - Crear `economy_config_model.dart` con clase `EconomyConfigModel` (coinsPerZombieKill, meleeWeapons, enabled) con métodos `fromJson`/`toJson`
    - Crear `player_stats_model.dart` con clase `PlayerStatsModel` (discordId, dayzPlayerName, playerKills, deaths, kdRatio, zombieKills, zombieMeleeKills, balance, lastActivity) con método `fromJson`
    - _Requisitos: 11.1, 12.4_
  - [x] 12.2 Agregar métodos de API al BackendApiClient para economía y estadísticas
    - Agregar métodos: `getEconomyConfig(guildId)`, `updateEconomyConfig(guildId, config)`, `getPlayerStats()`, `getPlayerStatsById(discordId)`, `getTransactions(page, size)` al `BackendApiClient`
    - _Requisitos: 11.2, 11.3, 12.1, 12.2, 12.3_
  - [x] 12.3 Crear providers de Riverpod para economía y estadísticas
    - Crear `economy_config_provider.dart` con provider para obtener y actualizar la configuración de economía
    - Crear `player_stats_provider.dart` con provider para obtener la lista de jugadores y estadísticas individuales
    - _Requisitos: 11.1, 11.2, 12.4_
  - [x] 12.4 Implementar pantalla de configuración de economía
    - Crear `economy_config_screen.dart` con formulario editable: campo numérico para monedas por kill, editor de lista de armas melee, toggle para habilitar/deshabilitar sistema
    - Crear widgets auxiliares: `melee_weapons_editor.dart` (lista editable de armas), `economy_toggle_card.dart` (switch de habilitación)
    - Enviar actualizaciones al backend al guardar cambios
    - _Requisitos: 11.1, 11.2_
  - [x] 12.5 Implementar pantalla de estadísticas de jugadores
    - Crear `player_stats_screen.dart` con tabla de jugadores vinculados mostrando: nombre DayZ, kills, muertes, K/D, zombie kills, balance
    - Crear widgets auxiliares: `player_stats_card.dart` (detalle de jugador), `stats_table.dart` (tabla resumen)
    - _Requisitos: 12.4_

- [x] 13. Integración final y verificación completa
  - [x] 13.1 Conectar pantallas Flutter a la navegación de la app
    - Agregar rutas y entradas de menú para las nuevas pantallas de configuración de economía y estadísticas de jugadores en la app Flutter existente
    - _Requisitos: 11.1, 12.4_
  - [ ]* 13.2 Escribir tests de integración del flujo completo
    - Test de integración con H2: parsear log → detectar kill de zombie → acreditar monedas → verificar balance y transacción
    - Test de startup de la aplicación verificando que el esquema de base de datos se crea correctamente
    - _Requisitos: 1.3, 5.1, 5.5, 14.4_

- [x] 14. Checkpoint final — Verificar que todo el sistema funciona
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia requisitos específicos para trazabilidad
- Los checkpoints aseguran validación incremental
- Los tests de propiedades validan propiedades universales de correctitud definidas en el diseño
- Los tests unitarios validan ejemplos específicos y edge cases
- El backend usa Java 17 + Spring Boot 3.4 + JDA 5.x
- La app Flutter usa Dart con Riverpod para state management
- jqwik ya está configurado en build.gradle para property-based testing
