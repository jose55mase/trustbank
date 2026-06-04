# Documento de Requisitos: Game Logs Viewer

## Introducción

Este módulo extiende la aplicación Flutter `nitrado_server_manager` para mostrar TODOS los eventos del juego DayZ parseados y categorizados desde los logs del servidor (`server_log.ADM`). Actualmente la app muestra los logs como texto crudo sin clasificación por tipo de evento. El objetivo es que el backend parsee todos los tipos de eventos (conexiones, desconexiones, kills entre jugadores, kills de zombies, mensajes de chat, etc.) y los exponga como datos estructurados que la app Flutter pueda mostrar con filtros por categoría, búsqueda y visualización diferenciada por tipo de evento.

## Glosario

- **Backend**: Servicio Spring Boot (`discord-bot-backend`) que se comunica con la API de Nitrado para obtener los logs del servidor DayZ.
- **App_Flutter**: Aplicación móvil `nitrado_server_manager` que consume la API del Backend para gestionar el servidor DayZ.
- **ADM_Log**: Archivo `server_log.ADM` generado por el servidor DayZ que contiene todos los eventos del juego en formato texto plano.
- **Evento_de_Juego**: Una entrada individual parseada del ADM_Log que representa una acción ocurrida en el servidor (conexión, desconexión, kill, etc.).
- **Categoría_de_Evento**: Clasificación de un Evento_de_Juego según su tipo: `connection`, `disconnection`, `player_kill`, `zombie_kill`, `chat`, `hit`, `unknown`.
- **Parser_de_Logs**: Componente del Backend responsable de analizar el texto crudo del ADM_Log y extraer Eventos_de_Juego estructurados.
- **Endpoint_de_Eventos**: API REST del Backend que expone los Eventos_de_Juego parseados a la App_Flutter.
- **BackendApiClient**: Cliente HTTP basado en Dio en la App_Flutter que se comunica con el Backend.

## Requisitos

### Requisito 1: Parseo completo de eventos del ADM Log

**User Story:** Como administrador del servidor DayZ, quiero que el backend parsee todos los tipos de eventos del log ADM, para que pueda ver toda la actividad del servidor de forma estructurada.

#### Criterios de Aceptación

1. WHEN el Backend recibe el contenido del ADM_Log, THE Parser_de_Logs SHALL extraer eventos de conexión de jugadores con el formato `HH:mm:ss | Player "NOMBRE" is connected (id=ID)`
2. WHEN el Backend recibe el contenido del ADM_Log, THE Parser_de_Logs SHALL extraer eventos de desconexión de jugadores con el formato `HH:mm:ss | Player "NOMBRE" has been disconnected`
3. WHEN el Backend recibe el contenido del ADM_Log, THE Parser_de_Logs SHALL extraer eventos de kills entre jugadores con el formato `HH:mm:ss | Player "VICTIMA" (...) killed by Player "KILLER" (...) with ARMA from DISTANCIA meters`
4. WHEN el Backend recibe el contenido del ADM_Log, THE Parser_de_Logs SHALL extraer eventos de kills de zombies con el formato `HH:mm:ss | Player "NOMBRE" (...) killed ZmbTipo`
5. WHEN el Backend recibe el contenido del ADM_Log, THE Parser_de_Logs SHALL extraer eventos de chat con el formato `HH:mm:ss | Player "NOMBRE" (id=...) placed Chat: MENSAJE`
6. WHEN una línea del ADM_Log no coincide con ningún patrón conocido, THE Parser_de_Logs SHALL clasificar el evento como categoría `unknown` y preservar el texto original de la línea
7. THE Parser_de_Logs SHALL asignar a cada Evento_de_Juego un timestamp, una Categoría_de_Evento, el nombre del jugador involucrado y los datos específicos del tipo de evento

### Requisito 2: Endpoint REST para eventos de juego

**User Story:** Como desarrollador de la App_Flutter, quiero un endpoint REST que devuelva los eventos parseados del servidor, para poder mostrarlos en la interfaz de usuario.

#### Criterios de Aceptación

1. WHEN la App_Flutter realiza una petición GET al Endpoint_de_Eventos, THE Backend SHALL responder con una lista de Eventos_de_Juego en formato JSON
2. THE Backend SHALL incluir en cada Evento_de_Juego los campos: `timestamp`, `category`, `playerName`, `message` y `details` (objeto con datos específicos del tipo de evento)
3. WHEN la App_Flutter envía el parámetro de consulta `category`, THE Backend SHALL filtrar los eventos y devolver únicamente los que coincidan con la Categoría_de_Evento especificada
4. WHEN la App_Flutter envía el parámetro de consulta `search`, THE Backend SHALL filtrar los eventos cuyo contenido textual contenga el término de búsqueda (sin distinción de mayúsculas/minúsculas)
5. THE Backend SHALL devolver los eventos ordenados cronológicamente del más reciente al más antiguo
6. IF el ADM_Log no está disponible o la API de Nitrado falla, THEN THE Backend SHALL responder con un código HTTP 502 y un mensaje descriptivo del error

### Requisito 3: Modelo de datos de eventos en Flutter

**User Story:** Como desarrollador de la App_Flutter, quiero un modelo de datos que represente los eventos de juego, para poder manipularlos y mostrarlos en la UI.

#### Criterios de Aceptación

1. THE App_Flutter SHALL definir un modelo `GameLogEvent` con los campos: `timestamp` (String), `category` (enum), `playerName` (String), `message` (String) y `details` (Map)
2. WHEN la App_Flutter recibe la respuesta JSON del Endpoint_de_Eventos, THE BackendApiClient SHALL deserializar cada objeto JSON en una instancia de `GameLogEvent`
3. WHEN la App_Flutter serializa un `GameLogEvent` a JSON y lo deserializa de vuelta, THE App_Flutter SHALL producir un objeto equivalente al original (propiedad round-trip)
4. IF el JSON recibido contiene una categoría no reconocida, THEN THE App_Flutter SHALL asignar la categoría `unknown` sin lanzar excepciones

### Requisito 4: Pantalla de visualización de eventos de juego

**User Story:** Como administrador del servidor DayZ, quiero ver todos los eventos del juego en una pantalla dedicada con filtros por categoría, para poder monitorear la actividad del servidor de forma eficiente.

#### Criterios de Aceptación

1. THE App_Flutter SHALL mostrar una pantalla de "Game Logs" que liste todos los Eventos_de_Juego obtenidos del Backend
2. THE App_Flutter SHALL diferenciar visualmente cada Evento_de_Juego según su Categoría_de_Evento usando iconos y colores distintos
3. WHEN el usuario selecciona un filtro de categoría, THE App_Flutter SHALL mostrar únicamente los eventos que pertenezcan a la categoría seleccionada
4. WHEN el usuario ingresa texto en el campo de búsqueda, THE App_Flutter SHALL filtrar los eventos mostrando solo aquellos cuyo contenido coincida con el texto ingresado (sin distinción de mayúsculas/minúsculas)
5. WHEN el usuario presiona el botón de actualizar, THE App_Flutter SHALL solicitar los eventos más recientes al Backend y actualizar la lista
6. WHILE la App_Flutter está cargando los eventos, THE App_Flutter SHALL mostrar un indicador de progreso
7. IF la carga de eventos falla, THEN THE App_Flutter SHALL mostrar un mensaje de error con la opción de reintentar

### Requisito 5: Filtrado por categoría de evento

**User Story:** Como administrador del servidor DayZ, quiero filtrar los eventos por tipo (kills, conexiones, desconexiones, etc.), para poder enfocarme en la actividad que me interesa.

#### Criterios de Aceptación

1. THE App_Flutter SHALL mostrar chips o botones de filtro para cada Categoría_de_Evento disponible: conexiones, desconexiones, kills de jugadores, kills de zombies, chat y otros
2. WHEN el usuario selecciona la categoría "Todos", THE App_Flutter SHALL mostrar todos los eventos sin filtrar
3. WHEN el usuario selecciona una categoría específica, THE App_Flutter SHALL mostrar únicamente los eventos de esa categoría
4. THE App_Flutter SHALL indicar visualmente cuál categoría está actualmente seleccionada
5. WHEN se aplica un filtro de categoría junto con una búsqueda de texto, THE App_Flutter SHALL mostrar solo los eventos que cumplan ambos criterios simultáneamente

### Requisito 6: Parseo y formateo de eventos (Round-Trip)

**User Story:** Como desarrollador, quiero garantizar que el parseo de logs sea correcto y reversible, para poder confiar en la integridad de los datos mostrados.

#### Criterios de Aceptación

1. THE Parser_de_Logs SHALL proporcionar un método de formateo que convierta un Evento_de_Juego de vuelta a su representación textual en formato ADM
2. FOR ALL Eventos_de_Juego válidos, parsear una línea ADM y luego formatearla y re-parsearla SHALL producir un evento equivalente al original (propiedad round-trip)
3. FOR ALL contenidos de ADM_Log con mezcla de líneas válidas e inválidas, THE Parser_de_Logs SHALL extraer exactamente las líneas válidas sin lanzar excepciones por las líneas inválidas (propiedad de resiliencia)
4. FOR ALL contenidos de ADM_Log, el número de eventos parseados SHALL ser menor o igual al número total de líneas del log (propiedad metamórfica)
