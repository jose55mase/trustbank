# Documento de Requisitos

## Introducción

Esta funcionalidad agrega comandos slash de Discord para controlar servidores de juego DayZ alojados en Nitrado. Los comandos permiten a los administradores del servidor de Discord reiniciar y detener servidores directamente desde un canal de Discord, utilizando la integración existente con la API de Nitrado (`NitradoApiClient`). El acceso a estos comandos está restringido exclusivamente a usuarios con el rol de administrador en Discord.

## Glosario

- **Bot**: La aplicación de Discord basada en Spring Boot y JDA 5.x que recibe y procesa comandos slash.
- **Comando_Restart**: El comando slash `/restart` que reinicia un servidor DayZ a través de la API de Nitrado.
- **Comando_Stop**: El comando slash `/stop` que detiene un servidor DayZ a través de la API de Nitrado.
- **NitradoApiClient**: El servicio existente que encapsula la comunicación con la API de Nitrado, incluyendo el método `serverAction(int serviceId, ServerAction action)`.
- **Rol_Administrador**: El rol de Discord que otorga permisos de administración. Solo los usuarios con este rol pueden ejecutar los comandos de control del servidor.
- **Servidor_DayZ**: Un servidor de juego DayZ alojado en Nitrado, identificado por su `serviceId`.
- **CommandHandler**: El componente existente que mantiene un registro de comandos slash y despacha eventos a los manejadores correspondientes.
- **Respuesta_Efímera**: Un mensaje de respuesta en Discord que solo es visible para el usuario que ejecutó el comando.

## Requisitos

### Requisito 1: Comando de reinicio del servidor

**Historia de Usuario:** Como administrador del servidor de Discord, quiero reiniciar el servidor DayZ desde Discord con un comando slash, para no tener que acceder al panel de Nitrado manualmente.

#### Criterios de Aceptación

1. WHEN un usuario ejecuta el Comando_Restart, THE Bot SHALL verificar que el usuario posee el Rol_Administrador antes de procesar la solicitud.
2. WHEN un usuario con Rol_Administrador ejecuta el Comando_Restart, THE Bot SHALL invocar el método `serverAction` del NitradoApiClient con la acción RESTART para el Servidor_DayZ correspondiente.
3. WHEN el NitradoApiClient completa la acción RESTART exitosamente, THE Bot SHALL responder al usuario con un mensaje de confirmación indicando que el servidor se está reiniciando.
4. WHEN un usuario sin Rol_Administrador ejecuta el Comando_Restart, THE Bot SHALL responder con una Respuesta_Efímera indicando que no tiene permisos para ejecutar el comando.

### Requisito 2: Comando de detención del servidor

**Historia de Usuario:** Como administrador del servidor de Discord, quiero detener el servidor DayZ desde Discord con un comando slash, para poder apagarlo rápidamente cuando sea necesario.

#### Criterios de Aceptación

1. WHEN un usuario ejecuta el Comando_Stop, THE Bot SHALL verificar que el usuario posee el Rol_Administrador antes de procesar la solicitud.
2. WHEN un usuario con Rol_Administrador ejecuta el Comando_Stop, THE Bot SHALL invocar el método `serverAction` del NitradoApiClient con la acción STOP para el Servidor_DayZ correspondiente.
3. WHEN el NitradoApiClient completa la acción STOP exitosamente, THE Bot SHALL responder al usuario con un mensaje de confirmación indicando que el servidor se está deteniendo.
4. WHEN un usuario sin Rol_Administrador ejecuta el Comando_Stop, THE Bot SHALL responder con una Respuesta_Efímera indicando que no tiene permisos para ejecutar el comando.

### Requisito 3: Verificación de permisos por rol

**Historia de Usuario:** Como propietario del servidor de Discord, quiero que solo los administradores puedan controlar el servidor de juego, para evitar que usuarios no autorizados interrumpan las partidas.

#### Criterios de Aceptación

1. THE Bot SHALL verificar la presencia del Rol_Administrador en el miembro del servidor de Discord que ejecuta el comando, utilizando la API de permisos de JDA.
2. WHEN el Bot no puede determinar los roles del usuario (por ejemplo, si el comando se ejecuta fuera de un servidor de Discord), THE Bot SHALL denegar la ejecución y responder con una Respuesta_Efímera indicando que el comando solo está disponible en servidores.

### Requisito 4: Selección del servidor DayZ

**Historia de Usuario:** Como administrador, quiero que el bot identifique automáticamente el servidor DayZ disponible, para no tener que recordar identificadores técnicos.

#### Criterios de Aceptación

1. WHEN un usuario con Rol_Administrador ejecuta el Comando_Restart o el Comando_Stop, THE Bot SHALL obtener la lista de servidores DayZ disponibles mediante el método `getServers` del NitradoApiClient.
2. WHEN el NitradoApiClient retorna exactamente un Servidor_DayZ, THE Bot SHALL ejecutar la acción sobre ese servidor sin solicitar selección adicional.
3. WHEN el NitradoApiClient retorna más de un Servidor_DayZ, THE Bot SHALL presentar al usuario una lista con los nombres y estados de los servidores disponibles para que seleccione uno.
4. WHEN el NitradoApiClient retorna cero servidores DayZ, THE Bot SHALL responder con una Respuesta_Efímera indicando que no se encontraron servidores DayZ disponibles.

### Requisito 5: Manejo de errores de la API de Nitrado

**Historia de Usuario:** Como administrador, quiero recibir mensajes claros cuando algo falle al controlar el servidor, para saber qué ocurrió y si debo intentar de nuevo.

#### Criterios de Aceptación

1. IF el NitradoApiClient lanza una excepción de conexión al ejecutar una acción, THEN THE Bot SHALL responder con una Respuesta_Efímera indicando que no se pudo contactar con el servicio de Nitrado.
2. IF el NitradoApiClient lanza una excepción de autenticación, THEN THE Bot SHALL responder con una Respuesta_Efímera indicando que hay un problema de autenticación con la API de Nitrado.
3. IF el NitradoApiClient lanza una excepción de servidor no encontrado, THEN THE Bot SHALL responder con una Respuesta_Efímera indicando que el servidor especificado no fue encontrado.
4. IF el NitradoApiClient lanza cualquier otra excepción, THEN THE Bot SHALL responder con una Respuesta_Efímera indicando que ocurrió un error inesperado y registrar el error en los logs del Bot.

### Requisito 6: Retroalimentación inmediata al usuario

**Historia de Usuario:** Como administrador, quiero recibir confirmación inmediata de que mi comando fue recibido, para no quedarme esperando sin saber si funcionó.

#### Criterios de Aceptación

1. WHEN un usuario ejecuta el Comando_Restart o el Comando_Stop, THE Bot SHALL enviar una respuesta diferida (deferred reply) dentro de los 3 segundos posteriores a la recepción del evento, indicando que la solicitud está siendo procesada.
2. WHEN la acción del NitradoApiClient se completa, THE Bot SHALL actualizar la respuesta diferida con el resultado final (éxito o error).

### Requisito 7: Registro de comandos slash en Discord

**Historia de Usuario:** Como desarrollador, quiero que los nuevos comandos se registren automáticamente en Discord al iniciar el bot, para que estén disponibles sin intervención manual.

#### Criterios de Aceptación

1. THE Bot SHALL registrar el Comando_Restart y el Comando_Stop como comandos slash globales a través del CommandRegistry existente durante la inicialización.
2. THE Bot SHALL incluir una descripción en español para cada comando registrado que indique su función.
