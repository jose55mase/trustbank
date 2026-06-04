# Documento de Requisitos — Integración Nitrado Server

## Introducción

Migración de la integración con la API de Nitrado (`https://api.nitrado.net`) desde la aplicación Flutter/Dart (`nitrado_server_manager`) al backend Java Spring Boot (`discord-bot-backend`). El backend expondrá endpoints REST que la app Flutter consumirá, eliminando la comunicación directa entre el cliente Dart y la API de Nitrado. Esto centraliza la autenticación, simplifica el cliente móvil y permite reutilizar la lógica de servidor desde otros clientes (por ejemplo, comandos de Discord).

## Glosario

- **API_Gateway**: Capa de controladores REST del backend Spring Boot que expone los endpoints para la app Flutter.
- **Nitrado_Client**: Componente del backend responsable de comunicarse con la API de Nitrado mediante HTTP.
- **Nitrado_API**: API REST externa de Nitrado ubicada en `https://api.nitrado.net`.
- **Nitrado_Token**: Token OAuth Bearer utilizado para autenticarse con la Nitrado_API.
- **GameServer**: Modelo que representa un servidor DayZ con campos: id, name, ip, port, status, currentPlayers, maxPlayers, map, gameVersion.
- **Player**: Modelo que representa un jugador conectado al servidor con campos: id, name, online.
- **BannedPlayer**: Modelo que representa un jugador baneado con campos: id, name, reason, bannedAt.
- **FileEntry**: Modelo que representa un archivo o directorio en el servidor con campos: name, path, type, size.
- **ServerAction**: Enumeración de acciones de control del servidor: start, stop, restart.
- **Service_ID**: Identificador numérico único de un servicio/servidor en la Nitrado_API.
- **Flutter_App**: Aplicación cliente Flutter/Dart (`nitrado_server_manager`) que consume los endpoints del API_Gateway.

## Requisitos

### Requisito 1: Configuración del Token de Nitrado

**Historia de Usuario:** Como administrador del sistema, quiero que el backend gestione el token de autenticación de Nitrado de forma centralizada, para que la app Flutter no necesite almacenar ni enviar credenciales de Nitrado directamente.

#### Criterios de Aceptación

1. THE API_Gateway SHALL cargar el Nitrado_Token desde `application.properties` o desde variables de entorno.
2. WHEN el Nitrado_Client realiza una solicitud a la Nitrado_API, THE Nitrado_Client SHALL incluir el Nitrado_Token como cabecera `Authorization: Bearer {token}` en cada petición.
3. IF el Nitrado_Token no está configurado o está vacío, THEN THE API_Gateway SHALL registrar un error descriptivo al iniciar e impedir el uso de los endpoints de Nitrado.
4. IF la Nitrado_API responde con código 401 o 403, THEN THE Nitrado_Client SHALL propagar un error de autenticación con un mensaje descriptivo al API_Gateway.

### Requisito 2: Listado de Servidores DayZ

**Historia de Usuario:** Como usuario de la app, quiero obtener la lista de mis servidores DayZ a través del backend, para poder ver todos mis servidores sin que la app se conecte directamente a Nitrado.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud GET al endpoint `/api/servers`, THE API_Gateway SHALL devolver una lista de objetos GameServer en formato JSON.
2. WHEN el Nitrado_Client consulta la Nitrado_API en `/services`, THE Nitrado_Client SHALL filtrar los resultados para incluir únicamente servicios cuyo campo `game` contenga "dayz" (sin distinción de mayúsculas/minúsculas).
3. THE API_Gateway SHALL mapear cada servicio de la Nitrado_API a un objeto GameServer con los campos: id, name, ip, port, status, currentPlayers, maxPlayers, map, gameVersion.
4. IF la Nitrado_API no devuelve servicios DayZ, THEN THE API_Gateway SHALL devolver una lista vacía con código HTTP 200.
5. IF la Nitrado_API responde con un error, THEN THE API_Gateway SHALL devolver un código HTTP apropiado (502 para errores del servidor de Nitrado, 401 para errores de autenticación) con un mensaje descriptivo.

### Requisito 3: Estado Detallado del Servidor

**Historia de Usuario:** Como usuario de la app, quiero consultar el estado detallado de un servidor específico, para poder ver información actualizada como jugadores conectados, mapa y versión.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud GET al endpoint `/api/servers/{serviceId}/status`, THE API_Gateway SHALL devolver un objeto GameServer con la información detallada del servidor.
2. WHEN el Nitrado_Client consulta la Nitrado_API en `/services/{serviceId}/gameservers`, THE Nitrado_Client SHALL parsear la respuesta y construir un objeto GameServer con todos los campos.
3. IF el Service_ID proporcionado no corresponde a un servidor existente, THEN THE API_Gateway SHALL devolver un código HTTP 404 con un mensaje indicando que el servidor no fue encontrado.

### Requisito 4: Control del Servidor (Start, Stop, Restart)

**Historia de Usuario:** Como usuario de la app, quiero iniciar, detener y reiniciar mis servidores DayZ desde la app a través del backend, para poder gestionar el ciclo de vida del servidor de forma remota.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud POST al endpoint `/api/servers/{serviceId}/actions/{action}` con una ServerAction válida (start, stop, restart), THE API_Gateway SHALL enviar la acción correspondiente a la Nitrado_API y devolver un código HTTP 200 con un mensaje de confirmación.
2. WHEN la ServerAction es "start" o "restart", THE Nitrado_Client SHALL enviar una solicitud POST a `/services/{serviceId}/gameservers/restart` en la Nitrado_API.
3. WHEN la ServerAction es "stop", THE Nitrado_Client SHALL enviar una solicitud POST a `/services/{serviceId}/gameservers/stop` en la Nitrado_API.
4. IF la ServerAction proporcionada no es válida, THEN THE API_Gateway SHALL devolver un código HTTP 400 con un mensaje indicando las acciones permitidas.
5. IF la Nitrado_API rechaza la acción, THEN THE API_Gateway SHALL devolver el código HTTP y mensaje de error correspondiente de la Nitrado_API.

### Requisito 5: Listado de Jugadores Conectados

**Historia de Usuario:** Como usuario de la app, quiero ver la lista de jugadores conectados a un servidor, para poder monitorear quién está jugando en tiempo real.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud GET al endpoint `/api/servers/{serviceId}/players`, THE API_Gateway SHALL devolver una lista de objetos Player en formato JSON.
2. WHEN el Nitrado_Client consulta la Nitrado_API en `/services/{serviceId}/gameservers/games/players`, THE Nitrado_Client SHALL parsear la respuesta y construir objetos Player con los campos: id, name, online.
3. IF no hay jugadores conectados, THEN THE API_Gateway SHALL devolver una lista vacía con código HTTP 200.

### Requisito 6: Expulsión de Jugadores

**Historia de Usuario:** Como usuario de la app, quiero expulsar a un jugador de mi servidor, para poder mantener el orden en la partida.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud POST al endpoint `/api/servers/{serviceId}/players/{playerId}/kick`, THE API_Gateway SHALL enviar la solicitud de expulsión a la Nitrado_API y devolver un código HTTP 200 con un mensaje de confirmación.
2. WHEN el Nitrado_Client envía la solicitud de expulsión, THE Nitrado_Client SHALL enviar un POST a `/services/{serviceId}/gameservers/games/players/kick` con el campo `player_id` en el cuerpo de la solicitud.
3. IF la Nitrado_API rechaza la expulsión, THEN THE API_Gateway SHALL devolver el código HTTP y mensaje de error correspondiente.

### Requisito 7: Baneo de Jugadores

**Historia de Usuario:** Como usuario de la app, quiero banear a un jugador de mi servidor con una razón opcional, para poder restringir el acceso a jugadores problemáticos.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud POST al endpoint `/api/servers/{serviceId}/players/{playerId}/ban` con un campo opcional `reason`, THE API_Gateway SHALL enviar la solicitud de baneo a la Nitrado_API y devolver un código HTTP 200 con un mensaje de confirmación.
2. WHEN el Nitrado_Client envía la solicitud de baneo, THE Nitrado_Client SHALL enviar un POST a `/services/{serviceId}/gameservers/games/players/ban` con el campo `player_id` y opcionalmente `reason` en el cuerpo.
3. IF la Nitrado_API rechaza el baneo, THEN THE API_Gateway SHALL devolver el código HTTP y mensaje de error correspondiente.

### Requisito 8: Listado de Jugadores Baneados

**Historia de Usuario:** Como usuario de la app, quiero ver la lista de jugadores baneados de mi servidor, para poder revisar y gestionar los baneos existentes.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud GET al endpoint `/api/servers/{serviceId}/banlist`, THE API_Gateway SHALL devolver una lista de objetos BannedPlayer en formato JSON.
2. WHEN el Nitrado_Client consulta la Nitrado_API en `/services/{serviceId}/gameservers/games/banlist`, THE Nitrado_Client SHALL parsear la respuesta y construir objetos BannedPlayer con los campos: id, name, reason, bannedAt.
3. IF no hay jugadores baneados, THEN THE API_Gateway SHALL devolver una lista vacía con código HTTP 200.

### Requisito 9: Desbaneo de Jugadores

**Historia de Usuario:** Como usuario de la app, quiero desbanear a un jugador de mi servidor, para poder restaurar su acceso cuando sea apropiado.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud DELETE al endpoint `/api/servers/{serviceId}/banlist/{playerId}`, THE API_Gateway SHALL enviar la solicitud de desbaneo a la Nitrado_API y devolver un código HTTP 200 con un mensaje de confirmación.
2. WHEN el Nitrado_Client envía la solicitud de desbaneo, THE Nitrado_Client SHALL enviar un DELETE a `/services/{serviceId}/gameservers/games/banlist` con el campo `player_id` en el cuerpo.
3. IF la Nitrado_API rechaza el desbaneo, THEN THE API_Gateway SHALL devolver el código HTTP y mensaje de error correspondiente.

### Requisito 10: Listado de Archivos del Servidor

**Historia de Usuario:** Como usuario de la app, quiero navegar los archivos de mi servidor DayZ, para poder ver la estructura de archivos y directorios del servidor.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud GET al endpoint `/api/servers/{serviceId}/files` con un parámetro de consulta `path`, THE API_Gateway SHALL devolver una lista de objetos FileEntry en formato JSON.
2. WHEN el Nitrado_Client consulta la Nitrado_API en `/services/{serviceId}/gameservers/file_server/list` con el parámetro `dir`, THE Nitrado_Client SHALL parsear la respuesta y construir objetos FileEntry con los campos: name, path, type, size.
3. IF el directorio solicitado no existe, THEN THE API_Gateway SHALL devolver un código HTTP 404 con un mensaje descriptivo.
4. IF no se proporciona el parámetro `path`, THEN THE API_Gateway SHALL usar "/" como directorio raíz por defecto.

### Requisito 11: Descarga de Archivos del Servidor

**Historia de Usuario:** Como usuario de la app, quiero descargar archivos de configuración de mi servidor, para poder revisar y respaldar la configuración.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud GET al endpoint `/api/servers/{serviceId}/files/download` con un parámetro de consulta `path`, THE API_Gateway SHALL devolver el contenido del archivo como texto.
2. WHEN el Nitrado_Client solicita la descarga a la Nitrado_API en `/services/{serviceId}/gameservers/file_server/download`, THE Nitrado_Client SHALL obtener la URL temporal de descarga de la respuesta y descargar el contenido del archivo desde esa URL.
3. IF el archivo solicitado no existe, THEN THE API_Gateway SHALL devolver un código HTTP 404 con un mensaje descriptivo.

### Requisito 12: Subida de Archivos al Servidor

**Historia de Usuario:** Como usuario de la app, quiero subir archivos de configuración a mi servidor, para poder modificar la configuración del servidor de forma remota.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud POST al endpoint `/api/servers/{serviceId}/files/upload` con el parámetro de consulta `path` y el contenido del archivo en el cuerpo, THE API_Gateway SHALL enviar el archivo a la Nitrado_API y devolver un código HTTP 200 con un mensaje de confirmación.
2. WHEN el Nitrado_Client envía la solicitud de subida, THE Nitrado_Client SHALL enviar un POST a `/services/{serviceId}/gameservers/file_server/upload` con el parámetro `path` y el contenido como `application/octet-stream`.
3. IF la Nitrado_API rechaza la subida, THEN THE API_Gateway SHALL devolver el código HTTP y mensaje de error correspondiente.

### Requisito 13: Descarga de Logs del Servidor

**Historia de Usuario:** Como usuario de la app, quiero descargar los logs de mi servidor DayZ, para poder diagnosticar problemas y revisar la actividad del servidor.

#### Criterios de Aceptación

1. WHEN la Flutter_App envía una solicitud GET al endpoint `/api/servers/{serviceId}/logs`, THE API_Gateway SHALL devolver el contenido del archivo de log del servidor como texto.
2. WHEN el Nitrado_Client obtiene los logs, THE Nitrado_Client SHALL listar los archivos en `/games` para localizar la carpeta DayZ, y luego descargar el archivo de log desde la ruta `{carpeta_dayz}/logs/server_log.ADM`.
3. IF la carpeta DayZ no se encuentra en `/games`, THEN THE Nitrado_Client SHALL intentar la ruta alternativa `/games/ni{serviceId}_dayz/logs/server_log.ADM`.
4. IF el archivo de log no existe o no se puede descargar, THEN THE API_Gateway SHALL devolver un código HTTP 404 con un mensaje descriptivo.

### Requisito 14: Manejo de Errores y Propagación

**Historia de Usuario:** Como usuario de la app, quiero recibir mensajes de error claros cuando algo falla, para poder entender qué ocurrió y tomar acción.

#### Criterios de Aceptación

1. IF la Nitrado_API responde con código HTTP 401 o 403, THEN THE API_Gateway SHALL devolver un código HTTP 401 con un mensaje indicando que el token de Nitrado es inválido o ha expirado.
2. IF la Nitrado_API responde con un código HTTP 4xx (distinto de 401/403), THEN THE API_Gateway SHALL devolver un código HTTP 400 con el mensaje de error proporcionado por la Nitrado_API.
3. IF la Nitrado_API responde con un código HTTP 5xx, THEN THE API_Gateway SHALL devolver un código HTTP 502 con un mensaje indicando que el servicio de Nitrado no está disponible temporalmente.
4. IF la conexión con la Nitrado_API falla por timeout o error de red, THEN THE API_Gateway SHALL devolver un código HTTP 504 con un mensaje indicando que no se pudo contactar con el servicio de Nitrado.
5. THE API_Gateway SHALL devolver todos los errores en un formato JSON consistente con los campos: `error` (código de error), `message` (descripción legible).

### Requisito 15: Logging y Observabilidad de la Integración

**Historia de Usuario:** Como administrador del sistema, quiero que todas las interacciones con la API de Nitrado queden registradas, para poder diagnosticar problemas y monitorear el uso.

#### Criterios de Aceptación

1. WHEN el Nitrado_Client envía una solicitud a la Nitrado_API, THE Nitrado_Client SHALL registrar en los logs el método HTTP, la URL del endpoint y el Service_ID con nivel INFO.
2. WHEN la Nitrado_API responde con un error, THE Nitrado_Client SHALL registrar el código de respuesta HTTP, el mensaje de error y el Service_ID con nivel ERROR.
3. WHEN el Nitrado_Client completa una solicitud exitosamente, THE Nitrado_Client SHALL registrar el tiempo de respuesta en milisegundos con nivel DEBUG.
4. THE Nitrado_Client SHALL incluir un prefijo identificable (por ejemplo, `[NitradoClient]`) en todos los mensajes de log para facilitar el filtrado.
