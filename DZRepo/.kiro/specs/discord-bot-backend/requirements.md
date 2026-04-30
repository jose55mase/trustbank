# Documento de Requisitos

## Introducción

Backend en Java que se integra con la API de Discord mediante un bot. El sistema mantiene una conexión persistente con Discord a través de WebSocket (Gateway), permite enviar mensajes a canales, y escucha y responde a eventos y comandos entrantes en tiempo real. Utiliza JDA (Java Discord API) como librería principal de integración.

## Glosario

- **Bot_Backend**: Aplicación Java que se conecta a Discord y gestiona la comunicación bidireccional con la plataforma.
- **Discord_Gateway**: Conexión WebSocket persistente proporcionada por Discord para recibir eventos en tiempo real.
- **Event_Listener**: Componente del Bot_Backend responsable de recibir y despachar eventos entrantes de Discord.
- **Command_Handler**: Componente del Bot_Backend responsable de interpretar y ejecutar comandos recibidos desde Discord.
- **Message_Sender**: Componente del Bot_Backend responsable de enviar mensajes a canales de Discord.
- **Bot_Token**: Token de autenticación secreto utilizado para conectar el Bot_Backend con la API de Discord.
- **Slash_Command**: Comando registrado en Discord con el prefijo `/` que los usuarios pueden invocar desde la interfaz de Discord.
- **JDA**: Java Discord API, librería de código abierto para interactuar con la API de Discord desde Java.
- **Channel_ID**: Identificador único de un canal de Discord.
- **Health_Check**: Endpoint que reporta el estado de salud del Bot_Backend y su conexión con Discord.

## Requisitos

### Requisito 1: Autenticación y Conexión con Discord

**Historia de Usuario:** Como administrador del sistema, quiero que el backend se autentique con Discord usando un bot token, para que pueda establecer una conexión segura y persistente con la plataforma.

#### Criterios de Aceptación

1. WHEN el Bot_Backend se inicia, THE Bot_Backend SHALL autenticarse con el Discord_Gateway utilizando el Bot_Token configurado.
2. WHEN la autenticación es exitosa, THE Bot_Backend SHALL establecer una conexión WebSocket persistente con el Discord_Gateway.
3. IF el Bot_Token es inválido o no está configurado, THEN THE Bot_Backend SHALL registrar un mensaje de error descriptivo y terminar la ejecución de forma controlada.
4. THE Bot_Backend SHALL cargar el Bot_Token desde `application.properties` (puede ser hardcoded para pruebas) o desde variables de entorno. En producción se recomienda usar variables de entorno.

### Requisito 2: Conexión Persistente y Reconexión Automática

**Historia de Usuario:** Como administrador del sistema, quiero que el backend mantenga una conexión estable con Discord en todo momento, para que no se pierdan eventos ni mensajes.

#### Criterios de Aceptación

1. WHILE el Bot_Backend está en ejecución, THE Bot_Backend SHALL mantener una conexión activa con el Discord_Gateway.
2. IF la conexión con el Discord_Gateway se pierde, THEN THE Bot_Backend SHALL intentar reconectarse automáticamente utilizando una estrategia de backoff exponencial.
3. WHEN la reconexión es exitosa, THE Bot_Backend SHALL reanudar la escucha de eventos sin intervención manual.
4. IF la reconexión falla después de 5 intentos consecutivos, THEN THE Bot_Backend SHALL registrar un error crítico con el número de intentos realizados.

### Requisito 3: Escucha de Eventos en Tiempo Real

**Historia de Usuario:** Como administrador del sistema, quiero que el backend escuche todos los eventos que Discord envía, para que pueda reaccionar a mensajes, comandos e interacciones de los usuarios.

#### Criterios de Aceptación

1. WHILE el Bot_Backend está conectado al Discord_Gateway, THE Event_Listener SHALL recibir y procesar eventos de mensajes entrantes.
2. WHILE el Bot_Backend está conectado al Discord_Gateway, THE Event_Listener SHALL recibir y procesar eventos de Slash_Command.
3. WHEN el Event_Listener recibe un evento, THE Event_Listener SHALL despachar el evento al Command_Handler correspondiente dentro de los 2 segundos posteriores a la recepción.
4. IF el Event_Listener recibe un evento con formato no reconocido, THEN THE Event_Listener SHALL registrar el evento como advertencia y continuar la operación normal.

### Requisito 4: Procesamiento de Comandos

**Historia de Usuario:** Como usuario de Discord, quiero enviar comandos al bot y recibir respuestas, para poder interactuar con el backend desde Discord.

#### Criterios de Aceptación

1. WHEN el Command_Handler recibe un Slash_Command válido, THE Command_Handler SHALL ejecutar la lógica asociada al comando y devolver una respuesta al canal de origen.
2. WHEN el Command_Handler recibe un Slash_Command con el nombre `/ping`, THE Command_Handler SHALL responder con el mensaje "pong" y la latencia actual del Bot_Backend en milisegundos.
3. WHEN el Command_Handler recibe un Slash_Command con el nombre `/status`, THE Command_Handler SHALL responder con el estado actual del Bot_Backend incluyendo tiempo de actividad y estado de la conexión.
4. IF el Command_Handler recibe un Slash_Command no registrado, THEN THE Command_Handler SHALL responder con un mensaje indicando que el comando no fue reconocido.
5. IF el Command_Handler encuentra un error durante la ejecución de un comando, THEN THE Command_Handler SHALL responder con un mensaje de error genérico al usuario y registrar el error detallado en los logs.

### Requisito 5: Envío de Mensajes a Canales

**Historia de Usuario:** Como desarrollador, quiero que el backend pueda enviar mensajes a canales específicos de Discord, para poder notificar eventos o enviar información programáticamente.

#### Criterios de Aceptación

1. WHEN el Message_Sender recibe una solicitud de envío con un Channel_ID y contenido de texto válidos, THE Message_Sender SHALL enviar el mensaje al canal de Discord especificado.
2. IF el Channel_ID proporcionado no existe o el Bot_Backend no tiene permisos para escribir en el canal, THEN THE Message_Sender SHALL registrar un error con el Channel_ID y el motivo del fallo.
3. IF el contenido del mensaje excede los 2000 caracteres (límite de Discord), THEN THE Message_Sender SHALL dividir el contenido en múltiples mensajes consecutivos respetando el límite.
4. WHEN el Message_Sender envía un mensaje exitosamente, THE Message_Sender SHALL registrar el envío con el Channel_ID y un identificador del mensaje.

### Requisito 6: Registro de Comandos Slash en Discord

**Historia de Usuario:** Como administrador del sistema, quiero que los comandos slash se registren automáticamente en Discord al iniciar el bot, para que los usuarios puedan descubrirlos y usarlos sin configuración manual.

#### Criterios de Aceptación

1. WHEN el Bot_Backend se conecta exitosamente al Discord_Gateway, THE Bot_Backend SHALL registrar todos los Slash_Command definidos en la configuración del bot con la API de Discord.
2. WHEN un Slash_Command se registra exitosamente, THE Bot_Backend SHALL registrar en los logs el nombre del comando registrado.
3. IF el registro de un Slash_Command falla, THEN THE Bot_Backend SHALL registrar un error con el nombre del comando y el motivo del fallo, y continuar con el registro de los comandos restantes.

### Requisito 7: Logging y Observabilidad

**Historia de Usuario:** Como administrador del sistema, quiero que el backend registre su actividad de forma estructurada, para poder diagnosticar problemas y monitorear el comportamiento del bot.

#### Criterios de Aceptación

1. THE Bot_Backend SHALL registrar todos los eventos significativos (inicio, conexión, desconexión, errores, comandos recibidos) utilizando un framework de logging estructurado con niveles INFO, WARN y ERROR.
2. WHEN el Bot_Backend recibe un comando, THE Bot_Backend SHALL registrar el nombre del comando, el usuario que lo invocó y el canal de origen.
3. THE Bot_Backend SHALL exponer un endpoint de Health_Check que retorne el estado de la conexión con Discord y el tiempo de actividad del sistema.
4. IF el Bot_Backend detecta una tasa de errores superior a 10 errores por minuto, THEN THE Bot_Backend SHALL registrar una alerta con nivel ERROR indicando la tasa de errores actual.

### Requisito 8: Configuración Externalizada

**Historia de Usuario:** Como administrador del sistema, quiero que la configuración del bot sea externalizable, para poder modificar parámetros sin recompilar la aplicación.

#### Criterios de Aceptación

1. THE Bot_Backend SHALL cargar la configuración (Bot_Token, Channel_ID por defecto, prefijo de log) desde un archivo `application.properties` o `application.yml`.
2. THE Bot_Backend SHALL permitir sobreescribir cualquier valor de configuración mediante variables de entorno.
3. IF un valor de configuración obligatorio no está presente, THEN THE Bot_Backend SHALL registrar un error indicando el nombre del parámetro faltante y terminar la ejecución de forma controlada.
