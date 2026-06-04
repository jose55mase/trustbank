# Documento de Requisitos — Kill Feed Discord

## Introducción

Este documento define los requisitos para el sistema de Kill Feed de DayZ integrado con Discord. La funcionalidad permite a los administradores de un servidor de Discord configurar un canal donde se publican automáticamente eventos de muerte (kills) extraídos de los logs del servidor DayZ alojado en Nitrado. El sistema realiza un sondeo periódico de los logs, parsea los eventos de muerte y publica embeds enriquecidos visualmente en el canal configurado.

## Glosario

- **Kill_Feed_System**: Componente principal que orquesta el sondeo de logs, el parseo de eventos de muerte y la publicación de embeds en Discord.
- **Kill_Event**: Estructura de datos que representa un evento de muerte extraído de los logs del servidor DayZ, conteniendo nombre del asesino, nombre de la víctima, arma/causa, distancia, ubicación y marca de tiempo.
- **Log_Parser**: Componente encargado de analizar el contenido del archivo `server_log.ADM` y extraer los eventos de muerte como objetos `Kill_Event`.
- **Kill_Feed_Channel_Config**: Entidad persistida que almacena la asociación entre un servidor de Discord (guild), un canal de Discord y un servicio de Nitrado para la publicación del kill feed.
- **Embed_Builder**: Componente que construye los embeds de Discord enriquecidos a partir de un `Kill_Event`.
- **Poll_Scheduler**: Tarea programada de Spring que ejecuta el ciclo de sondeo de logs periódicamente.
- **NitradoApiClient**: Servicio existente que se comunica con la API de Nitrado, incluyendo el método `getServerLogs(int serviceId)` para descargar el archivo de log del servidor.
- **MessageSender**: Componente existente para enviar mensajes a canales de Discord.
- **SlashCommand**: Interfaz existente que define el contrato para comandos slash de Discord.
- **Guild**: Servidor de Discord donde opera el bot.
- **ADM_Log**: Archivo de log del servidor DayZ en formato `server_log.ADM` que contiene eventos del juego, incluyendo muertes de jugadores.

## Requisitos

### Requisito 1: Comando de Configuración del Canal de Kill Feed

**Historia de Usuario:** Como administrador de un servidor de Discord, quiero vincular un canal de Discord a un servidor DayZ de Nitrado para recibir el kill feed, de modo que los miembros del servidor puedan ver los eventos de muerte en tiempo casi real.

#### Criterios de Aceptación

1. THE Kill_Feed_System SHALL proporcionar un comando slash `/killfeed` con las subacciones `setup`, `remove` y `test`.
2. WHEN un administrador ejecuta `/killfeed setup` con un canal de Discord y un ID de servicio de Nitrado, THE Kill_Feed_System SHALL almacenar la configuración que asocia el guild, el canal y el servicio de Nitrado.
3. WHEN un usuario sin permisos de administrador ejecuta `/killfeed setup`, THE Kill_Feed_System SHALL responder con un mensaje efímero indicando que se requieren permisos de administrador.
4. WHEN un administrador ejecuta `/killfeed setup` y ya existe una configuración para ese guild, THE Kill_Feed_System SHALL reemplazar la configuración anterior con la nueva.
5. WHEN un administrador ejecuta `/killfeed remove`, THE Kill_Feed_System SHALL eliminar la configuración de kill feed para ese guild y confirmar la eliminación.
6. WHEN un administrador ejecuta `/killfeed remove` y no existe configuración para ese guild, THE Kill_Feed_System SHALL responder indicando que no hay configuración activa.
7. WHEN un administrador ejecuta `/killfeed setup` con un ID de servicio de Nitrado inválido, THE Kill_Feed_System SHALL validar el ID contra la API de Nitrado y responder con un error descriptivo.

### Requisito 2: Sondeo Periódico de Logs

**Historia de Usuario:** Como administrador del servidor, quiero que el sistema consulte automáticamente los logs del servidor DayZ cada 5 minutos, de modo que los eventos de muerte se detecten sin intervención manual.

#### Criterios de Aceptación

1. THE Poll_Scheduler SHALL ejecutar el ciclo de sondeo de logs cada 5 minutos utilizando la programación de tareas de Spring.
2. WHEN el ciclo de sondeo se ejecuta, THE Kill_Feed_System SHALL consultar todas las configuraciones activas de Kill_Feed_Channel_Config y descargar los logs correspondientes mediante `NitradoApiClient.getServerLogs(serviceId)`.
3. WHEN el ciclo de sondeo se ejecuta, THE Kill_Feed_System SHALL procesar únicamente los eventos de muerte que no hayan sido publicados previamente.
4. THE Kill_Feed_System SHALL mantener un registro del último evento procesado por cada configuración para evitar la publicación duplicada de eventos.
5. IF la descarga de logs falla por un error de conexión con Nitrado, THEN THE Kill_Feed_System SHALL registrar el error en el log de la aplicación y reintentar en el siguiente ciclo de sondeo.
6. IF la descarga de logs falla por un error de autenticación, THEN THE Kill_Feed_System SHALL registrar el error con nivel ERROR y omitir esa configuración hasta el siguiente ciclo.

### Requisito 3: Parseo de Eventos de Muerte del Log

**Historia de Usuario:** Como desarrollador, quiero que el sistema parsee correctamente los eventos de muerte del archivo `server_log.ADM` de DayZ, de modo que se extraigan todos los datos relevantes de cada kill.

#### Criterios de Aceptación

1. WHEN el Log_Parser recibe el contenido de un archivo `server_log.ADM`, THE Log_Parser SHALL identificar y extraer las líneas que corresponden a eventos de muerte de jugadores.
2. THE Log_Parser SHALL extraer los siguientes campos de cada evento de muerte: nombre del asesino, nombre de la víctima, arma o causa de muerte, distancia del disparo y coordenadas de ubicación.
3. THE Log_Parser SHALL extraer la marca de tiempo de cada línea de log y asociarla al Kill_Event correspondiente.
4. WHEN una línea de log contiene un evento de muerte pero tiene un formato inesperado o campos faltantes, THE Log_Parser SHALL registrar una advertencia y omitir esa línea sin interrumpir el procesamiento de las demás líneas.
5. THE Log_Parser SHALL ignorar las líneas del log que no correspondan a eventos de muerte de jugadores (conexiones, desconexiones, daño ambiental sin muerte, etc.).
6. FOR ALL Kill_Event válidos, parsear el evento y luego formatear el Kill_Event de vuelta a texto SHALL producir un objeto equivalente al original (propiedad de ida y vuelta).

### Requisito 4: Publicación de Embeds en Discord

**Historia de Usuario:** Como miembro de un servidor de Discord, quiero ver embeds visualmente atractivos con la información de cada kill, de modo que pueda seguir la actividad del servidor DayZ de forma intuitiva.

#### Criterios de Aceptación

1. WHEN un Kill_Event es procesado, THE Embed_Builder SHALL construir un embed de Discord que contenga: nombre del asesino, nombre de la víctima, arma utilizada, distancia del disparo, ubicación en el mapa y marca de tiempo.
2. THE Embed_Builder SHALL incluir un icono de calavera o muerte en el embed para hacerlo visualmente intuitivo.
3. THE Embed_Builder SHALL utilizar un color de acento consistente (rojo) para el borde lateral del embed.
4. WHEN el Kill_Feed_System tiene un Kill_Event listo para publicar, THE Kill_Feed_System SHALL enviar el embed al canal de Discord configurado en la Kill_Feed_Channel_Config correspondiente.
5. IF el canal de Discord configurado ya no existe o el bot no tiene permisos para enviar mensajes, THEN THE Kill_Feed_System SHALL registrar el error y omitir la publicación de ese evento sin interrumpir el procesamiento de los demás eventos.
6. THE Embed_Builder SHALL formatear la distancia en metros y las coordenadas de ubicación de forma legible para el usuario.

### Requisito 5: Control de Duplicados


**Historia de Usuario:** Como miembro del servidor de Discord, quiero ver solo eventos de muerte nuevos en el canal de kill feed, de modo que no se repitan publicaciones de eventos antiguos.

#### Criterios de Aceptación

1. THE Kill_Feed_System SHALL mantener en memoria la marca de tiempo o identificador del último evento procesado por cada configuración activa.
2. WHEN el ciclo de sondeo obtiene nuevos logs, THE Kill_Feed_System SHALL comparar cada evento con el último evento procesado y publicar únicamente los eventos posteriores.
3. WHEN el sistema se reinicia, THE Kill_Feed_System SHALL comenzar a procesar eventos desde el momento del reinicio, sin reprocesar eventos históricos del log completo.
4. WHEN dos eventos de muerte tienen la misma marca de tiempo, THE Kill_Feed_System SHALL utilizar el orden de aparición en el log para determinar cuáles son nuevos.

### Requisito 7: Comando de Prueba con Datos Dummy

**Historia de Usuario:** Como administrador del servidor de Discord, quiero poder enviar un embed de prueba con datos ficticios al canal configurado, de modo que pueda verificar que el formato visual y la configuración del canal son correctos sin necesitar logs reales de Nitrado.

#### Criterios de Aceptación

1. THE Kill_Feed_System SHALL proporcionar una subacción `/killfeed test` dentro del comando slash `/killfeed`.
2. WHEN un administrador ejecuta `/killfeed test`, THE Kill_Feed_System SHALL generar un Kill_Event con datos dummy realistas (nombres de jugadores ficticios, arma, distancia, ubicación y marca de tiempo actual) y publicar el embed correspondiente en el canal configurado.
3. WHEN un administrador ejecuta `/killfeed test` y no existe una configuración de kill feed para ese guild, THE Kill_Feed_System SHALL responder con un mensaje efímero indicando que primero debe configurar el canal con `/killfeed setup`.
4. WHEN un usuario sin permisos de administrador ejecuta `/killfeed test`, THE Kill_Feed_System SHALL responder con un mensaje efímero indicando que se requieren permisos de administrador.
5. THE Kill_Feed_System SHALL utilizar el mismo Embed_Builder que se usa para eventos reales al generar el embed de prueba, de modo que el resultado visual sea idéntico.

### Requisito 8: Manejo de Errores y Resiliencia

**Historia de Usuario:** Como administrador del bot, quiero que el sistema maneje errores de forma robusta, de modo que un fallo en un servidor no afecte el procesamiento de los demás servidores configurados.

#### Criterios de Aceptación

1. IF ocurre un error al procesar los logs de un servidor específico, THEN THE Kill_Feed_System SHALL registrar el error y continuar procesando los demás servidores configurados.
2. IF la API de Nitrado devuelve un error de servidor (5xx), THEN THE Kill_Feed_System SHALL registrar el error y reintentar en el siguiente ciclo de sondeo.
3. IF el contenido del log descargado está vacío, THEN THE Kill_Feed_System SHALL omitir el procesamiento para esa configuración sin registrar un error.
4. THE Kill_Feed_System SHALL registrar métricas de cada ciclo de sondeo: cantidad de configuraciones procesadas, cantidad de eventos nuevos encontrados y cantidad de embeds publicados.
