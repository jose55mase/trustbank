# Documento de Requisitos — Delivery App (Domicilios)

## Introducción

Aplicación móvil desarrollada en Flutter para gestión de domicilios (entregas a domicilio). La app permite a usuarios solicitar entregas sin necesidad de registro, a repartidores gestionar sus servicios activos, y a administradores supervisar toda la operación desde un panel centralizado. El diseño sigue un tema oscuro inspirado en Nequi, con influencias de Rappi y Uber. En esta fase inicial, todos los datos son simulados (mock) sin backend real, pero la arquitectura y documentación están preparadas para una integración futura con un backend real.

## Glosario

- **App**: La aplicación móvil Flutter de domicilios
- **Usuario**: Persona que solicita una entrega a domicilio a través de la App
- **Repartidor**: Persona encargada de realizar la entrega física del producto
- **Administrador**: Persona con acceso al panel de administración para supervisar operaciones
- **Pedido**: Solicitud de entrega creada por un Usuario, que contiene dirección, datos de contacto, descripción y precio del producto
- **Pedido_Activo**: Pedido que se encuentra en proceso de entrega y es visible en la lista de pedidos activos
- **Pedido_Historial**: Registro de un pedido completado, almacenado en una tabla separada de historial
- **Código_Confirmación**: Código único generado por la App y visible solo para el Usuario solicitante, utilizado para confirmar la entrega
- **Panel_Admin**: Interfaz de administración donde el Administrador supervisa pedidos, repartidores y ganancias
- **Panel_Repartidor**: Interfaz donde el Repartidor gestiona sus entregas asignadas
- **Servicio_Mock**: Capa de datos simulados que imita el comportamiento de un backend real
- **Geolocalización**: Funcionalidad de rastreo de ubicación en tiempo real del Repartidor durante una entrega

## Requisitos

### Requisito 1: Solicitud de Pedido sin Registro

**Historia de Usuario:** Como Usuario, quiero solicitar una entrega sin necesidad de crear una cuenta o iniciar sesión, para poder usar el servicio de forma rápida y sin fricción.

#### Criterios de Aceptación

1. THE App SHALL presentar un formulario de solicitud de Pedido con los campos: dirección de entrega, nombre del Usuario, número de teléfono, descripción del pedido, precio del producto y tipo de entrega solicitada.
2. WHEN el Usuario completa todos los campos obligatorios y confirma el envío, THE App SHALL crear un Pedido_Activo y generar un Código_Confirmación único asociado a ese Pedido.
3. WHEN el Usuario envía el formulario con campos obligatorios vacíos, THE App SHALL mostrar mensajes de validación específicos indicando los campos faltantes.
4. IF el Usuario ya tiene un Pedido_Activo en curso, THEN THE App SHALL impedir la creación de un nuevo Pedido y mostrar un mensaje indicando que debe esperar a que se complete el pedido actual.
5. WHEN el Pedido es creado exitosamente, THE App SHALL mostrar el Código_Confirmación al Usuario en pantalla.

### Requisito 2: Cola de Pedidos en Panel de Administración

**Historia de Usuario:** Como Administrador, quiero ver todos los pedidos pendientes apilados en el Panel_Admin, para poder asignarlos y dar seguimiento a las entregas.

#### Criterios de Aceptación

1. THE Panel_Admin SHALL mostrar una lista de todos los Pedidos_Activos ordenados por fecha de creación (más reciente primero).
2. WHEN un nuevo Pedido_Activo es creado, THE Panel_Admin SHALL actualizar la lista para incluir el nuevo Pedido.
3. THE Panel_Admin SHALL mostrar para cada Pedido_Activo: nombre del Usuario, dirección de entrega, descripción del pedido, precio del producto y estado actual del Pedido.
4. WHEN un Administrador selecciona un Pedido_Activo, THE Panel_Admin SHALL permitir asignar un Repartidor disponible a ese Pedido.

### Requisito 3: Confirmación de Entrega con Código

**Historia de Usuario:** Como Repartidor, quiero confirmar la entrega ingresando un código que solo tiene el Usuario solicitante, para garantizar que el producto fue entregado a la persona correcta.

#### Criterios de Aceptación

1. WHEN el Repartidor llega al destino, THE Panel_Repartidor SHALL presentar un campo para ingresar el Código_Confirmación.
2. WHEN el Repartidor ingresa un Código_Confirmación válido que coincide con el del Pedido_Activo, THE App SHALL marcar el Pedido como completado.
3. IF el Repartidor ingresa un Código_Confirmación que no coincide con el del Pedido_Activo, THEN THE App SHALL mostrar un mensaje de error indicando que el código es incorrecto y permitir reintentar.
4. WHEN un Pedido es marcado como completado, THE App SHALL mover el registro del Pedido_Activo a la tabla de Pedido_Historial.
5. WHEN un Pedido es marcado como completado, THE App SHALL eliminar el Pedido de la lista de Pedidos_Activos.

### Requisito 4: Panel de Administración — Información de Repartidores

**Historia de Usuario:** Como Administrador, quiero ver información detallada de cada Repartidor, para poder evaluar su rendimiento y gestionar la operación.

#### Criterios de Aceptación

1. THE Panel_Admin SHALL mostrar para cada Repartidor: nombre completo, número total de entregas realizadas y estado actual (disponible, en entrega, inactivo).
2. WHEN el Administrador selecciona un Repartidor, THE Panel_Admin SHALL mostrar el historial de entregas del Repartidor con: fecha de entrega, nombre del Usuario que recibió el producto y costo del producto entregado.
3. THE Panel_Admin SHALL permitir filtrar el historial de entregas de un Repartidor por rango de fechas.

### Requisito 5: Autenticación Diferenciada por Tipo de Usuario

**Historia de Usuario:** Como Repartidor o Administrador, quiero iniciar sesión en un panel específico para mi rol, para acceder solo a las funcionalidades que me corresponden.

#### Criterios de Aceptación

1. THE App SHALL presentar una pantalla de inicio de sesión con opción de seleccionar el tipo de usuario: Repartidor o Administrador.
2. WHEN un Repartidor ingresa credenciales válidas, THE App SHALL redirigir al Panel_Repartidor.
3. WHEN un Administrador ingresa credenciales válidas, THE App SHALL redirigir al Panel_Admin.
4. IF un usuario ingresa credenciales inválidas, THEN THE App SHALL mostrar un mensaje de error indicando que las credenciales son incorrectas.
5. THE App SHALL mantener las sesiones de Repartidor y Administrador separadas e independientes de la interfaz del Usuario solicitante.

### Requisito 6: Reporte de Ganancias

**Historia de Usuario:** Como Administrador, quiero ver las ganancias acumuladas por día, mes y año, para poder analizar el rendimiento financiero del negocio.

#### Criterios de Aceptación

1. THE Panel_Admin SHALL mostrar un resumen de ganancias acumuladas con tres vistas: diaria, mensual y anual.
2. WHEN el Administrador selecciona la vista diaria, THE Panel_Admin SHALL mostrar las ganancias totales del día actual y un listado de ganancias por cada día del mes en curso.
3. WHEN el Administrador selecciona la vista mensual, THE Panel_Admin SHALL mostrar las ganancias totales del mes actual y un listado de ganancias por cada mes del año en curso.
4. WHEN el Administrador selecciona la vista anual, THE Panel_Admin SHALL mostrar las ganancias totales del año actual y un comparativo con años anteriores disponibles.
5. THE Panel_Admin SHALL calcular las ganancias a partir de los costos de productos registrados en los Pedidos del Pedido_Historial.

### Requisito 7: Geolocalización del Repartidor

**Historia de Usuario:** Como Usuario, quiero ver la ubicación en tiempo real del Repartidor que lleva mi pedido, para saber cuándo llegará mi entrega.

#### Criterios de Aceptación

1. WHEN un Repartidor acepta un Pedido_Activo, THE App SHALL activar el rastreo de Geolocalización del Repartidor.
2. WHILE el Repartidor tiene un Pedido_Activo asignado, THE App SHALL actualizar la ubicación del Repartidor cada 10 segundos.
3. WHILE el Pedido_Activo está en curso, THE App SHALL mostrar al Usuario solicitante un mapa con la ubicación en tiempo real del Repartidor asignado.
4. WHEN el Pedido es marcado como completado, THE App SHALL detener el rastreo de Geolocalización del Repartidor para ese Pedido.
5. IF la App no puede obtener la ubicación del Repartidor, THEN THE App SHALL mostrar al Usuario un mensaje indicando que la ubicación no está disponible temporalmente.

### Requisito 8: Privacidad y Límite de Pedidos por Usuario

**Historia de Usuario:** Como Usuario, quiero que solo yo pueda ver mi pedido y que nadie más tenga acceso a mi información, para proteger mi privacidad.

#### Criterios de Aceptación

1. THE App SHALL permitir al Usuario ver únicamente su propio Pedido_Activo y su propio Pedido_Historial.
2. THE App SHALL restringir a un máximo de 1 Pedido_Activo simultáneo por Usuario.
3. WHEN un Usuario intenta acceder a información de un Pedido que no le pertenece, THE App SHALL denegar el acceso y mostrar un mensaje de error.
4. THE App SHALL identificar al Usuario mediante su número de teléfono para asociar Pedidos a un Usuario específico.

### Requisito 9: Gestión de Historial de Pedidos

**Historia de Usuario:** Como Administrador, quiero que los pedidos completados se guarden en un historial separado, para mantener limpia la lista de pedidos activos y conservar un registro completo.

#### Criterios de Aceptación

1. WHEN un Pedido es marcado como completado, THE App SHALL crear un registro en la tabla de Pedido_Historial con: datos del Pedido original, nombre del Repartidor, fecha y hora de completación, y nombre de quien recibió la entrega.
2. WHEN un Pedido es movido al Pedido_Historial, THE App SHALL eliminar el registro correspondiente de la tabla de Pedidos_Activos.
3. THE Panel_Admin SHALL permitir consultar el Pedido_Historial completo con filtros por fecha, Repartidor y Usuario.
4. THE App SHALL conservar los registros del Pedido_Historial de forma indefinida.

### Requisito 10: Capa de Datos Mock y Documentación para Backend

**Historia de Usuario:** Como desarrollador backend, quiero tener documentación clara de los modelos de datos, endpoints esperados y contratos de API, para poder implementar el backend real y conectarlo a la App.

#### Criterios de Aceptación

1. THE App SHALL utilizar un Servicio_Mock que simule todas las operaciones de datos (crear pedido, listar pedidos, confirmar entrega, consultar historial, autenticación, geolocalización).
2. THE Servicio_Mock SHALL implementar las mismas interfaces que el backend real utilizará, facilitando el reemplazo futuro.
3. THE App SHALL incluir documentación técnica que describa: modelos de datos con sus campos y tipos, endpoints esperados del API REST, flujos de autenticación, y contratos de request/response para cada operación.
4. THE Servicio_Mock SHALL generar datos de prueba realistas para al menos 5 Usuarios, 3 Repartidores, 1 Administrador y 10 Pedidos en Pedido_Historial.

### Requisito 11: Diseño Visual — Tema Oscuro

**Historia de Usuario:** Como Usuario, quiero una interfaz con tema oscuro moderna e intuitiva, para tener una experiencia visual agradable y consistente con apps de referencia como Nequi, Rappi y Uber.

#### Criterios de Aceptación

1. THE App SHALL utilizar un tema oscuro como tema principal con una paleta de colores inspirada en Nequi (tonos morados/magenta sobre fondos oscuros).
2. THE App SHALL mantener un contraste mínimo de 4.5:1 entre texto y fondo para cumplir con estándares de accesibilidad.
3. THE App SHALL utilizar componentes de navegación y diseño de interfaz inspirados en Rappi y Uber (navegación por tabs, tarjetas de pedido, mapas integrados).
4. THE App SHALL aplicar el tema oscuro de forma consistente en todas las pantallas: formulario de pedido, panel de Repartidor, Panel_Admin y pantalla de seguimiento.

### Requisito 12: Notificaciones de Estado del Pedido

**Historia de Usuario:** Como Usuario, quiero recibir notificaciones sobre el estado de mi pedido, para estar informado del progreso de mi entrega sin tener que revisar la app constantemente.

#### Criterios de Aceptación

1. WHEN un Repartidor es asignado a un Pedido_Activo, THE App SHALL notificar al Usuario con el nombre del Repartidor asignado.
2. WHEN el Repartidor actualiza el estado del Pedido (recogido, en camino), THE App SHALL notificar al Usuario del cambio de estado.
3. WHEN el Pedido es marcado como completado, THE App SHALL notificar al Usuario que su entrega ha sido realizada.
4. WHILE la App está en segundo plano, THE App SHALL mostrar las notificaciones como notificaciones push del sistema operativo (simuladas en modo mock).

### Requisito 13: Panel del Repartidor

**Historia de Usuario:** Como Repartidor, quiero tener un panel donde pueda ver mis entregas asignadas y gestionar mis servicios activos, para organizar mi trabajo de forma eficiente.

#### Criterios de Aceptación

1. THE Panel_Repartidor SHALL mostrar la lista de Pedidos_Activos asignados al Repartidor con: dirección de entrega, nombre del Usuario, descripción del pedido y precio del producto.
2. WHEN el Repartidor selecciona un Pedido_Activo, THE Panel_Repartidor SHALL mostrar los detalles completos del Pedido y opciones para actualizar el estado (recogido, en camino, en destino).
3. THE Panel_Repartidor SHALL mostrar un resumen del día actual del Repartidor: número de entregas completadas y ganancias del día.
4. WHEN el Repartidor no tiene Pedidos_Activos asignados, THE Panel_Repartidor SHALL mostrar un mensaje indicando que no hay entregas pendientes.
