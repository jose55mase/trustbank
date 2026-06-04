# Plan de Implementación: Comandos Discord-Nitrado

## Visión General

Este plan implementa los comandos slash `/restart` y `/stop` para controlar servidores DayZ alojados en Nitrado desde Discord. La implementación sigue un enfoque incremental: primero la clase base abstracta con la lógica compartida, luego los comandos concretos, después la integración con el sistema existente de comandos, y finalmente los tests. El lenguaje de implementación es Java 17 con Spring Boot, JDA 5.x, JUnit 5 y jqwik.

## Tareas

- [x] 1. Crear la clase abstracta `AbstractServerCommand`
  - Crear el archivo `discord-bot-backend/src/main/java/com/discord/bot/command/AbstractServerCommand.java`
  - La clase debe implementar `SlashCommand` y recibir `NitradoApiClient` por constructor
  - Definir los métodos abstractos: `getAction()` (retorna `ServerAction`), `getSuccessMessage(String serverName)` (retorna `String`)
  - Implementar el método `execute(SlashCommandInteractionEvent event)` con la lógica completa:
    - Verificación de permisos: comprobar que `event.getMember()` no sea null (Req 3.2) y que tenga `Permission.ADMINISTRATOR` (Req 3.1)
    - Respuestas efímeras de denegación cuando no hay permisos (Req 1.4, 2.4)
    - Respuesta diferida con `event.deferReply().queue()` antes de llamadas a Nitrado (Req 6.1)
    - Obtención de servidores con `nitradoApiClient.getServers()` (Req 4.1)
    - Lógica de selección: 0 servidores → mensaje de error (Req 4.4), 1 servidor → ejecución directa (Req 4.2), 2+ servidores → lista informativa (Req 4.3)
    - Ejecución de `nitradoApiClient.serverAction(serviceId, getAction())` para servidor único
    - Actualización de respuesta diferida con `event.getHook().editOriginal()` (Req 6.2)
    - Manejo de excepciones: `NitradoConnectionException` (Req 5.1), `NitradoAuthException` (Req 5.2), `NitradoNotFoundException` (Req 5.3), `NitradoApiException` y `Exception` genérica (Req 5.4)
    - Logging de errores con SLF4J
  - _Requisitos: 1.1, 1.4, 2.1, 2.4, 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2_

- [x] 2. Crear los comandos concretos `RestartCommand` y `StopCommand`
  - [x] 2.1 Crear `RestartCommand`
    - Crear el archivo `discord-bot-backend/src/main/java/com/discord/bot/command/RestartCommand.java`
    - Anotar con `@Component` para auto-registro en Spring
    - Extender `AbstractServerCommand`, inyectar `NitradoApiClient` por constructor
    - Implementar `getName()` retornando `"restart"`
    - Implementar `getDescription()` retornando `"Reinicia el servidor DayZ (solo administradores)"`
    - Implementar `getAction()` retornando `ServerAction.RESTART`
    - Implementar `getSuccessMessage(String serverName)` con mensaje de confirmación de reinicio
    - _Requisitos: 1.2, 1.3, 7.2_

  - [x] 2.2 Crear `StopCommand`
    - Crear el archivo `discord-bot-backend/src/main/java/com/discord/bot/command/StopCommand.java`
    - Anotar con `@Component` para auto-registro en Spring
    - Extender `AbstractServerCommand`, inyectar `NitradoApiClient` por constructor
    - Implementar `getName()` retornando `"stop"`
    - Implementar `getDescription()` retornando `"Detiene el servidor DayZ (solo administradores)"`
    - Implementar `getAction()` retornando `ServerAction.STOP`
    - Implementar `getSuccessMessage(String serverName)` con mensaje de confirmación de detención
    - _Requisitos: 2.2, 2.3, 7.2_

- [x] 3. Checkpoint - Verificar compilación
  - Ejecutar `./gradlew compileJava` en `discord-bot-backend/` para asegurar que todo compila correctamente
  - Verificar que `RestartCommand` y `StopCommand` se registran automáticamente en `CommandHandler` gracias a la inyección de Spring (Req 7.1)
  - Asegurar que no hay errores de compilación. Preguntar al usuario si surgen dudas.

- [x] 4. Tests unitarios para los comandos
  - [x] 4.1 Crear tests unitarios para `AbstractServerCommand` vía `RestartCommand`
    - Crear el archivo `discord-bot-backend/src/test/java/com/discord/bot/command/RestartCommandTest.java`
    - Configurar mocks de JDA: `SlashCommandInteractionEvent`, `Member`, `InteractionHook`, `ReplyCallbackAction`
    - Configurar mock de `NitradoApiClient`
    - Tests a implementar:
      - `getName()` retorna `"restart"` (Req 1.2)
      - `getDescription()` no está vacío y está en español (Req 7.2)
      - Usuario sin `Permission.ADMINISTRATOR` recibe respuesta efímera de denegación (Req 1.4, 3.1)
      - Comando ejecutado fuera de guild (`member == null`) recibe respuesta efímera (Req 3.2)
      - Con 1 servidor: invoca `serverAction` con `ServerAction.RESTART` y responde con mensaje de éxito (Req 1.2, 1.3, 4.2)
      - Con 0 servidores: responde con mensaje de "no se encontraron servidores" (Req 4.4)
      - Con 2+ servidores: responde con lista de servidores (Req 4.3)
      - `deferReply()` se invoca antes de las llamadas a Nitrado (Req 6.1)
      - `editOriginal()` se invoca con el resultado final (Req 6.2)
      - `NitradoConnectionException` → mensaje de error de conexión (Req 5.1)
      - `NitradoAuthException` → mensaje de error de autenticación (Req 5.2)
      - `NitradoNotFoundException` → mensaje de servidor no encontrado (Req 5.3)
      - Excepción genérica → mensaje de error genérico (Req 5.4)
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 3.1, 3.2, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 7.2_

  - [ ]* 4.2 Crear tests unitarios para `StopCommand`
    - Crear el archivo `discord-bot-backend/src/test/java/com/discord/bot/command/StopCommandTest.java`
    - Tests análogos a `RestartCommandTest` pero verificando `ServerAction.STOP` y mensajes de detención
    - _Requisitos: 2.1, 2.2, 2.3, 2.4_

- [x] 5. Tests de propiedades (jqwik)
  - [ ]* 5.1 Test de propiedad: Control de acceso por rol de administrador
    - Crear el archivo `discord-bot-backend/src/test/java/com/discord/bot/command/ServerCommandAccessControlPropertyTest.java`
    - **Propiedad 1: Control de acceso por rol de administrador**
    - Generar combinaciones aleatorias de: tipo de comando (restart/stop), presencia de permisos de administrador (true/false), member null o no null
    - Verificar que `serverAction` se invoca si y solo si el usuario tiene `Permission.ADMINISTRATOR`
    - Verificar que sin permisos se recibe respuesta efímera de denegación
    - Mínimo 100 iteraciones
    - **Valida: Requisitos 1.1, 1.4, 2.1, 2.4, 3.1**

  - [ ]* 5.2 Test de propiedad: Auto-selección con servidor único
    - Crear el archivo `discord-bot-backend/src/test/java/com/discord/bot/command/ServerCommandSingleServerPropertyTest.java`
    - **Propiedad 2: Auto-selección con servidor único**
    - Generar `GameServerDto` aleatorios (nombres, IDs, estados variados) en listas de exactamente 1 elemento
    - Verificar que `serverAction` se invoca con el `serviceId` correcto sin solicitar selección
    - Mínimo 100 iteraciones
    - **Valida: Requisitos 4.2**

  - [ ]* 5.3 Test de propiedad: Presentación completa de múltiples servidores
    - Crear el archivo `discord-bot-backend/src/test/java/com/discord/bot/command/ServerCommandMultiServerPropertyTest.java`
    - **Propiedad 3: Presentación completa de múltiples servidores**
    - Generar listas de 2-10 `GameServerDto` con nombres y estados aleatorios
    - Verificar que la respuesta contiene el nombre y estado de cada servidor de la lista
    - Verificar que `serverAction` NO se invoca (no se ejecuta acción automática)
    - Mínimo 100 iteraciones
    - **Valida: Requisitos 4.3**

- [x] 6. Checkpoint final - Verificar compilación y tests
  - Ejecutar `./gradlew test` en `discord-bot-backend/` para asegurar que todos los tests pasan
  - Verificar que no hay errores de compilación ni tests fallidos
  - Asegurar que todos los tests pasan. Preguntar al usuario si surgen dudas.

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia requisitos específicos para trazabilidad
- Los checkpoints aseguran validación incremental
- Los tests de propiedades validan propiedades universales de correctitud definidas en el diseño
- Los tests unitarios validan ejemplos específicos y casos borde
- El registro de los comandos en `CommandHandler` y `CommandRegistry` es automático gracias a la inyección de dependencias de Spring — no requiere modificaciones en `BotInitializer` ni `CommandHandler`
