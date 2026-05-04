# Tareas de Implementación — Kill Feed Discord

## Tarea 1: Modelos de datos (Records)

- [x] 1.1 Crear el record `KillEvent` en `com.discord.bot.killfeed.model` con los campos: killerName, victimName, weapon, distance, killerX, killerY, killerZ, victimX, victimY, victimZ, timestamp, lineIndex
- [x] 1.2 Crear el record `KillFeedConfig` en `com.discord.bot.killfeed.model` con los campos: guildId, channelId, serviceId
- [x] 1.3 Crear el record `LastProcessedState` en `com.discord.bot.killfeed.model` con los campos: timestamp, lineIndex
- [x] 1.4 Crear el record `PollResult` en `com.discord.bot.killfeed.model` con los campos: configsProcessed, newEventsFound, embedsPublished, errors

## Tarea 2: LogParser — Parseo de eventos de muerte

- [x] 2.1 Crear la clase `LogParser` en `com.discord.bot.killfeed.service` con el método `parseKillEvents(String logContent)` que retorna `List<KillEvent>` extrayendo eventos de muerte del log ADM usando regex
- [x] 2.2 Implementar el método `parseLine(String line, int lineIndex)` que retorna `Optional<KillEvent>` para una sola línea de log, omitiendo líneas que no son kills
- [x] 2.3 Implementar el método `formatKillEvent(KillEvent event)` que formatea un KillEvent de vuelta a texto de log para validar la propiedad de ida y vuelta
- [x] 2.4 Implementar manejo de líneas malformadas: registrar advertencia con log WARN y omitir la línea sin interrumpir el procesamiento de las demás
- [x] 2.5 Crear `LogParserTest` con tests unitarios para líneas de ejemplo del formato ADM de DayZ, incluyendo variaciones de formato
- [x] 2.6 [PBT] Crear `LogParserRoundTripPropertyTest` — Feature: kill-feed-discord, Property 1: Para cualquier KillEvent válido, formatear como texto y parsear de vuelta produce un evento equivalente
- [x] 2.7 [PBT] Crear `LogParserKillExtractionPropertyTest` — Feature: kill-feed-discord, Property 2: Para cualquier log mixto, el parser extrae únicamente las líneas de kill
- [x] 2.8 [PBT] Crear `LogParserResiliencePropertyTest` — Feature: kill-feed-discord, Property 3: Para cualquier log con líneas malformadas mezcladas con válidas, el parser extrae las válidas sin lanzar excepciones

## Tarea 3: KillFeedConfigStore — Almacén de configuraciones

- [x] 3.1 Crear la clase `KillFeedConfigStore` en `com.discord.bot.killfeed.store` con ConcurrentHashMap para configs y lastProcessed, implementando saveConfig, getConfig, removeConfig, getAllConfigs
- [x] 3.2 Implementar los métodos getLastProcessed y updateLastProcessed para el control de duplicados
- [x] 3.3 Crear `KillFeedConfigStoreTest` con tests unitarios para: remove sin config existente, getAllConfigs vacío, getConfig inexistente
- [x] 3.4 [PBT] Crear `KillFeedConfigStorePropertyTest` — Feature: kill-feed-discord, Property 4: Para cualquier par de configs con mismo guildId, guardar ambas resulta en la segunda almacenada; Property 5: Para cualquier config almacenada, eliminarla por guildId retorna vacío

## Tarea 4: Filtrado de duplicados

- [x] 4.1 Implementar el método de filtrado de eventos en `KillFeedService` que compara cada KillEvent con el LastProcessedState y retorna solo los eventos nuevos (timestamp posterior o mismo timestamp con lineIndex mayor)
- [x] 4.2 [PBT] Crear `DuplicateFilterPropertyTest` — Feature: kill-feed-discord, Property 6: Para cualquier lista de KillEvents y LastProcessedState, el filtrado retorna únicamente eventos posteriores al estado

## Tarea 5: KillFeedEmbedBuilder — Construcción de embeds

- [x] 5.1 Crear la clase `KillFeedEmbedBuilder` en `com.discord.bot.killfeed.service` con el método `buildEmbed(KillEvent event)` que construye un MessageEmbed con color rojo (#CC0000), icono de calavera, y todos los campos del evento
- [x] 5.2 Implementar el método `createDummyEvent()` que genera un KillEvent con datos ficticios realistas para el comando de prueba
- [x] 5.3 Crear `KillFeedEmbedBuilderTest` con tests unitarios para: color rojo del embed, presencia del icono de calavera, formato de distancia en metros, evento dummy
- [x] 5.4 [PBT] Crear `KillFeedEmbedBuilderPropertyTest` — Feature: kill-feed-discord, Property 7: Para cualquier KillEvent, el embed construido contiene nombre del asesino, víctima, arma, distancia en metros y coordenadas

## Tarea 6: KillFeedService — Servicio de orquestación

- [x] 6.1 Crear la clase `KillFeedService` en `com.discord.bot.killfeed.service` con dependencias a NitradoApiClient, LogParser, KillFeedConfigStore, KillFeedEmbedBuilder y JDA (BotInitializer)
- [x] 6.2 Implementar `pollAllConfigs()` que itera sobre todas las configuraciones activas, descarga logs, parsea eventos, filtra duplicados, publica embeds y retorna PollResult con métricas
- [x] 6.3 Implementar `processConfig(KillFeedConfig config)` con aislamiento de errores: cada config se procesa en su propio try-catch para que un fallo no afecte a las demás
- [x] 6.4 Implementar manejo de errores de Nitrado: NitradoConnectionException (log WARN), NitradoAuthException (log ERROR), NitradoServerException (log ERROR), log vacío (omitir sin error)
- [x] 6.5 Implementar envío de embeds al canal configurado usando JDA, con manejo de canal no encontrado y permisos insuficientes
- [x] 6.6 Crear `KillFeedServiceTest` con tests unitarios para: ciclo de sondeo completo con mocks, aislamiento de errores entre configs, log vacío, errores de Nitrado, canal no encontrado

## Tarea 7: KillFeedScheduler — Tarea programada

- [x] 7.1 Crear la clase `KillFeedScheduler` en `com.discord.bot.killfeed.scheduler` con @Scheduled(fixedRate = 300000) que invoca KillFeedService.pollAllConfigs() y registra métricas del PollResult
- [x] 7.2 Agregar `@EnableScheduling` a la clase principal de la aplicación Spring Boot si no está presente
- [x] 7.3 Crear `KillFeedSchedulerTest` verificando que el scheduler invoca el servicio correctamente

## Tarea 8: KillFeedCommand — Comando slash /killfeed

- [x] 8.1 Crear la clase `KillFeedCommand` en `com.discord.bot.killfeed.command` implementando SlashCommand con nombre "killfeed" y subcomandos setup, remove, test usando SubcommandData de JDA
- [x] 8.2 Implementar subcomando `setup`: verificar permisos de admin, validar serviceId contra NitradoApiClient.getServers(), guardar config en KillFeedConfigStore, responder con confirmación
- [x] 8.3 Implementar subcomando `remove`: verificar permisos de admin, eliminar config del store, responder con confirmación o indicar que no hay config activa
- [x] 8.4 Implementar subcomando `test`: verificar permisos de admin, verificar que existe config, generar evento dummy con KillFeedEmbedBuilder, enviar embed al canal configurado
- [x] 8.5 Implementar verificación de permisos de administrador para todos los subcomandos, respondiendo con mensaje efímero si el usuario no tiene permisos
- [x] 8.6 Crear `KillFeedCommandTest` con tests unitarios para: setup exitoso, setup sin permisos, setup con serviceId inválido, setup sobreescritura, remove exitoso, remove sin config, test exitoso, test sin config, test sin permisos
