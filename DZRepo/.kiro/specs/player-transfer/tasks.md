# Plan de Implementación: Transferencia de TNT Coins entre Jugadores

## Resumen

Este plan convierte el diseño de transferencia de TNT Coins en tareas incrementales de codificación. El orden sigue las dependencias: primero los nuevos tipos de transacción y excepciones, luego el record de resultado, el método de transferencia en el servicio, el comando slash `/transferir`, la actualización del comando `/transacciones`, y finalmente los tests. Cada tarea construye sobre las anteriores y no deja código huérfano.

## Tareas

- [x] 1. Extender el modelo de dominio con nuevos tipos y excepciones
  - [x] 1.1 Agregar PLAYER_TRANSFER_SENT y PLAYER_TRANSFER_RECEIVED al enum TransactionType
    - Abrir `discord-bot-backend/src/main/java/com/discord/bot/economy/model/TransactionType.java`
    - Agregar `PLAYER_TRANSFER_SENT` con Javadoc "Coins sent to another player via /transferir"
    - Agregar `PLAYER_TRANSFER_RECEIVED` con Javadoc "Coins received from another player via /transferir"
    - _Requisitos: 1.3, 1.4, 5.1, 5.2_
  - [x] 1.2 Crear la excepción SelfTransferException
    - Crear `SelfTransferException` en `discord-bot-backend/src/main/java/com/discord/bot/economy/exception/SelfTransferException.java`
    - Extender `RuntimeException` con constructor que recibe `String message`
    - Seguir el patrón de las excepciones existentes (`InvalidAmountException`, `InsufficientBalanceException`)
    - _Requisitos: 3.2_
  - [x] 1.3 Crear el record TransferResult
    - Crear `TransferResult` en `discord-bot-backend/src/main/java/com/discord/bot/economy/model/TransferResult.java`
    - Definir como `public record TransferResult(CurrencyTransaction senderTransaction, CurrencyTransaction receiverTransaction)`
    - Incluir Javadoc describiendo que contiene los registros de transacción del emisor y receptor
    - _Requisitos: 1.1, 1.3, 1.4_

- [x] 2. Implementar la lógica de transferencia en EconomyService
  - [x] 2.1 Agregar el método transferCoins a EconomyService
    - Abrir `discord-bot-backend/src/main/java/com/discord/bot/economy/service/EconomyService.java`
    - Agregar método `@Transactional public TransferResult transferCoins(PlayerProfile sender, PlayerProfile receiver, long amount)`
    - Validar `amount > 0` → lanzar `InvalidAmountException` si no
    - Validar `sender != receiver` (comparar por ID) → lanzar `SelfTransferException` si son iguales
    - Validar `sender.getBalance() >= amount` → lanzar `InsufficientBalanceException` si no
    - Debitar al emisor: `sender.setBalance(sender.getBalance() - amount)`, guardar con `playerProfileRepository.save(sender)`
    - Crear transacción SENT: `new CurrencyTransaction(sender, PLAYER_TRANSFER_SENT, amount, sender.getBalance(), "Transferencia enviada a " + receiver.getDayzPlayerName(), LocalDateTime.now())`
    - Acreditar al receptor: `receiver.setBalance(receiver.getBalance() + amount)`, guardar con `playerProfileRepository.save(receiver)`
    - Crear transacción RECEIVED: `new CurrencyTransaction(receiver, PLAYER_TRANSFER_RECEIVED, amount, receiver.getBalance(), "Transferencia recibida de " + sender.getDayzPlayerName(), LocalDateTime.now())`
    - Retornar `new TransferResult(savedSentTx, savedReceivedTx)`
    - _Requisitos: 1.1, 1.3, 1.4, 2.2, 2.3, 3.2, 4.1, 4.2, 4.3, 5.1, 5.2_
  - [ ]* 2.2 Escribir test de propiedad: Conservación de monedas en transferencia
    - Crear `TransferCoinsPropertyTest` en `discord-bot-backend/src/test/java/com/discord/bot/economy/service/TransferCoinsPropertyTest.java`
    - Configurar con `@DataJpaTest` y `@AddPackage` de jqwik-spring para inyectar repositorios reales con H2
    - **Propiedad 1: Conservación de monedas en transferencia** — Para balances iniciales `Bs` y `Br` y cantidad válida `A` donde `0 < A ≤ Bs`, después de `transferCoins`, la suma `sender.balance + receiver.balance == Bs + Br`
    - **Valida: Requisitos 4.3, 1.1**
  - [ ]* 2.3 Escribir test de propiedad: Débito y crédito exactos en transferencia
    - **Propiedad 2: Débito y crédito exactos** — Después de `transferCoins(sender, receiver, A)`, `sender.balance == Bs - A` y `receiver.balance == Br + A`
    - **Valida: Requisitos 1.1**
  - [ ]* 2.4 Escribir test de propiedad: Registros de transacción correctos
    - **Propiedad 3: Registros de transacción correctos** — La transferencia crea exactamente dos transacciones: una `PLAYER_TRANSFER_SENT` para el emisor con cantidad `A` y descripción conteniendo el nombre DayZ del receptor, y una `PLAYER_TRANSFER_RECEIVED` para el receptor con cantidad `A` y descripción conteniendo el nombre DayZ del emisor
    - **Valida: Requisitos 1.3, 1.4, 5.1, 5.2**
  - [ ]* 2.5 Escribir test de propiedad: Rechazo de transferencia con balance insuficiente
    - **Propiedad 4: Rechazo balance insuficiente** — Para cantidad `A > sender.balance`, `transferCoins` lanza `InsufficientBalanceException` y el balance del emisor permanece sin cambios
    - **Valida: Requisitos 2.2**
  - [ ]* 2.6 Escribir test de propiedad: Rechazo de cantidades no positivas
    - **Propiedad 5: Rechazo cantidades no positivas** — Para cantidad `A ≤ 0`, `transferCoins` lanza `InvalidAmountException` sin modificar balances
    - **Valida: Requisitos 2.3**
  - [ ]* 2.7 Escribir test de propiedad: Rechazo de auto-transferencia
    - **Propiedad 6: Rechazo auto-transferencia** — Cuando emisor y receptor son el mismo perfil, `transferCoins` lanza `SelfTransferException` sin modificar el balance
    - **Valida: Requisitos 3.2**

- [x] 3. Checkpoint — Verificar que el modelo y servicio de transferencia funcionan
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 4. Implementar el comando slash /transferir
  - [x] 4.1 Crear TransferirCommand
    - Crear `TransferirCommand` en `discord-bot-backend/src/main/java/com/discord/bot/economy/command/TransferirCommand.java`
    - Implementar `SlashCommand` con `@Component`, inyectar `EconomyService` y `PlayerLinkService`
    - `getName()` retorna `"transferir"`, `getDescription()` retorna `"Transfiere TNT Coins a otro jugador"`
    - `getCommandData()` retorna comando con opciones: `usuario` (USER, required) y `cantidad` (INTEGER, required)
    - En `execute()`:
      - Obtener `targetUser` y `cantidad` de las opciones del evento
      - Validar que `targetUser` no sea bot → responder "❌ No puedes transferir monedas a un bot." ephemeral
      - Validar que emisor ≠ receptor (comparar Discord IDs) → responder "❌ No puedes transferirte monedas a ti mismo." ephemeral
      - Buscar perfil del emisor con `playerLinkService.findByDiscordId(event.getUser().getId())` → si vacío, responder "❌ Debes vincular tu cuenta primero con `/vincular`." ephemeral
      - Buscar perfil del receptor con `playerLinkService.findByDiscordId(targetUser.getId())` → si vacío, responder "❌ El usuario no tiene una cuenta vinculada." ephemeral
      - Llamar `economyService.transferCoins(senderProfile, receiverProfile, cantidad)`
      - En éxito: responder con embed verde (0x2ECC71) mostrando: título "✅ Transferencia Exitosa", campos Emisor (mention), Receptor (mention), Cantidad, Nuevo balance emisor, Nuevo balance receptor
      - Capturar `InvalidAmountException` → "❌ La cantidad debe ser un número positivo." ephemeral
      - Capturar `InsufficientBalanceException` → "❌ Balance insuficiente. Tu balance actual es: X TNT Coins." ephemeral
      - Capturar `SelfTransferException` → "❌ No puedes transferirte monedas a ti mismo." ephemeral
      - Capturar `Exception` genérica → log error + "❌ Ocurrió un error interno. Intenta de nuevo." ephemeral
    - Seguir el patrón de `EconomiaCommand` para formato de embeds y manejo de errores
    - _Requisitos: 1.1, 1.2, 2.1, 2.2, 2.3, 3.1, 3.2, 6.1, 6.2_
  - [ ]* 4.2 Escribir tests unitarios para TransferirCommand
    - Crear `TransferirCommandTest` en `discord-bot-backend/src/test/java/com/discord/bot/economy/command/TransferirCommandTest.java`
    - Usar mocking de JDA `SlashCommandInteractionEvent` siguiendo el patrón de tests existentes
    - Tests: transferencia exitosa (verificar embed con campos requeridos), rechazo emisor no vinculado, rechazo receptor no vinculado, rechazo receptor es bot, rechazo emisor = receptor, rechazo cantidad no positiva, rechazo balance insuficiente, mensaje genérico en error interno
    - _Requisitos: 1.1, 1.2, 2.1, 2.2, 2.3, 3.1, 3.2, 6.1, 6.2_

- [x] 5. Actualizar TransaccionesCommand para mostrar los nuevos tipos de transacción
  - [x] 5.1 Agregar labels y emojis para PLAYER_TRANSFER_SENT y PLAYER_TRANSFER_RECEIVED
    - Abrir `discord-bot-backend/src/main/java/com/discord/bot/economy/command/TransaccionesCommand.java`
    - En el método `translateTransactionType`, agregar cases: `PLAYER_TRANSFER_SENT` → "📤 Transferencia Enviada", `PLAYER_TRANSFER_RECEIVED` → "📥 Transferencia Recibida"
    - En el método `isDebitType`, agregar `PLAYER_TRANSFER_SENT` como tipo de débito (muestra con prefijo "-")
    - _Requisitos: 5.3_

- [x] 6. Checkpoint final — Verificar que todo el sistema de transferencias funciona
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia requisitos específicos para trazabilidad
- Los checkpoints aseguran validación incremental
- Los tests de propiedades validan propiedades universales de correctitud definidas en el diseño (jqwik)
- Los tests unitarios validan ejemplos específicos y edge cases (JUnit 5)
- El backend usa Java 17 + Spring Boot 3.4 + JDA 5.x + Spring Data JPA
- No se requieren cambios en el esquema de base de datos — los nuevos TransactionType se almacenan como STRING en la columna existente
