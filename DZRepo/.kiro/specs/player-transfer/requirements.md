# Documento de Requisitos — Transferencia de TNT Coins entre Jugadores

## Introducción

Este documento define los requisitos para la funcionalidad de transferencia de TNT Coins entre jugadores. Los jugadores podrán enviar monedas desde su cuenta a la cuenta de otro jugador vinculado mediante un comando slash de Discord. La operación debe ser atómica (débito del emisor + crédito del receptor en una sola transacción de base de datos) y registrar ambos movimientos en el historial de transacciones.

## Glosario

- **Bot_Discord**: Aplicación Spring Boot con JDA 5.x que procesa comandos slash de Discord.
- **Sistema_Economía**: Módulo del backend Spring Boot responsable de gestionar la moneda virtual, transacciones y balances de jugadores.
- **TNT_Coins**: Moneda virtual del sistema de economía que los jugadores ganan al matar zombies con armas cuerpo a cuerpo.
- **Jugador_Vinculado**: Un usuario de Discord que ha asociado su cuenta con su nombre de jugador DayZ en el servidor.
- **Emisor**: El jugador que inicia la transferencia y cuyo balance se reduce.
- **Receptor**: El jugador que recibe la transferencia y cuyo balance se incrementa.
- **Transacción**: Registro inmutable de un cambio en el balance de TNT_Coins de un jugador, incluyendo tipo, cantidad, timestamp y razón.
- **Transferencia**: Operación atómica que debita TNT_Coins del Emisor y acredita la misma cantidad al Receptor.

## Requisitos

### Requisito 1: Comando de Transferencia de TNT Coins

**Historia de Usuario:** Como jugador, quiero enviar TNT Coins a otro jugador mediante un comando de Discord, para poder compartir mis monedas con otros miembros del servidor.

#### Criterios de Aceptación

1. WHEN un Jugador_Vinculado ejecuta `/transferir @usuario <cantidad>`, THE Bot_Discord SHALL debitar la cantidad especificada del balance del Emisor y acreditar la misma cantidad al balance del Receptor.
2. WHEN la transferencia se completa exitosamente, THE Bot_Discord SHALL responder con un embed que muestre: el Emisor, el Receptor, la cantidad transferida, el nuevo balance del Emisor, y el nuevo balance del Receptor.
3. WHEN la transferencia se completa exitosamente, THE Sistema_Economía SHALL crear una Transacción de tipo "PLAYER_TRANSFER_SENT" para el Emisor con la cantidad transferida.
4. WHEN la transferencia se completa exitosamente, THE Sistema_Economía SHALL crear una Transacción de tipo "PLAYER_TRANSFER_RECEIVED" para el Receptor con la cantidad transferida.

---

### Requisito 2: Validación del Emisor

**Historia de Usuario:** Como sistema, quiero validar que el emisor tenga una cuenta vinculada y balance suficiente, para garantizar la integridad de la economía.

#### Criterios de Aceptación

1. WHEN un usuario sin cuenta vinculada ejecuta `/transferir`, THE Bot_Discord SHALL rechazar el comando con un mensaje indicando que debe vincular su cuenta primero usando `/vincular`.
2. WHEN el Emisor tiene un balance menor a la cantidad solicitada, THE Bot_Discord SHALL rechazar la transferencia e informar el balance actual del Emisor.
3. WHEN la cantidad especificada es menor o igual a cero, THE Bot_Discord SHALL rechazar la transferencia con un mensaje indicando que la cantidad debe ser un número positivo.

---

### Requisito 3: Validación del Receptor

**Historia de Usuario:** Como sistema, quiero validar que el receptor tenga una cuenta vinculada y sea diferente al emisor, para evitar transferencias inválidas.

#### Criterios de Aceptación

1. WHEN el usuario objetivo de la transferencia no tiene cuenta vinculada, THE Bot_Discord SHALL rechazar la transferencia con un mensaje indicando que el receptor no tiene cuenta vinculada.
2. WHEN el Emisor intenta transferir TNT Coins a sí mismo, THE Bot_Discord SHALL rechazar la transferencia con un mensaje indicando que no es posible transferirse monedas a uno mismo.

---

### Requisito 4: Atomicidad de la Transferencia

**Historia de Usuario:** Como administrador, quiero que las transferencias sean atómicas, para que no existan estados inconsistentes donde se debite al emisor sin acreditar al receptor.

#### Criterios de Aceptación

1. THE Sistema_Economía SHALL ejecutar el débito del Emisor y el crédito del Receptor dentro de una única transacción de base de datos.
2. IF ocurre un error durante la transferencia, THEN THE Sistema_Economía SHALL revertir todos los cambios (balance del Emisor, balance del Receptor, y registros de transacciones) sin modificar ningún dato.
3. THE Sistema_Economía SHALL garantizar que la suma total de TNT_Coins en el sistema permanezca constante después de cada transferencia (las monedas debitadas del Emisor son exactamente iguales a las monedas acreditadas al Receptor).

---

### Requisito 5: Registro de Transacciones de Transferencia

**Historia de Usuario:** Como jugador, quiero que mis transferencias aparezcan en mi historial de transacciones, para tener un registro de las monedas que he enviado y recibido.

#### Criterios de Aceptación

1. THE Sistema_Economía SHALL registrar la Transacción del Emisor con tipo "PLAYER_TRANSFER_SENT", la cantidad transferida, y una descripción que incluya el nombre del Receptor.
2. THE Sistema_Economía SHALL registrar la Transacción del Receptor con tipo "PLAYER_TRANSFER_RECEIVED", la cantidad transferida, y una descripción que incluya el nombre del Emisor.
3. WHEN un jugador ejecuta `/transacciones`, THE Bot_Discord SHALL mostrar las transferencias enviadas y recibidas junto con los demás tipos de transacciones existentes.

---

### Requisito 6: Manejo de Errores en Transferencias

**Historia de Usuario:** Como jugador, quiero recibir mensajes claros cuando una transferencia falla, para entender qué salió mal y cómo corregirlo.

#### Criterios de Aceptación

1. IF ocurre un error interno durante la transferencia, THEN THE Bot_Discord SHALL responder al usuario con un mensaje genérico de error sin exponer detalles técnicos.
2. IF el usuario objetivo es un bot de Discord, THEN THE Bot_Discord SHALL rechazar la transferencia con un mensaje indicando que no se puede transferir monedas a un bot.

