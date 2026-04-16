# Plan de Implementación: Delivery App (Domicilios)

## Visión General

Implementación incremental de la aplicación Flutter de domicilios siguiendo Clean Architecture con Riverpod. Se construyen primero los modelos y repositorios (dominio + datos mock), luego las pantallas de cada flujo (Usuario, Repartidor, Administrador), y finalmente se integra navegación, tema y notificaciones.

## Tareas

- [x] 1. Configurar estructura del proyecto y dependencias
  - Crear proyecto Flutter (si no existe) y configurar `pubspec.yaml` con dependencias: `flutter_riverpod`, `go_router`, `google_maps_flutter`, `flutter_local_notifications`, `uuid`, `glados` (dev), `mocktail` (dev)
  - Crear la estructura de carpetas: `lib/core/`, `lib/models/`, `lib/repositories/`, `lib/data/mock/`, `lib/providers/`, `lib/screens/` con subcarpetas `usuario/`, `repartidor/`, `admin/`, `auth/`
  - Crear `lib/core/constants.dart` con constantes de la app
  - _Requisitos: 10.1, 10.2, 11.1_

- [ ] 2. Implementar modelos de datos
  - [x] 2.1 Crear modelos principales: `Pedido`, `PedidoHistorial`, `Usuario`, `Repartidor`, `Administrador`, `Ubicacion` en `lib/models/`
    - Incluir enums `EstadoPedido`, `TipoEntrega`, `EstadoRepartidor`, `TipoUsuario`
    - Incluir `CrearPedidoRequest`, `AuthResult`, `SesionActiva`, `ReporteGanancias`, `GananciaPeriodo`, `ResumenDiario`
    - _Requisitos: 1.1, 3.2, 4.1, 5.2, 6.1, 10.3_

  - [x] 2.2 Escribir test de propiedad para modelo Pedido — campos requeridos
    - **Propiedad 6: Visualización de pedido contiene campos requeridos**
    - **Valida: Requisitos 2.3**

  - [x] 2.3 Escribir test de propiedad para modelo Repartidor — campos requeridos
    - **Propiedad 9: Información de repartidor contiene campos requeridos**
    - **Valida: Requisitos 4.1**

- [ ] 3. Implementar interfaces de repositorio
  - [x] 3.1 Crear `PedidoRepository` abstracto en `lib/repositories/pedido_repository.dart`
    - Definir métodos: `crearPedido`, `obtenerPedidosActivos`, `obtenerPedidoActivoPorUsuario`, `asignarRepartidor`, `actualizarEstadoPedido`, `confirmarEntrega`, `obtenerHistorial`, `obtenerHistorialUsuario`
    - _Requisitos: 1.2, 2.1, 3.2, 9.1, 9.3_

  - [x] 3.2 Crear `AuthRepository` abstracto en `lib/repositories/auth_repository.dart`
    - Definir métodos: `login`, `logout`, `obtenerSesionActiva`
    - _Requisitos: 5.1, 5.2, 5.3_

  - [x] 3.3 Crear `RepartidorRepository` abstracto en `lib/repositories/repartidor_repository.dart`
    - Definir métodos: `obtenerRepartidores`, `obtenerRepartidoresDisponibles`, `obtenerPedidosAsignados`, `obtenerHistorialRepartidor`, `obtenerResumenDiario`
    - _Requisitos: 4.1, 4.2, 13.1, 13.3_

  - [x] 3.4 Crear `GeolocalizacionRepository` abstracto en `lib/repositories/geolocalizacion_repository.dart`
    - Definir métodos: `iniciarRastreo`, `detenerRastreo`, `obtenerUbicacion`, `streamUbicacion`
    - _Requisitos: 7.1, 7.2, 7.4_

  - [x] 3.5 Crear `ReporteGananciasRepository` abstracto y `NotificacionService` abstracto
    - _Requisitos: 6.1, 12.1_

- [ ] 4. Implementar capa de datos mock
  - [x] 4.1 Crear `mock_data.dart` con datos de prueba realistas
    - Generar al menos 5 Usuarios, 3 Repartidores, 1 Administrador y 10 Pedidos en historial
    - _Requisitos: 10.4_

  - [x] 4.2 Implementar `MockPedidoRepository`
    - Implementar creación de pedido con generación de código único (uuid + substring de 6 caracteres)
    - Implementar validación de máximo 1 pedido activo por usuario
    - Implementar confirmación de entrega con verificación de código y movimiento a historial
    - Implementar listado de pedidos activos ordenados por fecha descendente
    - Implementar filtros de historial por fecha, repartidor y usuario
    - _Requisitos: 1.2, 1.4, 2.1, 3.2, 3.4, 3.5, 8.1, 8.2, 9.1, 9.2, 9.3_

  - [x] 4.3 Escribir test de propiedad — creación genera código único
    - **Propiedad 1: Creación de pedido genera código único**
    - **Valida: Requisitos 1.2**

  - [x] 4.4 Escribir test de propiedad — campos vacíos rechazados
    - **Propiedad 2: Campos vacíos son rechazados con validación**
    - **Valida: Requisitos 1.3**

  - [x] 4.5 Escribir test de propiedad — máximo 1 pedido activo por usuario
    - **Propiedad 3: Invariante de pedido único por usuario**
    - **Valida: Requisitos 1.4, 8.2**

  - [x] 4.6 Escribir test de propiedad — ordenamiento por fecha descendente
    - **Propiedad 4: Pedidos activos ordenados por fecha descendente**
    - **Valida: Requisitos 2.1**

  - [x] 4.7 Escribir test de propiedad — nuevo pedido en lista de activos
    - **Propiedad 5: Nuevo pedido aparece en lista de activos**
    - **Valida: Requisitos 2.2**

  - [x] 4.8 Escribir test de propiedad — round-trip de completación
    - **Propiedad 7: Round-trip de completación de pedido**
    - **Valida: Requisitos 3.2, 3.4, 3.5, 9.1, 9.2**

  - [x] 4.9 Escribir test de propiedad — código incorrecto rechazado
    - **Propiedad 8: Código de confirmación incorrecto es rechazado**
    - **Valida: Requisitos 3.3**

  - [x] 4.10 Escribir test de propiedad — usuario solo accede a sus pedidos
    - **Propiedad 13: Usuario solo accede a sus propios pedidos**
    - **Valida: Requisitos 8.1, 8.3**

  - [x] 4.11 Escribir test de propiedad — filtros de historial correctos
    - **Propiedad 14: Filtros de historial retornan solo registros coincidentes**
    - **Valida: Requisitos 4.3, 9.3**

  - [x] 4.12 Implementar `MockAuthRepository`
    - Implementar login con validación de credenciales contra datos mock
    - Implementar logout y gestión de sesión activa
    - Separar sesiones de Repartidor y Administrador
    - _Requisitos: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 4.13 Escribir test de propiedad — autenticación redirige según rol
    - **Propiedad 10: Autenticación redirige al panel correcto según rol**
    - **Valida: Requisitos 5.2, 5.3**

  - [x] 4.14 Escribir test de propiedad — credenciales inválidas rechazadas
    - **Propiedad 11: Credenciales inválidas son rechazadas**
    - **Valida: Requisitos 5.4**

  - [x] 4.15 Implementar `MockRepartidorRepository`
    - Implementar listado de repartidores y filtrado por disponibilidad
    - Implementar historial de entregas por repartidor con filtros de fecha
    - Implementar resumen diario (entregas completadas y ganancias del día)
    - _Requisitos: 4.1, 4.2, 4.3, 13.1, 13.3_

  - [x] 4.16 Escribir test de propiedad — resumen diario correcto
    - **Propiedad 18: Resumen diario del repartidor agrega correctamente**
    - **Valida: Requisitos 13.3**

  - [x] 4.17 Implementar `MockGeolocalizacionRepository`
    - Simular rastreo con ubicaciones aleatorias cada 10 segundos
    - Implementar inicio/detención de rastreo vinculado a pedidos
    - _Requisitos: 7.1, 7.2, 7.4_

  - [x] 4.18 Implementar `MockReporteGananciasRepository`
    - Calcular ganancias diarias, mensuales y anuales a partir de Pedido_Historial
    - _Requisitos: 6.1, 6.2, 6.3, 6.4, 6.5_

  - [x] 4.19 Escribir test de propiedad — agregación de ganancias correcta
    - **Propiedad 12: Agregación de ganancias es correcta**
    - **Valida: Requisitos 6.2, 6.3, 6.4, 6.5**

  - [x] 4.20 Implementar `MockNotificacionService`
    - Simular notificaciones locales para asignación, cambio de estado y entrega completada
    - _Requisitos: 12.1, 12.2, 12.3, 12.4_

  - [x] 4.21 Escribir test de propiedad — notificaciones por cambio de estado
    - **Propiedad 16: Cambios de estado generan notificaciones**
    - **Valida: Requisitos 12.1, 12.2, 12.3**

- [x] 5. Checkpoint — Verificar modelos, repositorios y capa mock
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.


- [ ] 6. Implementar Riverpod Providers
  - [x] 6.1 Crear `pedido_providers.dart` con providers para pedidos activos, historial y creación de pedido
    - Inyectar `PedidoRepository` vía Riverpod
    - _Requisitos: 1.2, 2.1, 9.1_

  - [x] 6.2 Crear `auth_providers.dart` con providers para login, logout y sesión activa
    - Inyectar `AuthRepository` vía Riverpod
    - _Requisitos: 5.1, 5.2, 5.3_

  - [x] 6.3 Crear `repartidor_providers.dart` con providers para repartidores, pedidos asignados y resumen diario
    - Inyectar `RepartidorRepository` vía Riverpod
    - _Requisitos: 4.1, 13.1, 13.3_

  - [x] 6.4 Crear `geolocalizacion_providers.dart` con provider de stream de ubicación
    - Inyectar `GeolocalizacionRepository` vía Riverpod
    - _Requisitos: 7.1, 7.2, 7.3_

- [ ] 7. Implementar tema oscuro y configuración de la app
  - [x] 7.1 Crear `app_theme.dart` con tema oscuro inspirado en Nequi
    - Definir paleta de colores morados/magenta sobre fondos oscuros
    - Asegurar contraste mínimo 4.5:1 entre texto y fondo
    - Definir estilos de texto, botones, tarjetas, inputs y navegación
    - _Requisitos: 11.1, 11.2, 11.3, 11.4_

  - [x] 7.2 Escribir test de propiedad — contraste de tema cumple accesibilidad
    - **Propiedad 15: Contraste de tema cumple accesibilidad**
    - **Valida: Requisitos 11.2**

  - [x] 7.3 Crear `app_router.dart` con GoRouter
    - Definir rutas para: pantalla inicial, formulario de pedido, seguimiento, login, panel repartidor, panel admin y sub-pantallas
    - Implementar guards de navegación por rol (repartidor solo accede a su panel, admin solo al suyo)
    - _Requisitos: 5.2, 5.3, 5.5_

  - [x] 7.4 Crear `app.dart` y actualizar `main.dart`
    - Configurar `ProviderScope`, `MaterialApp.router` con GoRouter y tema oscuro
    - Registrar implementaciones mock como providers de repositorios
    - _Requisitos: 10.1, 10.2, 11.4_

- [ ] 8. Implementar flujo de Usuario (sin registro)
  - [x] 8.1 Crear `formulario_pedido_screen.dart`
    - Formulario con campos: dirección de entrega, nombre, teléfono, descripción, precio del producto, tipo de entrega
    - Validación de campos obligatorios con mensajes específicos por campo faltante
    - Verificar si el usuario ya tiene pedido activo antes de permitir creación
    - Mostrar Código_Confirmación al crear pedido exitosamente
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [x] 8.2 Crear `seguimiento_pedido_screen.dart`
    - Mostrar estado actual del pedido con indicador visual
    - Integrar mapa con ubicación en tiempo real del repartidor (google_maps_flutter)
    - Mostrar mensaje cuando la ubicación no está disponible
    - _Requisitos: 7.3, 7.5_

  - [x] 8.3 Crear `historial_usuario_screen.dart`
    - Listar pedidos completados del usuario (filtrados por teléfono)
    - Mostrar datos de cada pedido del historial
    - _Requisitos: 8.1, 8.4_

  - [x] 8.4 Escribir test de propiedad — pedidos asignados con campos requeridos
    - **Propiedad 17: Panel de repartidor muestra pedidos asignados con campos requeridos**
    - **Valida: Requisitos 13.1**

- [ ] 9. Implementar flujo de Autenticación
  - [x] 9.1 Crear `login_screen.dart`
    - Selector de tipo de usuario: Repartidor o Administrador
    - Campos de usuario y contraseña
    - Mostrar mensaje de error para credenciales inválidas
    - Redirigir al panel correspondiente según rol tras login exitoso
    - _Requisitos: 5.1, 5.2, 5.3, 5.4_

- [ ] 10. Implementar Panel del Repartidor
  - [x] 10.1 Crear `panel_repartidor_screen.dart`
    - Listar pedidos activos asignados al repartidor con: dirección, nombre usuario, descripción, precio
    - Mostrar resumen del día: entregas completadas y ganancias
    - Mostrar mensaje cuando no hay entregas pendientes
    - _Requisitos: 13.1, 13.3, 13.4_

  - [x] 10.2 Crear `detalle_pedido_screen.dart` (repartidor)
    - Mostrar detalles completos del pedido asignado
    - Botones para actualizar estado: recogido, en camino, en destino
    - _Requisitos: 13.2_

  - [x] 10.3 Crear `confirmacion_entrega_screen.dart`
    - Campo para ingresar Código_Confirmación
    - Validar código contra el pedido activo
    - Mostrar error si código es incorrecto, permitir reintentos
    - Marcar pedido como completado si código es correcto
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 11. Checkpoint — Verificar flujos de Usuario y Repartidor
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [ ] 12. Implementar Panel de Administración
  - [x] 12.1 Crear `panel_admin_screen.dart`
    - Navegación por tabs: Cola de Pedidos, Repartidores, Historial, Ganancias
    - _Requisitos: 2.1, 4.1, 6.1, 9.3_

  - [x] 12.2 Crear `cola_pedidos_screen.dart`
    - Listar pedidos activos ordenados por fecha (más reciente primero)
    - Mostrar por cada pedido: nombre usuario, dirección, descripción, precio, estado
    - Permitir seleccionar pedido y asignar repartidor disponible
    - _Requisitos: 2.1, 2.2, 2.3, 2.4_

  - [x] 12.3 Crear `gestion_repartidores_screen.dart`
    - Listar repartidores con: nombre, total entregas, estado actual
    - Al seleccionar repartidor, mostrar historial de entregas con fecha, nombre usuario y costo
    - Filtro de historial por rango de fechas
    - _Requisitos: 4.1, 4.2, 4.3_

  - [x] 12.4 Crear `historial_pedidos_screen.dart`
    - Listar pedidos completados con filtros por fecha, repartidor y usuario
    - Mostrar datos completos de cada registro del historial
    - _Requisitos: 9.1, 9.3, 9.4_

  - [x] 12.5 Crear `reportes_ganancias_screen.dart`
    - Tres vistas: diaria, mensual, anual
    - Vista diaria: total del día + listado por día del mes
    - Vista mensual: total del mes + listado por mes del año
    - Vista anual: total del año + comparativo con años anteriores
    - _Requisitos: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 13. Integrar notificaciones y geolocalización
  - [x] 13.1 Integrar `MockNotificacionService` con flujo de pedidos
    - Disparar notificación al asignar repartidor
    - Disparar notificación al cambiar estado del pedido
    - Disparar notificación al completar entrega
    - Simular notificaciones push cuando la app está en segundo plano
    - _Requisitos: 12.1, 12.2, 12.3, 12.4_

  - [x] 13.2 Integrar geolocalización con flujo de entrega
    - Iniciar rastreo al asignar repartidor a pedido
    - Actualizar ubicación cada 10 segundos en el mapa del usuario
    - Detener rastreo al completar entrega
    - _Requisitos: 7.1, 7.2, 7.3, 7.4_

- [x] 14. Crear documentación técnica para backend
  - Crear archivo de documentación con: modelos de datos con campos y tipos, endpoints esperados del API REST, flujos de autenticación, contratos de request/response para cada operación
  - _Requisitos: 10.3_

- [x] 15. Checkpoint final — Verificar integración completa
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia requisitos específicos para trazabilidad
- Los checkpoints aseguran validación incremental
- Los tests de propiedad validan propiedades universales de correctitud
- Los tests unitarios validan ejemplos específicos y edge cases
