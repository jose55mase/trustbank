# Documentación Técnica del API REST — Delivery App

## Índice

1. [Modelos de Datos](#modelos-de-datos)
2. [Autenticación](#autenticación)
3. [Endpoints del API REST](#endpoints-del-api-rest)
4. [Formato de Errores](#formato-de-errores)

---

## Modelos de Datos

### Pedido (Activo)

Representa un pedido en curso dentro del sistema.

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `id` | `String` | Sí | Identificador único del pedido |
| `direccionEntrega` | `String` | Sí | Dirección de destino de la entrega |
| `nombreUsuario` | `String` | Sí | Nombre del usuario que solicita el pedido |
| `telefonoUsuario` | `String` | Sí | Número de teléfono del usuario (identificador principal) |
| `descripcion` | `String` | Sí | Descripción del producto o pedido |
| `precioProducto` | `double` | Sí | Precio del producto a entregar |
| `tipoEntrega` | `TipoEntrega` | Sí | Tipo de entrega: `estandar` o `express` |
| `codigoConfirmacion` | `String` | Sí | Código único de 6 caracteres alfanuméricos para confirmar la entrega |
| `estado` | `EstadoPedido` | Sí | Estado actual del pedido |
| `repartidorId` | `String?` | No | ID del repartidor asignado (null si no se ha asignado) |
| `fechaCreacion` | `DateTime` | Sí | Fecha y hora de creación del pedido |

#### Enum: EstadoPedido

| Valor | Descripción |
|---|---|
| `pendiente` | Pedido creado, esperando asignación de repartidor |
| `asignado` | Repartidor asignado al pedido |
| `recogido` | Repartidor recogió el producto |
| `enCamino` | Repartidor en camino al destino |
| `enDestino` | Repartidor llegó al destino |
| `completado` | Entrega confirmada con código |

#### Enum: TipoEntrega

| Valor | Descripción |
|---|---|
| `estandar` | Entrega estándar |
| `express` | Entrega express (prioridad) |

### PedidoHistorial

Registro de un pedido completado, almacenado en la tabla de historial.

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `id` | `String` | Sí | Identificador único del registro de historial |
| `pedidoOriginalId` | `String` | Sí | ID del pedido activo original |
| `direccionEntrega` | `String` | Sí | Dirección de destino de la entrega |
| `nombreUsuario` | `String` | Sí | Nombre del usuario que solicitó el pedido |
| `telefonoUsuario` | `String` | Sí | Teléfono del usuario solicitante |
| `descripcion` | `String` | Sí | Descripción del producto o pedido |
| `precioProducto` | `double` | Sí | Precio del producto entregado |
| `tipoEntrega` | `TipoEntrega` | Sí | Tipo de entrega utilizado |
| `nombreRepartidor` | `String` | Sí | Nombre completo del repartidor que realizó la entrega |
| `repartidorId` | `String` | Sí | ID del repartidor que realizó la entrega |
| `fechaCreacion` | `DateTime` | Sí | Fecha y hora de creación original del pedido |
| `fechaCompletacion` | `DateTime` | Sí | Fecha y hora en que se completó la entrega |
| `nombreReceptor` | `String` | Sí | Nombre de la persona que recibió la entrega |

### CrearPedidoRequest

Datos requeridos para crear un nuevo pedido.

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `direccionEntrega` | `String` | Sí | Dirección de destino de la entrega |
| `nombreUsuario` | `String` | Sí | Nombre del usuario solicitante |
| `telefonoUsuario` | `String` | Sí | Teléfono del usuario (identificador) |
| `descripcion` | `String` | Sí | Descripción del producto o pedido |
| `precioProducto` | `double` | Sí | Precio del producto |
| `tipoEntrega` | `TipoEntrega` | Sí | Tipo de entrega: `estandar` o `express` |

### Repartidor

Representa un repartidor del sistema.

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `id` | `String` | Sí | Identificador único del repartidor |
| `nombreCompleto` | `String` | Sí | Nombre completo del repartidor |
| `totalEntregas` | `int` | Sí | Número total de entregas realizadas |
| `estado` | `EstadoRepartidor` | Sí | Estado actual del repartidor |
| `usuario` | `String` | Sí | Nombre de usuario para login |
| `password` | `String` | Sí | Contraseña (hash en backend real) |

#### Enum: EstadoRepartidor

| Valor | Descripción |
|---|---|
| `disponible` | Repartidor disponible para recibir pedidos |
| `enEntrega` | Repartidor realizando una entrega |
| `inactivo` | Repartidor inactivo / fuera de servicio |

### Administrador

Representa un administrador del sistema.

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `id` | `String` | Sí | Identificador único del administrador |
| `nombre` | `String` | Sí | Nombre del administrador |
| `usuario` | `String` | Sí | Nombre de usuario para login |
| `password` | `String` | Sí | Contraseña (hash en backend real) |

### Ubicacion

Representa una ubicación geográfica con marca de tiempo.

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `latitud` | `double` | Sí | Latitud de la ubicación |
| `longitud` | `double` | Sí | Longitud de la ubicación |
| `timestamp` | `DateTime` | Sí | Marca de tiempo de la lectura de ubicación |

### Modelos de Autenticación

#### AuthResult

Resultado de un intento de autenticación.

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `exitoso` | `bool` | Sí | Indica si la autenticación fue exitosa |
| `mensaje` | `String?` | No | Mensaje descriptivo (error o éxito) |
| `userId` | `String?` | No | ID del usuario autenticado (solo si exitoso) |
| `tipo` | `TipoUsuario?` | No | Tipo de usuario autenticado (solo si exitoso) |

#### SesionActiva

Representa una sesión activa de un usuario autenticado.

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `userId` | `String` | Sí | ID del usuario con sesión activa |
| `tipo` | `TipoUsuario` | Sí | Tipo de usuario: `repartidor` o `administrador` |

#### Enum: TipoUsuario

| Valor | Descripción |
|---|---|
| `repartidor` | Usuario con rol de repartidor |
| `administrador` | Usuario con rol de administrador |

### Modelos de Reportes

#### ReporteGanancias

Reporte de ganancias con total y desglose por período.

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `totalActual` | `double` | Sí | Total de ganancias del período actual (día/mes/año) |
| `desglose` | `List<GananciaPeriodo>` | Sí | Listado desglosado por sub-período |

#### GananciaPeriodo

Ganancias de un período específico.

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `etiqueta` | `String` | Sí | Etiqueta del período (ej: "2024-01-15", "Enero 2024", "2024") |
| `total` | `double` | Sí | Total de ganancias del período |
| `cantidadPedidos` | `int` | Sí | Cantidad de pedidos completados en el período |

#### ResumenDiario

Resumen diario de actividad de un repartidor.

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `entregasCompletadas` | `int` | Sí | Número de entregas completadas en el día |
| `gananciasDia` | `double` | Sí | Total de ganancias del día |


---

## Autenticación

### Flujo de Autenticación

El sistema utiliza autenticación basada en sesiones con diferenciación por rol. Los usuarios solicitantes (que crean pedidos) no requieren autenticación — se identifican únicamente por su número de teléfono. Solo los repartidores y administradores necesitan iniciar sesión.

```
┌─────────────┐     POST /api/auth/login      ┌─────────────┐
│   Cliente    │ ──────────────────────────────>│   Servidor  │
│  (App)       │   { usuario, password, tipo }  │             │
│              │<──────────────────────────────  │             │
│              │   { exitoso, userId, tipo,     │             │
│              │     token/sesion }              │             │
└─────────────┘                                 └─────────────┘
```

#### 1. Login

- El usuario selecciona su tipo (`repartidor` o `administrador`) en la pantalla de login.
- Ingresa sus credenciales (usuario y contraseña).
- El servidor valida las credenciales contra la base de datos correspondiente según el tipo.
- Si las credenciales son válidas, se crea una sesión y se retorna el resultado con `exitoso: true`, el `userId` y el `tipo`.
- Si las credenciales son inválidas, se retorna `exitoso: false` con un mensaje de error genérico (sin revelar qué campo falló).
- La app redirige al panel correspondiente según el tipo: `Panel_Repartidor` o `Panel_Admin`.

#### 2. Sesión Activa

- Tras un login exitoso, el servidor mantiene una sesión activa asociada al usuario.
- La app puede consultar la sesión activa para determinar si el usuario ya está autenticado y su rol.
- Las sesiones de repartidor y administrador son independientes entre sí y de la interfaz del usuario solicitante.

#### 3. Logout

- El usuario puede cerrar sesión desde su panel.
- El servidor invalida la sesión activa.
- La app redirige a la pantalla de login.

#### 4. Usuarios Solicitantes (sin autenticación)

- Los usuarios que crean pedidos no necesitan autenticarse.
- Se identifican por su número de teléfono, que se envía como parte del request de creación de pedido.
- El teléfono se usa para asociar pedidos activos e historial a un usuario específico.

---

## Endpoints del API REST

### Base URL

```
https://api.delivery-app.com/api
```

Todos los endpoints usan JSON como formato de request y response. Los headers requeridos son:

```
Content-Type: application/json
Authorization: Bearer {token}  (solo para endpoints autenticados)
```

---

### Autenticación

#### POST /api/auth/login

Autentica un repartidor o administrador.

**Autenticación requerida:** No

**Request Body:**

```json
{
  "usuario": "string",
  "password": "string",
  "tipo": "repartidor | administrador"
}
```

**Response 200 — Login exitoso:**

```json
{
  "exitoso": true,
  "mensaje": "Login exitoso",
  "userId": "rep-001",
  "tipo": "repartidor",
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response 401 — Credenciales inválidas:**

```json
{
  "exitoso": false,
  "mensaje": "Credenciales incorrectas",
  "userId": null,
  "tipo": null
}
```

---

#### POST /api/auth/logout

Cierra la sesión activa del usuario autenticado.

**Autenticación requerida:** Sí

**Request Body:** Vacío

**Response 200:**

```json
{
  "mensaje": "Sesión cerrada exitosamente"
}
```

---

#### GET /api/auth/sesion

Obtiene la sesión activa actual (si existe).

**Autenticación requerida:** Sí

**Response 200 — Sesión activa:**

```json
{
  "userId": "rep-001",
  "tipo": "repartidor"
}
```

**Response 401 — Sin sesión activa:**

```json
{
  "error": "No hay sesión activa",
  "codigo": "SIN_SESION"
}
```

---

### Pedidos

#### POST /api/pedidos

Crea un nuevo pedido activo. Genera automáticamente un código de confirmación único de 6 caracteres.

**Autenticación requerida:** No (el usuario se identifica por teléfono)

**Validaciones:**
- Todos los campos son obligatorios y no pueden estar vacíos ni compuestos solo de espacios.
- El usuario (identificado por `telefonoUsuario`) no puede tener otro pedido activo en curso.
- `precioProducto` debe ser un número positivo.

**Request Body:**

```json
{
  "direccionEntrega": "Calle 123 #45-67, Bogotá",
  "nombreUsuario": "Juan Pérez",
  "telefonoUsuario": "3001234567",
  "descripcion": "Hamburguesa doble con papas",
  "precioProducto": 25000.0,
  "tipoEntrega": "estandar"
}
```

**Response 201 — Pedido creado:**

```json
{
  "id": "ped-abc123",
  "direccionEntrega": "Calle 123 #45-67, Bogotá",
  "nombreUsuario": "Juan Pérez",
  "telefonoUsuario": "3001234567",
  "descripcion": "Hamburguesa doble con papas",
  "precioProducto": 25000.0,
  "tipoEntrega": "estandar",
  "codigoConfirmacion": "A1B2C3",
  "estado": "pendiente",
  "repartidorId": null,
  "fechaCreacion": "2024-01-15T14:30:00Z"
}
```

**Response 400 — Validación fallida:**

```json
{
  "error": "Campos obligatorios faltantes",
  "codigo": "VALIDACION_FALLIDA",
  "campos": ["direccionEntrega", "descripcion"]
}
```

**Response 409 — Pedido duplicado:**

```json
{
  "error": "Ya tienes un pedido en curso",
  "codigo": "PEDIDO_DUPLICADO"
}
```

---

#### GET /api/pedidos/activos

Obtiene todos los pedidos activos ordenados por fecha de creación (más reciente primero).

**Autenticación requerida:** Sí (solo administrador)

**Response 200:**

```json
[
  {
    "id": "ped-abc123",
    "direccionEntrega": "Calle 123 #45-67, Bogotá",
    "nombreUsuario": "Juan Pérez",
    "telefonoUsuario": "3001234567",
    "descripcion": "Hamburguesa doble con papas",
    "precioProducto": 25000.0,
    "tipoEntrega": "estandar",
    "codigoConfirmacion": "A1B2C3",
    "estado": "pendiente",
    "repartidorId": null,
    "fechaCreacion": "2024-01-15T14:30:00Z"
  }
]
```

---

#### GET /api/pedidos/activo?telefono={telefono}

Obtiene el pedido activo de un usuario específico por su número de teléfono.

**Autenticación requerida:** No (el usuario se identifica por teléfono)

**Parámetros de Query:**

| Parámetro | Tipo | Requerido | Descripción |
|---|---|---|---|
| `telefono` | `String` | Sí | Número de teléfono del usuario |

**Response 200 — Pedido encontrado:**

```json
{
  "id": "ped-abc123",
  "direccionEntrega": "Calle 123 #45-67, Bogotá",
  "nombreUsuario": "Juan Pérez",
  "telefonoUsuario": "3001234567",
  "descripcion": "Hamburguesa doble con papas",
  "precioProducto": 25000.0,
  "tipoEntrega": "estandar",
  "codigoConfirmacion": "A1B2C3",
  "estado": "asignado",
  "repartidorId": "rep-001",
  "fechaCreacion": "2024-01-15T14:30:00Z"
}
```

**Response 404 — Sin pedido activo:**

```json
{
  "error": "No se encontró pedido activo para este usuario",
  "codigo": "PEDIDO_NO_ENCONTRADO"
}
```

---

#### PUT /api/pedidos/{id}/asignar

Asigna un repartidor disponible a un pedido activo.

**Autenticación requerida:** Sí (solo administrador)

**Parámetros de Ruta:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `id` | `String` | ID del pedido activo |

**Request Body:**

```json
{
  "repartidorId": "rep-001"
}
```

**Response 200 — Repartidor asignado:**

```json
{
  "id": "ped-abc123",
  "direccionEntrega": "Calle 123 #45-67, Bogotá",
  "nombreUsuario": "Juan Pérez",
  "telefonoUsuario": "3001234567",
  "descripcion": "Hamburguesa doble con papas",
  "precioProducto": 25000.0,
  "tipoEntrega": "estandar",
  "codigoConfirmacion": "A1B2C3",
  "estado": "asignado",
  "repartidorId": "rep-001",
  "fechaCreacion": "2024-01-15T14:30:00Z"
}
```

**Response 404 — Pedido no encontrado:**

```json
{
  "error": "Pedido no encontrado",
  "codigo": "PEDIDO_NO_ENCONTRADO"
}
```

---

#### PUT /api/pedidos/{id}/estado

Actualiza el estado de un pedido activo. Solo permite transiciones válidas: `recogido`, `enCamino`, `enDestino`.

**Autenticación requerida:** Sí (solo repartidor asignado al pedido)

**Parámetros de Ruta:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `id` | `String` | ID del pedido activo |

**Request Body:**

```json
{
  "estado": "recogido"
}
```

**Valores válidos para `estado`:** `recogido`, `enCamino`, `enDestino`

**Response 200 — Estado actualizado:**

```json
{
  "id": "ped-abc123",
  "direccionEntrega": "Calle 123 #45-67, Bogotá",
  "nombreUsuario": "Juan Pérez",
  "telefonoUsuario": "3001234567",
  "descripcion": "Hamburguesa doble con papas",
  "precioProducto": 25000.0,
  "tipoEntrega": "estandar",
  "codigoConfirmacion": "A1B2C3",
  "estado": "recogido",
  "repartidorId": "rep-001",
  "fechaCreacion": "2024-01-15T14:30:00Z"
}
```

---

#### POST /api/pedidos/{id}/confirmar

Confirma la entrega con el código de confirmación. Si el código es correcto, el pedido se mueve de activos a historial.

**Autenticación requerida:** Sí (solo repartidor asignado al pedido)

**Parámetros de Ruta:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `id` | `String` | ID del pedido activo |

**Request Body:**

```json
{
  "codigoConfirmacion": "A1B2C3",
  "nombreReceptor": "Juan Pérez"
}
```

**Response 200 — Entrega confirmada:**

```json
{
  "confirmado": true,
  "mensaje": "Entrega confirmada exitosamente"
}
```

**Response 400 — Código incorrecto:**

```json
{
  "confirmado": false,
  "mensaje": "Código de confirmación incorrecto",
  "codigo": "CODIGO_INCORRECTO"
}
```

---

### Historial

#### GET /api/historial

Obtiene el historial de pedidos completados con filtros opcionales.

**Autenticación requerida:** Sí (administrador para historial completo)

**Parámetros de Query:**

| Parámetro | Tipo | Requerido | Descripción |
|---|---|---|---|
| `fechaInicio` | `DateTime` (ISO 8601) | No | Fecha de inicio del rango de filtro |
| `fechaFin` | `DateTime` (ISO 8601) | No | Fecha de fin del rango de filtro |
| `repartidorId` | `String` | No | Filtrar por ID de repartidor |
| `telefonoUsuario` | `String` | No | Filtrar por teléfono del usuario |

**Response 200:**

```json
[
  {
    "id": "hist-001",
    "pedidoOriginalId": "ped-abc123",
    "direccionEntrega": "Calle 123 #45-67, Bogotá",
    "nombreUsuario": "Juan Pérez",
    "telefonoUsuario": "3001234567",
    "descripcion": "Hamburguesa doble con papas",
    "precioProducto": 25000.0,
    "tipoEntrega": "estandar",
    "nombreRepartidor": "Carlos Gómez",
    "repartidorId": "rep-001",
    "fechaCreacion": "2024-01-15T14:30:00Z",
    "fechaCompletacion": "2024-01-15T15:10:00Z",
    "nombreReceptor": "Juan Pérez"
  }
]
```

---

#### GET /api/historial/usuario?telefono={telefono}

Obtiene el historial de pedidos completados de un usuario específico.

**Autenticación requerida:** No (el usuario se identifica por teléfono)

**Parámetros de Query:**

| Parámetro | Tipo | Requerido | Descripción |
|---|---|---|---|
| `telefono` | `String` | Sí | Número de teléfono del usuario |

**Response 200:**

```json
[
  {
    "id": "hist-001",
    "pedidoOriginalId": "ped-abc123",
    "direccionEntrega": "Calle 123 #45-67, Bogotá",
    "nombreUsuario": "Juan Pérez",
    "telefonoUsuario": "3001234567",
    "descripcion": "Hamburguesa doble con papas",
    "precioProducto": 25000.0,
    "tipoEntrega": "estandar",
    "nombreRepartidor": "Carlos Gómez",
    "repartidorId": "rep-001",
    "fechaCreacion": "2024-01-15T14:30:00Z",
    "fechaCompletacion": "2024-01-15T15:10:00Z",
    "nombreReceptor": "Juan Pérez"
  }
]
```


---

### Repartidores

#### GET /api/repartidores

Obtiene la lista de todos los repartidores.

**Autenticación requerida:** Sí (solo administrador)

**Response 200:**

```json
[
  {
    "id": "rep-001",
    "nombreCompleto": "Carlos Gómez",
    "totalEntregas": 45,
    "estado": "disponible",
    "usuario": "cgomez"
  }
]
```

> **Nota:** El campo `password` nunca se incluye en las respuestas del API.

---

#### GET /api/repartidores/disponibles

Obtiene la lista de repartidores con estado `disponible`.

**Autenticación requerida:** Sí (solo administrador)

**Response 200:**

```json
[
  {
    "id": "rep-001",
    "nombreCompleto": "Carlos Gómez",
    "totalEntregas": 45,
    "estado": "disponible",
    "usuario": "cgomez"
  }
]
```

---

#### GET /api/repartidores/{repartidorId}/pedidos

Obtiene los pedidos activos asignados a un repartidor.

**Autenticación requerida:** Sí (repartidor autenticado o administrador)

**Parámetros de Ruta:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `repartidorId` | `String` | ID del repartidor |

**Response 200:**

```json
[
  {
    "id": "ped-abc123",
    "direccionEntrega": "Calle 123 #45-67, Bogotá",
    "nombreUsuario": "Juan Pérez",
    "telefonoUsuario": "3001234567",
    "descripcion": "Hamburguesa doble con papas",
    "precioProducto": 25000.0,
    "tipoEntrega": "estandar",
    "codigoConfirmacion": "A1B2C3",
    "estado": "asignado",
    "repartidorId": "rep-001",
    "fechaCreacion": "2024-01-15T14:30:00Z"
  }
]
```

---

#### GET /api/repartidores/{repartidorId}/historial

Obtiene el historial de entregas de un repartidor con filtros opcionales de fecha.

**Autenticación requerida:** Sí (repartidor autenticado o administrador)

**Parámetros de Ruta:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `repartidorId` | `String` | ID del repartidor |

**Parámetros de Query:**

| Parámetro | Tipo | Requerido | Descripción |
|---|---|---|---|
| `fechaInicio` | `DateTime` (ISO 8601) | No | Fecha de inicio del rango |
| `fechaFin` | `DateTime` (ISO 8601) | No | Fecha de fin del rango |

**Response 200:**

```json
[
  {
    "id": "hist-001",
    "pedidoOriginalId": "ped-abc123",
    "direccionEntrega": "Calle 123 #45-67, Bogotá",
    "nombreUsuario": "Juan Pérez",
    "telefonoUsuario": "3001234567",
    "descripcion": "Hamburguesa doble con papas",
    "precioProducto": 25000.0,
    "tipoEntrega": "estandar",
    "nombreRepartidor": "Carlos Gómez",
    "repartidorId": "rep-001",
    "fechaCreacion": "2024-01-15T14:30:00Z",
    "fechaCompletacion": "2024-01-15T15:10:00Z",
    "nombreReceptor": "Juan Pérez"
  }
]
```

---

#### GET /api/repartidores/{repartidorId}/resumen-diario

Obtiene el resumen diario de un repartidor: entregas completadas y ganancias del día.

**Autenticación requerida:** Sí (repartidor autenticado)

**Parámetros de Ruta:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `repartidorId` | `String` | ID del repartidor |

**Response 200:**

```json
{
  "entregasCompletadas": 5,
  "gananciasDia": 125000.0
}
```

---

### Reportes de Ganancias

#### GET /api/reportes/ganancias/diario

Obtiene las ganancias del día actual y un listado de ganancias por cada día del mes en curso.

**Autenticación requerida:** Sí (solo administrador)

**Response 200:**

```json
{
  "totalActual": 150000.0,
  "desglose": [
    {
      "etiqueta": "2024-01-15",
      "total": 150000.0,
      "cantidadPedidos": 6
    },
    {
      "etiqueta": "2024-01-14",
      "total": 120000.0,
      "cantidadPedidos": 5
    }
  ]
}
```

---

#### GET /api/reportes/ganancias/mensual

Obtiene las ganancias del mes actual y un listado de ganancias por cada mes del año en curso.

**Autenticación requerida:** Sí (solo administrador)

**Response 200:**

```json
{
  "totalActual": 3500000.0,
  "desglose": [
    {
      "etiqueta": "Enero 2024",
      "total": 3500000.0,
      "cantidadPedidos": 140
    },
    {
      "etiqueta": "Diciembre 2023",
      "total": 4200000.0,
      "cantidadPedidos": 168
    }
  ]
}
```

---

#### GET /api/reportes/ganancias/anual

Obtiene las ganancias del año actual y un comparativo con años anteriores.

**Autenticación requerida:** Sí (solo administrador)

**Response 200:**

```json
{
  "totalActual": 42000000.0,
  "desglose": [
    {
      "etiqueta": "2024",
      "total": 42000000.0,
      "cantidadPedidos": 1680
    },
    {
      "etiqueta": "2023",
      "total": 38000000.0,
      "cantidadPedidos": 1520
    }
  ]
}
```

---

### Geolocalización

#### POST /api/geolocalizacion/{repartidorId}/iniciar

Inicia el rastreo de ubicación de un repartidor para un pedido específico.

**Autenticación requerida:** Sí (sistema interno / repartidor)

**Parámetros de Ruta:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `repartidorId` | `String` | ID del repartidor |

**Request Body:**

```json
{
  "pedidoId": "ped-abc123"
}
```

**Response 200:**

```json
{
  "mensaje": "Rastreo iniciado",
  "repartidorId": "rep-001",
  "pedidoId": "ped-abc123"
}
```

---

#### POST /api/geolocalizacion/{repartidorId}/detener

Detiene el rastreo de ubicación de un repartidor.

**Autenticación requerida:** Sí (sistema interno / repartidor)

**Parámetros de Ruta:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `repartidorId` | `String` | ID del repartidor |

**Request Body:**

```json
{
  "pedidoId": "ped-abc123"
}
```

**Response 200:**

```json
{
  "mensaje": "Rastreo detenido",
  "repartidorId": "rep-001",
  "pedidoId": "ped-abc123"
}
```

---

#### GET /api/geolocalizacion/{repartidorId}/ubicacion

Obtiene la ubicación actual del repartidor.

**Autenticación requerida:** No (accesible para el usuario que sigue su pedido)

**Parámetros de Ruta:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `repartidorId` | `String` | ID del repartidor |

**Response 200 — Ubicación disponible:**

```json
{
  "latitud": 4.7110,
  "longitud": -74.0721,
  "timestamp": "2024-01-15T14:35:00Z"
}
```

**Response 404 — Ubicación no disponible:**

```json
{
  "error": "Ubicación no disponible temporalmente",
  "codigo": "UBICACION_NO_DISPONIBLE"
}
```

---

#### WebSocket: /api/geolocalizacion/{repartidorId}/stream

Stream de actualizaciones de ubicación en tiempo real (cada 10 segundos).

**Protocolo:** WebSocket

**Conexión:** `wss://api.delivery-app.com/api/geolocalizacion/{repartidorId}/stream`

**Mensaje recibido (cada 10 segundos):**

```json
{
  "latitud": 4.7110,
  "longitud": -74.0721,
  "timestamp": "2024-01-15T14:35:10Z"
}
```

---

### Notificaciones

#### POST /api/notificaciones/repartidor-asignado

Notifica al usuario que un repartidor fue asignado a su pedido.

**Autenticación requerida:** Sí (sistema interno)

**Request Body:**

```json
{
  "telefono": "3001234567",
  "nombreRepartidor": "Carlos Gómez"
}
```

**Response 200:**

```json
{
  "mensaje": "Notificación enviada"
}
```

---

#### POST /api/notificaciones/cambio-estado

Notifica al usuario un cambio de estado en su pedido.

**Autenticación requerida:** Sí (sistema interno)

**Request Body:**

```json
{
  "telefono": "3001234567",
  "nuevoEstado": "recogido"
}
```

**Response 200:**

```json
{
  "mensaje": "Notificación enviada"
}
```

---

#### POST /api/notificaciones/entrega-completada

Notifica al usuario que su entrega fue completada.

**Autenticación requerida:** Sí (sistema interno)

**Request Body:**

```json
{
  "telefono": "3001234567"
}
```

**Response 200:**

```json
{
  "mensaje": "Notificación enviada"
}
```

---

## Formato de Errores

Todas las respuestas de error siguen un formato consistente:

```json
{
  "error": "Descripción legible del error",
  "codigo": "CODIGO_ERROR_CONSTANTE",
  "campos": ["campo1", "campo2"]
}
```

| Campo | Tipo | Descripción |
|---|---|---|
| `error` | `String` | Mensaje descriptivo del error en español |
| `codigo` | `String` | Código constante para manejo programático |
| `campos` | `List<String>?` | Lista de campos con error (solo en errores de validación) |

### Códigos de Error

| Código | HTTP Status | Descripción |
|---|---|---|
| `VALIDACION_FALLIDA` | 400 | Campos obligatorios faltantes o inválidos |
| `CODIGO_INCORRECTO` | 400 | Código de confirmación no coincide |
| `CREDENCIALES_INVALIDAS` | 401 | Usuario o contraseña incorrectos |
| `SIN_SESION` | 401 | No hay sesión activa |
| `ACCESO_DENEGADO` | 403 | El usuario no tiene permisos para esta operación |
| `PEDIDO_NO_ENCONTRADO` | 404 | Pedido no existe o no está activo |
| `REPARTIDOR_NO_ENCONTRADO` | 404 | Repartidor no existe |
| `UBICACION_NO_DISPONIBLE` | 404 | No se pudo obtener la ubicación del repartidor |
| `PEDIDO_DUPLICADO` | 409 | El usuario ya tiene un pedido activo en curso |
| `ERROR_INTERNO` | 500 | Error interno del servidor |

---

## Resumen de Endpoints

| Método | Endpoint | Descripción | Auth |
|---|---|---|---|
| `POST` | `/api/auth/login` | Login de repartidor o administrador | No |
| `POST` | `/api/auth/logout` | Cerrar sesión | Sí |
| `GET` | `/api/auth/sesion` | Obtener sesión activa | Sí |
| `POST` | `/api/pedidos` | Crear nuevo pedido | No |
| `GET` | `/api/pedidos/activos` | Listar pedidos activos | Admin |
| `GET` | `/api/pedidos/activo?telefono={tel}` | Pedido activo de un usuario | No |
| `PUT` | `/api/pedidos/{id}/asignar` | Asignar repartidor a pedido | Admin |
| `PUT` | `/api/pedidos/{id}/estado` | Actualizar estado del pedido | Repartidor |
| `POST` | `/api/pedidos/{id}/confirmar` | Confirmar entrega con código | Repartidor |
| `GET` | `/api/historial` | Historial con filtros | Admin |
| `GET` | `/api/historial/usuario?telefono={tel}` | Historial de un usuario | No |
| `GET` | `/api/repartidores` | Listar todos los repartidores | Admin |
| `GET` | `/api/repartidores/disponibles` | Listar repartidores disponibles | Admin |
| `GET` | `/api/repartidores/{id}/pedidos` | Pedidos asignados a repartidor | Repartidor/Admin |
| `GET` | `/api/repartidores/{id}/historial` | Historial de entregas del repartidor | Repartidor/Admin |
| `GET` | `/api/repartidores/{id}/resumen-diario` | Resumen diario del repartidor | Repartidor |
| `GET` | `/api/reportes/ganancias/diario` | Reporte de ganancias diario | Admin |
| `GET` | `/api/reportes/ganancias/mensual` | Reporte de ganancias mensual | Admin |
| `GET` | `/api/reportes/ganancias/anual` | Reporte de ganancias anual | Admin |
| `POST` | `/api/geolocalizacion/{id}/iniciar` | Iniciar rastreo de ubicación | Sistema |
| `POST` | `/api/geolocalizacion/{id}/detener` | Detener rastreo de ubicación | Sistema |
| `GET` | `/api/geolocalizacion/{id}/ubicacion` | Ubicación actual del repartidor | No |
| `WS` | `/api/geolocalizacion/{id}/stream` | Stream de ubicación en tiempo real | No |
| `POST` | `/api/notificaciones/repartidor-asignado` | Notificar repartidor asignado | Sistema |
| `POST` | `/api/notificaciones/cambio-estado` | Notificar cambio de estado | Sistema |
| `POST` | `/api/notificaciones/entrega-completada` | Notificar entrega completada | Sistema |
