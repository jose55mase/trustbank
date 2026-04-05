# Plan de Implementación: Nitrado Server Manager

## Visión General

Implementación incremental de la aplicación Flutter siguiendo Clean Architecture con Riverpod. Cada tarea construye sobre las anteriores, comenzando por la estructura del proyecto y modelos de datos, avanzando hacia la lógica de negocio y finalizando con la integración de todas las pantallas.

El proyecto se crea en `nitrado_server_manager/` en la raíz del workspace, independiente de `dayzOffline.chernarusplus/`.

## Tareas

- [x] 1. Crear proyecto Flutter y estructura base
  - Ejecutar `flutter create nitrado_server_manager` en la raíz del workspace
  - Configurar `pubspec.yaml` con dependencias: `flutter_riverpod`, `riverpod_annotation`, `go_router`, `dio`, `flutter_secure_storage`, `xml`, `mocktail`, `glados` (o `dart_check`)
  - Crear la estructura de carpetas según el diseño: `lib/core/`, `lib/features/`, `lib/shared/`, `test/`
  - Crear `lib/main.dart` con `ProviderScope` y `lib/app.dart` con `MaterialApp.router`
  - Configurar GoRouter con las rutas principales: `/auth`, `/servers`, `/dashboard`, `/control`, `/players`, `/config`, `/types`, `/globals`, `/events`, `/logs`
  - _Requisitos: 10.1, 10.2, 10.5_

- [x] 2. Implementar modelos de datos y servicios de parseo XML
  - [x] 2.1 Crear modelos de dominio
    - Implementar clases: `GameServer`, `Player`, `BannedPlayer`, `ServerAction` (enum), `DayzType`, `DayzTypeFlags`, `GlobalVariable`, `SpawnEvent`, `SpawnEventFlags`, `EventChild`, `FileEntry`
    - Incluir métodos `==` y `hashCode` (o usar `equatable`/`freezed`) para comparación por valor
    - _Requisitos: 2.3, 6.2, 7.1, 8.1_

  - [x] 2.2 Implementar XmlParserService
    - Implementar `parseTypes` / `serializeTypes` para types.xml
    - Implementar `parseGlobals` / `serializeGlobals` para globals.xml
    - Implementar `parseEvents` / `serializeEvents` para events.xml
    - Implementar `isValidXml` e `isValidJson`
    - _Requisitos: 5.4, 5.5, 5.6, 6.4, 7.4, 8.5_

  - [x] 2.3 Test de propiedad: Round trip de types.xml
    - **Propiedad 7: Round trip de types.xml**
    - Generar listas aleatorias de `DayzType`, serializar a XML y parsear de vuelta; verificar equivalencia
    - **Valida: Requisito 6.4**

  - [x] 2.4 Test de propiedad: Round trip de globals.xml
    - **Propiedad 10: Round trip de globals.xml**
    - Generar listas aleatorias de `GlobalVariable`, serializar a XML y parsear de vuelta; verificar equivalencia
    - **Valida: Requisito 7.4**

  - [x] 2.5 Test de propiedad: Round trip de events.xml
    - **Propiedad 12: Round trip de events.xml**
    - Generar listas aleatorias de `SpawnEvent`, serializar a XML y parsear de vuelta; verificar equivalencia
    - **Valida: Requisito 8.5**

  - [x] 2.6 Test de propiedad: Validación de sintaxis XML y JSON
    - **Propiedad 6: Validación de sintaxis XML y JSON**
    - Generar strings aleatorios y verificar que `isValidXml`/`isValidJson` aceptan solo contenido válido
    - **Valida: Requisitos 5.4, 5.5, 5.6**

- [x] 3. Checkpoint - Verificar modelos y parseo XML
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 4. Implementar capa de autenticación
  - [x] 4.1 Implementar AuthService con almacenamiento seguro
    - Crear interfaz `AuthService` y su implementación usando `flutter_secure_storage`
    - Implementar `saveToken`, `getToken`, `validateToken`, `deleteToken`, `isAuthenticated`
    - Crear provider de Riverpod para `AuthService`
    - _Requisitos: 1.1, 1.2, 1.4, 1.5_

  - [x] 4.2 Crear pantalla de autenticación
    - Implementar UI con campo de texto para el Token_OAuth y botón de autenticación
    - Mostrar errores descriptivos si el token es inválido o expirado
    - Redirigir al listado de servidores tras autenticación exitosa
    - Implementar lógica de restauración automática de sesión al abrir la app
    - _Requisitos: 1.1, 1.2, 1.3_

  - [x] 4.3 Test de propiedad: Round trip de almacenamiento de token
    - **Propiedad 1: Round trip de almacenamiento de token**
    - Para cualquier token no vacío, `saveToken` seguido de `getToken` devuelve el mismo token; `deleteToken` seguido de `getToken` devuelve null
    - **Valida: Requisitos 1.1, 1.4**

- [x] 5. Implementar cliente API de Nitrado
  - [x] 5.1 Crear NitradoApiClient con Dio
    - Implementar interfaz `NitradoApiClient` y su implementación con `Dio`
    - Configurar interceptor para inyectar token OAuth en headers
    - Implementar timeout de 10 segundos y reintentos automáticos (3 reintentos con backoff exponencial para GET)
    - Implementar manejo de errores: 4xx muestra mensaje de API, 5xx muestra error genérico, token inválido redirige a auth
    - _Requisitos: 1.5, 2.4, 3.4_

  - [x] 5.2 Implementar endpoints del servidor
    - `getServers()`, `getServerStatus()`, `serverAction()` (start, stop, restart)
    - `getPlayers()`, `kickPlayer()`, `banPlayer()`, `getBanList()`, `unbanPlayer()`
    - `listFiles()`, `downloadFile()`, `uploadFile()`
    - `getServerLogs()`
    - _Requisitos: 2.1, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 9.1_

  - [x] 5.3 Test de propiedad: Propagación de errores de API
    - **Propiedad 4: Propagación de errores de API en control del servidor**
    - Para cualquier mensaje de error no vacío de la API, el estado de error presentado al usuario debe contenerlo
    - **Valida: Requisito 3.4**

- [x] 6. Checkpoint - Verificar autenticación y cliente API
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 7. Implementar selección de servidor y dashboard
  - [x] 7.1 Crear pantalla de selección de servidor
    - Consultar `getServers()` y mostrar lista de servidores DayZ
    - Al seleccionar un servidor, navegar al dashboard con el servidor seleccionado
    - Mostrar mensaje si no hay servidores DayZ activos
    - Permitir regresar a la lista de servidores desde cualquier sección
    - _Requisitos: 11.1, 11.2, 11.3, 11.4_

  - [x] 7.2 Crear pantalla de dashboard (Panel_Estado)
    - Mostrar información completa del servidor: nombre, IP, puerto, jugadores, mapa, versión
    - Implementar indicador visual de estado con código de color (verde/rojo/amarillo)
    - Implementar auto-refresh cada 30 segundos
    - Mostrar indicador de error de conexión con opción de reintentar
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [x] 7.3 Test de propiedad: Información completa del servidor
    - **Propiedad 2: Información completa del servidor en dashboard**
    - Para cualquier `GameServer` aleatorio, la representación del dashboard debe contener todos los campos requeridos
    - **Valida: Requisito 2.3**

  - [x] 7.4 Test de propiedad: Mapeo estado-color del servidor
    - **Propiedad 3: Mapeo estado-color del servidor**
    - Para cualquier estado válido, verificar que el color asignado es correcto (verde=started, rojo=stopped, amarillo=restarting/installing)
    - **Valida: Requisito 2.5**

- [x] 8. Implementar control del servidor
  - [x] 8.1 Crear pantalla de control del servidor
    - Implementar botones de iniciar, detener y reiniciar con diálogos de confirmación
    - Mostrar indicador de progreso durante operaciones
    - Deshabilitar botones cuando el servidor está en proceso de reinicio o arranque
    - Mostrar mensajes de error de la API al usuario
    - Mostrar notificación de éxito tras completar una acción
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 3.5, 10.3, 10.4_

  - [x] 8.2 Test de propiedad: Deshabilitación de controles durante operaciones
    - **Propiedad 5: Deshabilitación de controles durante operaciones en curso**
    - Para estados "restarting" o "installing", los botones de control deben estar deshabilitados
    - **Valida: Requisito 3.5**

- [x] 9. Implementar gestión de jugadores
  - [x] 9.1 Crear pantalla de gestión de jugadores
    - Mostrar lista de jugadores conectados consultando la API
    - Implementar acciones de expulsar y banear con diálogos de confirmación
    - Campo opcional de motivo para baneo
    - Implementar vista de lista de baneados con opción de desbanear
    - Mostrar mensaje si el servidor está offline o la consulta falla
    - _Requisitos: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 10. Implementar editor de archivos de configuración
  - [x] 10.1 Crear pantalla de editor de configuración
    - Listar archivos de configuración disponibles desde la API
    - Implementar editor de texto con resaltado de sintaxis para XML y JSON
    - Validar sintaxis XML/JSON antes de permitir subida
    - Subir archivo modificado al servidor tras guardar
    - _Requisitos: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 11. Checkpoint - Verificar funcionalidades principales
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 12. Implementar gestión visual de items (types.xml)
  - [x] 12.1 Crear pantalla de gestión de items
    - Parsear types.xml y mostrar lista de items con búsqueda y filtrado por nombre, categoría y zona de uso
    - Implementar formulario de edición con campos: nominal, lifetime, restock, min, quantmin, quantmax, cost, flags, category, usage, value
    - Validar que nominal >= min y mostrar advertencia si no se cumple
    - Guardar cambios serializando a XML y subiendo al servidor
    - _Requisitos: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [x] 12.2 Test de propiedad: Filtrado de items por categoría
    - **Propiedad 8: Filtrado de items por categoría**
    - Para cualquier lista de DayzType y categoría válida, el filtrado devuelve exactamente los items de esa categoría
    - **Valida: Requisitos 6.1, 6.6**

  - [x] 12.3 Test de propiedad: Validación nominal >= min
    - **Propiedad 9: Validación nominal >= min en types**
    - Para cualquier DayzType con nominal < min, la validación debe detectar la inconsistencia
    - **Valida: Requisito 6.5**

- [x] 13. Implementar gestión de variables globales (globals.xml)
  - [x] 13.1 Crear pantalla de gestión de variables globales
    - Parsear globals.xml y mostrar cada variable con nombre, valor y descripción
    - Implementar edición de valores con validación numérica
    - Rechazar valores no numéricos y mostrar mensaje de validación
    - Guardar cambios serializando a XML y subiendo al servidor
    - _Requisitos: 7.1, 7.2, 7.3, 7.4_

  - [x] 13.2 Test de propiedad: Validación numérica de variables globales
    - **Propiedad 11: Validación numérica de variables globales**
    - Para cualquier string no numérico, la validación debe rechazar el valor
    - **Valida: Requisito 7.3**

- [x] 14. Implementar gestión de eventos de spawn (events.xml)
  - [x] 14.1 Crear pantalla de gestión de eventos
    - Parsear events.xml y mostrar lista de eventos con nombre, nominal, estado activo/inactivo y tipo
    - Implementar formulario de edición con campos: nominal, min, max, lifetime, saferadius, position, active, children
    - Mostrar eventos con active=0 como desactivados
    - Guardar cambios serializando a XML y subiendo al servidor
    - _Requisitos: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [x] 14.2 Test de propiedad: Mapeo estado activo/inactivo de eventos
    - **Propiedad 13: Mapeo estado activo/inactivo de eventos**
    - Para cualquier SpawnEvent, active=0 se muestra como desactivado, active=1 como activado
    - **Valida: Requisito 8.4**

- [x] 15. Implementar visualización de logs
  - [x] 15.1 Crear pantalla de logs del servidor
    - Obtener logs del servidor a través de la API
    - Mostrar logs con formato legible y diferenciación visual por nivel (error, warning, info)
    - Implementar campo de búsqueda para filtrar entradas de log
    - Implementar botón de actualización manual de logs
    - _Requisitos: 9.1, 9.2, 9.3, 9.4_

  - [x] 15.2 Test de propiedad: Clasificación de niveles de log
    - **Propiedad 14: Clasificación de niveles de log**
    - Para entradas con indicadores "ERROR", "WARNING", "INFO", la clasificación asigna el nivel correcto
    - **Valida: Requisito 9.2**

  - [x] 15.3 Test de propiedad: Filtrado de logs por texto de búsqueda
    - **Propiedad 15: Filtrado de logs por texto de búsqueda**
    - Para cualquier lista de logs y string de búsqueda, el filtrado devuelve exactamente las entradas que contienen el texto (case-insensitive)
    - **Valida: Requisito 9.3**

- [x] 16. Integración final y navegación
  - [x] 16.1 Conectar navegación completa
    - Implementar menú de navegación principal con todas las secciones: Estado, Control, Jugadores, Configuración, Items, Eventos, Globals, Logs
    - Implementar diseño responsivo para móvil (drawer), tablet y escritorio (sidebar)
    - Implementar indicadores de carga globales durante operaciones API
    - Implementar notificaciones de confirmación temporales tras operaciones exitosas
    - Aplicar esquema de colores consistente en toda la app
    - _Requisitos: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 17. Checkpoint final - Verificar integración completa
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia requisitos específicos para trazabilidad
- Los checkpoints aseguran validación incremental
- Los tests de propiedades validan propiedades universales de corrección
- Los tests unitarios validan ejemplos específicos y casos edge
