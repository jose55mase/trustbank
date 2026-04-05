# Documento de Requisitos - Nitrado Server Manager

## Introducción

Aplicación móvil/escritorio desarrollada en Flutter que permite a administradores de servidores DayZ conectarse a la API de Nitrado para gestionar y monitorear su servidor de forma remota. La aplicación proporciona una interfaz gráfica intuitiva para controlar el estado del servidor, editar archivos de configuración, gestionar jugadores y supervisar el rendimiento del servidor sin necesidad de acceder directamente al panel web de Nitrado.

## Glosario

- **App**: La aplicación Flutter de administración de servidores DayZ
- **API_Nitrado**: La API REST de Nitrado (https://api.nitrado.net) utilizada para interactuar con los servicios del servidor
- **Token_OAuth**: Token de autenticación OAuth2 proporcionado por Nitrado para autorizar las solicitudes a la API
- **Servidor_DayZ**: Instancia de servidor de juego DayZ alojada en Nitrado
- **Panel_Estado**: Vista principal que muestra el estado actual del servidor (online, offline, reiniciando)
- **Editor_Configuración**: Componente de la App que permite editar archivos de configuración del servidor
- **Gestor_Jugadores**: Componente de la App que permite ver y administrar jugadores conectados
- **Archivo_Types**: Archivo `db/types.xml` que define todos los items del juego y sus propiedades de spawn
- **Archivo_Gameplay**: Archivo `cfggameplay.json` que controla la configuración principal de la experiencia de juego
- **Archivo_Eventos**: Archivo `db/events.xml` que define eventos de spawn para animales, zombies e items especiales
- **Archivo_Globals**: Archivo `db/globals.xml` que contiene variables globales del servidor
- **Almacenamiento_Seguro**: Sistema de almacenamiento cifrado local del dispositivo para guardar credenciales

## Requisitos

### Requisito 1: Autenticación con la API de Nitrado

**User Story:** Como administrador de servidor, quiero autenticarme con la API de Nitrado usando mi token OAuth, para poder acceder a las funcionalidades de gestión de mi servidor de forma segura.

#### Criterios de Aceptación

1. WHEN el administrador ingresa un Token_OAuth válido, THE App SHALL autenticar la sesión y almacenar el token en el Almacenamiento_Seguro del dispositivo
2. WHEN el administrador abre la App con un Token_OAuth previamente almacenado, THE App SHALL validar el token contra la API_Nitrado y restaurar la sesión automáticamente
3. IF el Token_OAuth es inválido o ha expirado, THEN THE App SHALL mostrar un mensaje de error descriptivo e indicar al administrador que ingrese un nuevo token
4. WHEN el administrador selecciona cerrar sesión, THE App SHALL eliminar el Token_OAuth del Almacenamiento_Seguro y redirigir a la pantalla de autenticación
5. THE App SHALL transmitir el Token_OAuth únicamente a través de conexiones HTTPS

### Requisito 2: Visualización del Estado del Servidor

**User Story:** Como administrador de servidor, quiero ver el estado actual de mi servidor DayZ en tiempo real, para poder monitorear su disponibilidad y rendimiento.

#### Criterios de Aceptación

1. WHEN el administrador accede al Panel_Estado, THE App SHALL consultar la API_Nitrado y mostrar el estado actual del Servidor_DayZ (online, offline, reiniciando, instalando)
2. WHILE el Panel_Estado está visible, THE App SHALL actualizar el estado del servidor cada 30 segundos
3. THE Panel_Estado SHALL mostrar la siguiente información del Servidor_DayZ: nombre del servidor, dirección IP, puerto, número de jugadores conectados, máximo de jugadores, mapa activo y versión del juego
4. IF la API_Nitrado no responde dentro de 10 segundos, THEN THE App SHALL mostrar un indicador de error de conexión y ofrecer la opción de reintentar
5. WHEN el estado del Servidor_DayZ cambia, THE App SHALL actualizar el indicador visual de estado con un código de color (verde para online, rojo para offline, amarillo para reiniciando)

### Requisito 3: Control del Servidor (Iniciar, Detener, Reiniciar)

**User Story:** Como administrador de servidor, quiero poder iniciar, detener y reiniciar mi servidor DayZ desde la aplicación, para gestionar su disponibilidad sin acceder al panel web.

#### Criterios de Aceptación

1. WHEN el administrador selecciona la acción de reiniciar, THE App SHALL enviar la solicitud de reinicio a la API_Nitrado y mostrar una confirmación previa al administrador
2. WHEN el administrador selecciona la acción de detener, THE App SHALL enviar la solicitud de detención a la API_Nitrado tras confirmación del administrador
3. WHEN el administrador selecciona la acción de iniciar, THE App SHALL enviar la solicitud de inicio a la API_Nitrado y mostrar el progreso del arranque
4. IF la acción de control del servidor falla, THEN THE App SHALL mostrar el mensaje de error devuelto por la API_Nitrado
5. WHILE el Servidor_DayZ está en proceso de reinicio o arranque, THE App SHALL deshabilitar los botones de control del servidor y mostrar un indicador de progreso

### Requisito 4: Gestión de Jugadores

**User Story:** Como administrador de servidor, quiero ver la lista de jugadores conectados y poder gestionar sus permisos, para mantener el orden en mi servidor.

#### Criterios de Aceptación

1. WHEN el administrador accede al Gestor_Jugadores, THE App SHALL consultar la API_Nitrado y mostrar la lista de jugadores conectados al Servidor_DayZ
2. WHEN el administrador selecciona expulsar a un jugador, THE App SHALL enviar la solicitud de expulsión a la API_Nitrado tras confirmación del administrador
3. WHEN el administrador selecciona banear a un jugador, THE App SHALL enviar la solicitud de baneo a la API_Nitrado con un campo opcional para el motivo del baneo
4. WHEN el administrador accede a la lista de baneados, THE App SHALL mostrar todos los jugadores baneados con la opción de desbanear
5. IF la lista de jugadores no puede obtenerse, THEN THE App SHALL mostrar un mensaje indicando que el servidor puede estar offline o la consulta falló

### Requisito 5: Editor de Archivos de Configuración del Servidor

**User Story:** Como administrador de servidor, quiero editar los archivos de configuración de mi servidor DayZ desde la aplicación, para ajustar la experiencia de juego sin usar herramientas externas.

#### Criterios de Aceptación

1. WHEN el administrador accede al Editor_Configuración, THE App SHALL listar los archivos de configuración disponibles en el Servidor_DayZ obtenidos a través de la API_Nitrado
2. WHEN el administrador selecciona un archivo de configuración, THE App SHALL descargar el contenido del archivo desde la API_Nitrado y mostrarlo en un editor de texto con resaltado de sintaxis para XML y JSON
3. WHEN el administrador guarda cambios en un archivo de configuración, THE App SHALL subir el archivo modificado al Servidor_DayZ a través de la API_Nitrado
4. IF el archivo de configuración contiene errores de sintaxis XML o JSON, THEN THE App SHALL señalar los errores antes de permitir la subida del archivo
5. WHEN el administrador edita el Archivo_Gameplay, THE Editor_Configuración SHALL validar que el contenido sea JSON válido antes de guardar
6. WHEN el administrador edita un archivo XML (Archivo_Types, Archivo_Eventos), THE Editor_Configuración SHALL validar que el contenido sea XML bien formado antes de guardar

### Requisito 6: Gestión Visual de Items (types.xml)

**User Story:** Como administrador de servidor, quiero una interfaz visual para gestionar los items del juego en el archivo types.xml, para modificar el loot del servidor de forma intuitiva sin editar XML manualmente.

#### Criterios de Aceptación

1. WHEN el administrador accede a la gestión de items, THE App SHALL parsear el Archivo_Types y mostrar una lista de items con búsqueda y filtrado por nombre, categoría y zona de uso
2. WHEN el administrador selecciona un item de la lista, THE App SHALL mostrar un formulario con los campos editables: nominal, lifetime, restock, min, quantmin, quantmax, cost, flags, category, usage y value
3. WHEN el administrador modifica los valores de un item y confirma los cambios, THE App SHALL actualizar el Archivo_Types en el Servidor_DayZ a través de la API_Nitrado
4. THE App SHALL parsear el Archivo_Types en objetos estructurados y formatear los objetos de vuelta a XML válido, de modo que parsear el XML resultante produzca un objeto equivalente al original (propiedad de ida y vuelta)
5. IF el administrador establece un valor de nominal menor que el valor de min para un item, THEN THE App SHALL mostrar una advertencia indicando la inconsistencia
6. WHEN el administrador filtra items por categoría, THE App SHALL mostrar únicamente los items que pertenecen a la categoría seleccionada (weapons, tools, containers, clothes, food, explosives, books)


### Requisito 7: Gestión de Variables Globales del Servidor

**User Story:** Como administrador de servidor, quiero modificar las variables globales del servidor desde una interfaz visual, para ajustar parámetros como el máximo de zombies o el tiempo de limpieza sin editar XML.

#### Criterios de Aceptación

1. WHEN el administrador accede a la gestión de variables globales, THE App SHALL parsear el Archivo_Globals y mostrar cada variable con su nombre, valor actual y una descripción legible
2. WHEN el administrador modifica el valor de una variable global y confirma, THE App SHALL actualizar el Archivo_Globals en el Servidor_DayZ a través de la API_Nitrado
3. IF el administrador ingresa un valor no numérico para una variable que requiere un número, THEN THE App SHALL rechazar el valor y mostrar un mensaje de validación
4. THE App SHALL parsear el Archivo_Globals en objetos estructurados y formatear los objetos de vuelta a XML válido, de modo que parsear el XML resultante produzca un objeto equivalente al original (propiedad de ida y vuelta)

### Requisito 8: Gestión de Eventos de Spawn

**User Story:** Como administrador de servidor, quiero gestionar los eventos de spawn de animales, zombies e items especiales desde una interfaz visual, para controlar la población del servidor.

#### Criterios de Aceptación

1. WHEN el administrador accede a la gestión de eventos, THE App SHALL parsear el Archivo_Eventos y mostrar una lista de eventos con su nombre, nominal, estado (activo/inactivo) y tipo
2. WHEN el administrador selecciona un evento, THE App SHALL mostrar un formulario con los campos editables: nominal, min, max, lifetime, saferadius, position, active y la lista de children
3. WHEN el administrador modifica un evento y confirma los cambios, THE App SHALL actualizar el Archivo_Eventos en el Servidor_DayZ a través de la API_Nitrado
4. WHEN el administrador cambia el campo active de un evento a 0, THE App SHALL mostrar el evento como desactivado en la lista
5. THE App SHALL parsear el Archivo_Eventos en objetos estructurados y formatear los objetos de vuelta a XML válido, de modo que parsear el XML resultante produzca un objeto equivalente al original (propiedad de ida y vuelta)

### Requisito 9: Visualización de Logs del Servidor

**User Story:** Como administrador de servidor, quiero ver los logs del servidor desde la aplicación, para diagnosticar problemas y monitorear la actividad.

#### Criterios de Aceptación

1. WHEN el administrador accede a la sección de logs, THE App SHALL obtener los logs más recientes del Servidor_DayZ a través de la API_Nitrado
2. THE App SHALL mostrar los logs con formato legible, diferenciando visualmente los niveles de log (error, advertencia, información)
3. WHEN el administrador utiliza el campo de búsqueda en los logs, THE App SHALL filtrar las entradas que contengan el texto buscado
4. WHILE el administrador está en la sección de logs, THE App SHALL ofrecer la opción de actualizar los logs manualmente

### Requisito 10: Navegación y Experiencia de Usuario

**User Story:** Como administrador de servidor, quiero una interfaz organizada y responsiva, para gestionar mi servidor de forma eficiente desde cualquier dispositivo.

#### Criterios de Aceptación

1. THE App SHALL organizar las funcionalidades en secciones accesibles desde un menú de navegación principal: Estado, Control, Jugadores, Configuración, Items, Eventos, Globals, Logs
2. THE App SHALL adaptar su diseño a diferentes tamaños de pantalla (móvil, tablet, escritorio)
3. WHILE la App está realizando una operación contra la API_Nitrado, THE App SHALL mostrar un indicador de carga visible al administrador
4. WHEN una operación contra la API_Nitrado se completa con éxito, THE App SHALL mostrar una notificación de confirmación temporal
5. THE App SHALL mantener un esquema de colores consistente con indicadores visuales claros para estados del servidor (verde: online, rojo: offline, amarillo: en proceso)

### Requisito 11: Selección de Servidor

**User Story:** Como administrador de servidor, quiero poder seleccionar entre múltiples servidores asociados a mi cuenta de Nitrado, para gestionar diferentes servidores desde la misma aplicación.

#### Criterios de Aceptación

1. WHEN el administrador se autentica exitosamente, THE App SHALL consultar la API_Nitrado y mostrar la lista de servidores DayZ disponibles en la cuenta
2. WHEN el administrador selecciona un servidor de la lista, THE App SHALL cargar la información de ese Servidor_DayZ y navegar al Panel_Estado
3. WHEN el administrador desea cambiar de servidor, THE App SHALL permitir regresar a la lista de servidores desde cualquier sección de la aplicación
4. IF la cuenta del administrador no tiene servidores DayZ activos, THEN THE App SHALL mostrar un mensaje indicando que no se encontraron servidores DayZ activos
