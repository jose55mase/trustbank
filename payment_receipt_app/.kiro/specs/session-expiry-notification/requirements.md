# Documento de Requisitos

## Introducción

Esta funcionalidad implementa la detección de expiración del token OAuth2 en la aplicación Flutter y la notificación al usuario mediante un diálogo modal. Cuando el backend responde con un error de token inválido o expirado (HTTP 401), la aplicación debe interceptar la respuesta, mostrar un diálogo informando al usuario que su sesión ha expirado, y redirigirlo a la pantalla de inicio de sesión tras su confirmación.

## Glosario

- **App_Flutter**: La aplicación móvil Flutter (payment_receipt_app) que consume la API del backend
- **ApiService**: El servicio centralizado que realiza todas las llamadas HTTP al backend
- **Token_OAuth2**: El token de acceso Bearer almacenado en SharedPreferences usado para autenticar las peticiones al backend
- **Diálogo_Sesión_Expirada**: Ventana modal que informa al usuario que su sesión ha expirado
- **Interceptor_HTTP**: Componente que intercepta todas las respuestas HTTP para detectar errores de autenticación
- **Pantalla_Login**: La pantalla de inicio de sesión de la aplicación
- **SharedPreferences**: Almacenamiento local donde se persiste el token y datos del usuario

## Requisitos

### Requisito 1: Detección de Token Expirado

**Historia de Usuario:** Como usuario de la aplicación, quiero que la app detecte automáticamente cuando mi token de sesión ha expirado, para que no me quede en un estado inconsistente sin poder realizar operaciones.

#### Criterios de Aceptación

1. WHEN el backend responde con código HTTP 401 a una petición autenticada, THE Interceptor_HTTP SHALL identificar la respuesta como una sesión expirada
2. WHEN el backend responde con un error que contiene "invalid_token" o "token expired" en el cuerpo, THE Interceptor_HTTP SHALL identificar la respuesta como una sesión expirada
3. THE Interceptor_HTTP SHALL interceptar todas las respuestas HTTP de peticiones realizadas por el ApiService

### Requisito 2: Notificación al Usuario

**Historia de Usuario:** Como usuario de la aplicación, quiero ver un mensaje claro cuando mi sesión expire, para entender por qué no puedo continuar operando.

#### Criterios de Aceptación

1. WHEN el Interceptor_HTTP detecta una sesión expirada, THE App_Flutter SHALL mostrar el Diálogo_Sesión_Expirada al usuario
2. THE Diálogo_Sesión_Expirada SHALL mostrar un mensaje indicando que la sesión ha expirado y que debe iniciar sesión nuevamente
3. THE Diálogo_Sesión_Expirada SHALL contener un botón de confirmación con texto "Aceptar" o "Iniciar Sesión"
4. WHILE el Diálogo_Sesión_Expirada está visible, THE App_Flutter SHALL impedir la interacción con el contenido detrás del diálogo (modal bloqueante)
5. THE Diálogo_Sesión_Expirada SHALL mostrarse una sola vez por evento de expiración, evitando múltiples diálogos simultáneos si varias peticiones fallan al mismo tiempo

### Requisito 3: Limpieza de Sesión y Redirección

**Historia de Usuario:** Como usuario de la aplicación, quiero ser redirigido al login después de que mi sesión expire, para poder autenticarme nuevamente de forma segura.

#### Criterios de Aceptación

1. WHEN el usuario presiona el botón de confirmación en el Diálogo_Sesión_Expirada, THE App_Flutter SHALL eliminar el Token_OAuth2 almacenado en SharedPreferences
2. WHEN el usuario presiona el botón de confirmación en el Diálogo_Sesión_Expirada, THE App_Flutter SHALL eliminar los datos de usuario almacenados en SharedPreferences
3. WHEN la limpieza de datos de sesión se completa, THE App_Flutter SHALL navegar a la Pantalla_Login
4. WHEN la App_Flutter navega a la Pantalla_Login por sesión expirada, THE App_Flutter SHALL limpiar toda la pila de navegación para que el usuario no pueda regresar con el botón atrás

### Requisito 4: Prevención de Peticiones con Token Expirado

**Historia de Usuario:** Como dueño del producto, quiero que una vez detectada la expiración no se sigan haciendo peticiones inválidas al backend, para evitar carga innecesaria en el servidor.

#### Criterios de Aceptación

1. WHEN el Interceptor_HTTP detecta una sesión expirada, THE App_Flutter SHALL cancelar o ignorar cualquier petición HTTP pendiente que use el Token_OAuth2 expirado
2. WHILE la sesión está marcada como expirada y el Diálogo_Sesión_Expirada está visible, THE ApiService SHALL rechazar nuevas peticiones HTTP autenticadas sin enviarlas al backend

### Requisito 5: Manejo de Errores de Conectividad

**Historia de Usuario:** Como usuario de la aplicación, quiero que la app distinga entre un error de red y una sesión expirada, para no ser redirigido al login innecesariamente.

#### Criterios de Aceptación

1. IF ocurre un error de conexión (timeout, sin internet), THEN THE Interceptor_HTTP SHALL distinguir el error de conectividad de un error de token expirado
2. IF ocurre un error de conexión, THEN THE App_Flutter SHALL mostrar un mensaje de error de conectividad en lugar del Diálogo_Sesión_Expirada
