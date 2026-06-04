# Documento de Requisitos — Sistema de Economía y Estadísticas de Jugadores

## Introducción

Este documento define los requisitos para un sistema integral de estadísticas y economía de jugadores para el bot de Discord de DayZ. El sistema incluye: vinculación de cuentas Discord ↔ jugador DayZ, seguimiento de estadísticas (kills, muertes, kills de zombies), una moneda virtual ("TNT Coins") que se gana matando zombies con armas cuerpo a cuerpo, comandos de administración de economía, tablas de clasificación, y configuración desde la app Flutter. Este es el primer feature que introduce persistencia con base de datos al proyecto.

## Glosario

- **Sistema_Economía**: Módulo del backend Spring Boot responsable de gestionar la moneda virtual, transacciones y balances de jugadores.
- **Sistema_Estadísticas**: Módulo del backend Spring Boot responsable de rastrear y almacenar kills de jugadores, muertes, kills de zombies y ratios.
- **Bot_Discord**: Aplicación Spring Boot con JDA 5.x que procesa comandos slash de Discord y publica información en canales.
- **App_Flutter**: Aplicación Flutter (nitrado_server_manager) que permite a administradores configurar el sistema a través de la API REST del backend.
- **Parser_Logs**: Componente que analiza los archivos server_log.ADM de DayZ para extraer eventos de kills de zombies.
- **TNT_Coins**: Moneda virtual del sistema de economía que los jugadores ganan al matar zombies con armas cuerpo a cuerpo.
- **Arma_Cuerpo_a_Cuerpo**: Armas de DayZ clasificadas como melee (hachas, cuchillos, bates, palas, etc.) que califican para recompensas de monedas.
- **Jugador_Vinculado**: Un usuario de Discord que ha asociado su cuenta con su nombre de jugador DayZ en el servidor.
- **Transacción**: Registro inmutable de un cambio en el balance de TNT_Coins de un jugador, incluyendo tipo, cantidad, timestamp y razón.
- **Configuración_Economía**: Conjunto de parámetros configurables que definen las recompensas, límites y comportamiento del sistema de economía.
- **Log_ADM**: Archivo de log del servidor DayZ (server_log.ADM) que contiene eventos de juego incluyendo kills de zombies.
- **Scheduler_Zombie_Kills**: Tarea programada que periódicamente descarga y analiza logs del servidor para detectar nuevos kills de zombies.

## Requisitos

### Requisito 1: Persistencia con Base de Datos

**Historia de Usuario:** Como desarrollador, quiero introducir una capa de persistencia con base de datos, para que el sistema pueda almacenar datos de jugadores, transacciones y configuraciones de forma duradera.

#### Criterios de Aceptación

1. THE Sistema_Economía SHALL utilizar Spring Data JPA con H2 como base de datos embebida para el perfil de desarrollo.
2. THE Sistema_Economía SHALL soportar MySQL como base de datos para el perfil de producción mediante configuración de propiedades.
3. THE Sistema_Economía SHALL crear automáticamente el esquema de base de datos al iniciar la aplicación utilizando la estrategia de generación DDL de Hibernate.
4. WHEN la aplicación se reinicia, THE Sistema_Economía SHALL preservar todos los datos almacenados previamente en la base de datos de producción.

---

### Requisito 2: Vinculación de Cuentas Discord ↔ DayZ

**Historia de Usuario:** Como jugador, quiero vincular mi cuenta de Discord con mi nombre de jugador DayZ, para que el sistema pueda rastrear mis estadísticas y otorgarme monedas automáticamente.

#### Criterios de Aceptación

1. WHEN un usuario ejecuta el comando `/vincular <nombre_dayz>`, THE Bot_Discord SHALL crear una asociación entre el ID de Discord del usuario y el nombre de jugador DayZ proporcionado.
2. WHEN un usuario intenta vincular un nombre de jugador DayZ que ya está vinculado a otra cuenta de Discord, THE Bot_Discord SHALL rechazar la vinculación y mostrar un mensaje indicando que el nombre ya está en uso.
3. WHEN un usuario ejecuta el comando `/desvincular`, THE Bot_Discord SHALL eliminar la asociación entre su cuenta de Discord y su nombre de jugador DayZ.
4. WHEN un usuario ejecuta `/vincular` y ya tiene una cuenta vinculada, THE Bot_Discord SHALL reemplazar la vinculación anterior con la nueva.
5. THE Bot_Discord SHALL almacenar la vinculación con el ID de Discord, el nombre de jugador DayZ, y la fecha de vinculación.

---

### Requisito 3: Comando de Estadísticas del Jugador

**Historia de Usuario:** Como jugador, quiero ver mis estadísticas de juego mediante un comando de Discord, para conocer mi rendimiento en el servidor.

#### Criterios de Aceptación

1. WHEN un usuario ejecuta el comando `/estatus`, THE Bot_Discord SHALL mostrar un embed con las estadísticas del jugador vinculado: nombre DayZ, kills de jugadores, muertes, ratio K/D, kills de zombies, y balance de TNT_Coins.
2. WHEN un usuario ejecuta `/estatus` sin tener una cuenta vinculada, THE Bot_Discord SHALL responder con un mensaje indicando que debe vincular su cuenta primero usando `/vincular`.
3. WHEN un usuario ejecuta `/estatus @otro_usuario`, THE Bot_Discord SHALL mostrar las estadísticas del usuario mencionado si tiene cuenta vinculada.
4. THE Bot_Discord SHALL calcular el ratio K/D dividiendo kills de jugadores entre muertes, mostrando "N/A" cuando las muertes son cero.

---

### Requisito 4: Parsing de Kills de Zombies desde Logs

**Historia de Usuario:** Como administrador del servidor, quiero que el sistema detecte automáticamente kills de zombies en los logs del servidor, para que los jugadores reciban monedas por sus logros.

#### Criterios de Aceptación

1. THE Parser_Logs SHALL identificar líneas de kill de zombies en el Log_ADM utilizando patrones regex que detecten entidades zombie (nombres que contengan "ZmbM", "ZmbF", o "Zmb").
2. WHEN una línea de log contiene un kill de zombie, THE Parser_Logs SHALL extraer: timestamp, nombre del jugador, tipo de zombie, y arma utilizada.
3. THE Parser_Logs SHALL formatear eventos de kill de zombie de vuelta a texto de log ADM para validar la propiedad de round-trip (parsear → formatear → parsear produce un evento equivalente).
4. IF una línea de log tiene un formato inesperado o campos numéricos malformados, THEN THE Parser_Logs SHALL omitir la línea y registrar una advertencia sin interrumpir el procesamiento de las demás líneas.
5. THE Parser_Logs SHALL distinguir entre kills de jugadores (Player vs Player) y kills de zombies (Player vs Zombie) sin confundir ambos tipos.

---

### Requisito 5: Recompensas de Monedas por Kills de Zombies

**Historia de Usuario:** Como jugador, quiero ganar TNT_Coins automáticamente al matar zombies con armas cuerpo a cuerpo, para tener un incentivo de juego.

#### Criterios de Aceptación

1. WHEN el Scheduler_Zombie_Kills detecta un kill de zombie realizado con un Arma_Cuerpo_a_Cuerpo, THE Sistema_Economía SHALL acreditar la cantidad configurada de TNT_Coins al Jugador_Vinculado correspondiente.
2. WHEN el kill de zombie fue realizado con un arma que no es cuerpo a cuerpo, THE Sistema_Economía SHALL registrar el kill en las estadísticas del jugador sin otorgar TNT_Coins.
3. WHEN el jugador que realizó el kill no tiene cuenta vinculada, THE Sistema_Economía SHALL registrar el evento de kill pero no otorgar monedas.
4. THE Sistema_Economía SHALL mantener una lista configurable de armas clasificadas como Arma_Cuerpo_a_Cuerpo (por defecto: SledgeHammer, FirefighterAxe, Hatchet, CombatKnife, HuntingKnife, Machete, BaseballBat, CricketBat, Crowbar, Pipe, Shovel, Pickaxe, Sword).
5. THE Sistema_Economía SHALL crear una Transacción de tipo "ZOMBIE_KILL_REWARD" por cada recompensa otorgada, registrando el tipo de zombie y el arma utilizada.

---

### Requisito 6: Scheduler de Detección de Kills de Zombies

**Historia de Usuario:** Como administrador, quiero que el sistema revise periódicamente los logs del servidor para detectar nuevos kills de zombies, para que las recompensas se otorguen de forma automática.

#### Criterios de Aceptación

1. THE Scheduler_Zombie_Kills SHALL ejecutarse cada 5 minutos para descargar y analizar los logs del servidor DayZ.
2. THE Scheduler_Zombie_Kills SHALL mantener un estado de último evento procesado para evitar procesar kills duplicados entre ciclos de polling.
3. WHEN el servidor de Nitrado no está disponible o retorna un error, THE Scheduler_Zombie_Kills SHALL registrar el error y reintentar en el siguiente ciclo sin interrumpir la operación del bot.
4. WHEN el contenido del log está vacío o es nulo, THE Scheduler_Zombie_Kills SHALL omitir el ciclo sin generar errores.
5. THE Scheduler_Zombie_Kills SHALL procesar los eventos en orden cronológico para garantizar la consistencia del estado.

---

### Requisito 7: Comandos de Administración de Economía

**Historia de Usuario:** Como administrador del servidor, quiero poder dar o quitar monedas a los jugadores, para gestionar la economía del servidor manualmente cuando sea necesario.

#### Criterios de Aceptación

1. WHEN un administrador ejecuta `/economia dar @usuario <cantidad>`, THE Bot_Discord SHALL acreditar la cantidad especificada de TNT_Coins al usuario mencionado y crear una Transacción de tipo "ADMIN_CREDIT".
2. WHEN un administrador ejecuta `/economia quitar @usuario <cantidad>`, THE Bot_Discord SHALL debitar la cantidad especificada de TNT_Coins del usuario mencionado y crear una Transacción de tipo "ADMIN_DEBIT".
3. WHEN un usuario sin permisos de administrador ejecuta un comando de `/economia dar` o `/economia quitar`, THE Bot_Discord SHALL rechazar el comando con un mensaje de permisos insuficientes.
4. WHEN la cantidad a debitar excede el balance actual del jugador, THE Bot_Discord SHALL rechazar la operación e informar el balance actual del jugador.
5. WHEN la cantidad especificada es menor o igual a cero, THE Bot_Discord SHALL rechazar la operación con un mensaje indicando que la cantidad debe ser positiva.
6. WHEN el usuario objetivo no tiene cuenta vinculada, THE Bot_Discord SHALL rechazar la operación indicando que el usuario no tiene cuenta vinculada.

---

### Requisito 8: Consulta de Balance

**Historia de Usuario:** Como jugador, quiero consultar mi balance de TNT_Coins rápidamente, para saber cuántas monedas tengo disponibles.

#### Criterios de Aceptación

1. WHEN un usuario ejecuta `/balance`, THE Bot_Discord SHALL mostrar el balance actual de TNT_Coins del jugador vinculado.
2. WHEN un usuario ejecuta `/balance` sin tener cuenta vinculada, THE Bot_Discord SHALL responder indicando que debe vincular su cuenta primero.
3. THE Bot_Discord SHALL mostrar el balance formateado con separador de miles para facilitar la lectura.

---

### Requisito 9: Historial de Transacciones

**Historia de Usuario:** Como jugador, quiero ver el historial de mis transacciones de monedas, para entender cómo he ganado y gastado mis TNT_Coins.

#### Criterios de Aceptación

1. WHEN un usuario ejecuta `/transacciones`, THE Bot_Discord SHALL mostrar las últimas 10 transacciones del jugador ordenadas de más reciente a más antigua.
2. THE Bot_Discord SHALL mostrar para cada transacción: tipo (recompensa zombie, crédito admin, débito admin), cantidad, fecha/hora, y descripción.
3. WHEN un usuario no tiene transacciones registradas, THE Bot_Discord SHALL mostrar un mensaje indicando que no hay transacciones.
4. WHEN un usuario ejecuta `/transacciones` sin cuenta vinculada, THE Bot_Discord SHALL responder indicando que debe vincular su cuenta primero.

---

### Requisito 10: Tablas de Clasificación (Leaderboards)

**Historia de Usuario:** Como jugador, quiero ver las tablas de clasificación del servidor, para comparar mi rendimiento con otros jugadores.

#### Criterios de Aceptación

1. WHEN un usuario ejecuta `/top kills`, THE Bot_Discord SHALL mostrar los 10 jugadores con más kills de jugadores, incluyendo nombre y cantidad de kills.
2. WHEN un usuario ejecuta `/top zombies`, THE Bot_Discord SHALL mostrar los 10 jugadores con más kills de zombies, incluyendo nombre y cantidad.
3. WHEN un usuario ejecuta `/top ricos`, THE Bot_Discord SHALL mostrar los 10 jugadores con mayor balance de TNT_Coins, incluyendo nombre y balance.
4. WHEN un usuario ejecuta `/top kd`, THE Bot_Discord SHALL mostrar los 10 jugadores con mejor ratio K/D (mínimo 5 muertes para calificar), incluyendo nombre y ratio.
5. THE Bot_Discord SHALL mostrar la posición del usuario que ejecuta el comando en la tabla si no aparece en el top 10.

---

### Requisito 11: Configuración de Economía desde la App Flutter

**Historia de Usuario:** Como administrador, quiero configurar los parámetros de la economía desde la app Flutter, para ajustar recompensas y comportamiento sin modificar código.

#### Criterios de Aceptación

1. THE App_Flutter SHALL mostrar una pantalla de configuración de economía con los parámetros editables: monedas por kill de zombie con melee, lista de armas cuerpo a cuerpo, y estado habilitado/deshabilitado del sistema.
2. WHEN un administrador modifica un parámetro de configuración en la App_Flutter, THE App_Flutter SHALL enviar la actualización al backend mediante la API REST.
3. THE Sistema_Economía SHALL exponer endpoints REST para leer y actualizar la Configuración_Economía (GET /api/economy/config y PUT /api/economy/config).
4. WHEN se actualiza la configuración de economía, THE Sistema_Economía SHALL aplicar los nuevos valores inmediatamente sin requerir reinicio del servidor.
5. THE Sistema_Economía SHALL validar que la cantidad de monedas por kill sea un número entero positivo antes de aceptar la actualización.

---

### Requisito 12: Endpoints REST para Estadísticas

**Historia de Usuario:** Como administrador, quiero ver estadísticas de jugadores desde la app Flutter, para monitorear la actividad del servidor.

#### Criterios de Aceptación

1. THE Sistema_Estadísticas SHALL exponer un endpoint GET /api/players/stats que retorne la lista de jugadores vinculados con sus estadísticas.
2. THE Sistema_Estadísticas SHALL exponer un endpoint GET /api/players/{discordId}/stats que retorne las estadísticas detalladas de un jugador específico.
3. THE Sistema_Estadísticas SHALL exponer un endpoint GET /api/economy/transactions que retorne las transacciones recientes con soporte de paginación (parámetros page y size).
4. THE App_Flutter SHALL mostrar una pantalla de estadísticas de jugadores con la información obtenida de los endpoints REST.

---

### Requisito 13: Seguimiento de Estadísticas de Jugadores

**Historia de Usuario:** Como sistema, quiero mantener estadísticas actualizadas de cada jugador, para alimentar los comandos de estatus y las tablas de clasificación.

#### Criterios de Aceptación

1. WHEN el Parser_Logs detecta un kill de jugador (Player vs Player), THE Sistema_Estadísticas SHALL incrementar el contador de kills del jugador atacante y el contador de muertes del jugador víctima.
2. WHEN el Parser_Logs detecta un kill de zombie, THE Sistema_Estadísticas SHALL incrementar el contador de kills de zombies del jugador.
3. THE Sistema_Estadísticas SHALL almacenar por cada Jugador_Vinculado: kills de jugadores, muertes, kills de zombies, kills de zombies con melee, y fecha de última actividad.
4. THE Sistema_Estadísticas SHALL actualizar las estadísticas de forma atómica para evitar inconsistencias en caso de errores durante el procesamiento.

---

### Requisito 14: Manejo de Errores y Resiliencia

**Historia de Usuario:** Como administrador, quiero que el sistema maneje errores de forma robusta, para que fallos individuales no afecten la operación general del bot.

#### Criterios de Aceptación

1. IF la base de datos no está disponible al procesar un kill de zombie, THEN THE Sistema_Economía SHALL registrar el error y reintentar en el siguiente ciclo de polling.
2. IF un comando de Discord falla por un error interno, THEN THE Bot_Discord SHALL responder al usuario con un mensaje genérico de error sin exponer detalles técnicos.
3. IF el Scheduler_Zombie_Kills falla durante un ciclo, THEN THE Scheduler_Zombie_Kills SHALL continuar operando en el siguiente ciclo programado sin intervención manual.
4. THE Sistema_Economía SHALL utilizar transacciones de base de datos para garantizar que las operaciones de crédito/débito sean atómicas (el balance y la transacción se actualizan juntos o ninguno se actualiza).
