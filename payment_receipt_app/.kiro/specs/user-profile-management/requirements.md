# Documento de Requisitos - Gestión de Perfil de Usuario

## Introducción

Este documento define los requisitos para la funcionalidad de gestión de perfil de usuario en la plataforma GuardiansTrustBank. La funcionalidad permite a los usuarios actualizar su contraseña y datos personales, a los administradores asignar roles a usuarios, y establece un rol de superadministrador oculto para los demás administradores.

## Glosario

- **Sistema**: La plataforma GuardiansTrustBank compuesta por el backend Spring Boot y el frontend Flutter
- **Usuario**: Persona registrada en la plataforma con rol ROLE_USER
- **Administrador**: Persona con rol ROLE_ADMIN que gestiona usuarios
- **Superadministrador**: Persona con rol ROLE_SUPER_ADMIN con privilegios máximos, invisible para administradores regulares
- **Perfil**: Conjunto de datos personales del usuario (nombre, apellido, email, teléfono, dirección, ciudad, país, código postal, descripción personal)
- **Servicio_de_Autenticación**: Componente del backend que gestiona tokens OAuth2 y validación de credenciales
- **API_Backend**: API REST del backend Spring Boot que expone los endpoints de gestión
- **App_Flutter**: Aplicación móvil/web Flutter que consume la API_Backend
- **Contraseña_Actual**: Contraseña vigente del usuario utilizada para verificar identidad antes de un cambio
- **Contraseña_Nueva**: Nueva contraseña que reemplazará a la contraseña actual tras validación

## Requisitos

### Requisito 1: Actualización de Contraseña

**Historia de Usuario:** Como usuario, quiero actualizar mi contraseña desde mi perfil, para mantener la seguridad de mi cuenta.

#### Criterios de Aceptación

1. WHEN el Usuario proporciona la contraseña actual correcta y una contraseña nueva válida, THE API_Backend SHALL actualizar la contraseña del Usuario almacenándola con cifrado BCrypt
2. WHEN el Usuario proporciona una contraseña actual incorrecta, THE API_Backend SHALL rechazar la solicitud con un mensaje de error indicando que la contraseña actual es incorrecta
3. WHEN el Usuario proporciona una contraseña nueva con menos de 8 caracteres, THE API_Backend SHALL rechazar la solicitud indicando que la contraseña nueva no cumple los requisitos mínimos de longitud
4. WHEN la contraseña se actualiza exitosamente, THE App_Flutter SHALL mostrar un mensaje de confirmación al Usuario y cerrar el formulario de cambio de contraseña
5. IF el Usuario no está autenticado al intentar cambiar la contraseña, THEN THE API_Backend SHALL retornar un error 401 y denegar la operación

### Requisito 2: Actualización de Datos Personales

**Historia de Usuario:** Como usuario, quiero actualizar mis datos personales (nombre, apellido, teléfono, dirección, ciudad, país, código postal, descripción), para mantener mi información al día.

#### Criterios de Aceptación

1. WHEN el Usuario envía un formulario con datos personales actualizados, THE API_Backend SHALL guardar los cambios en la base de datos y retornar el objeto de usuario actualizado
2. WHEN el Usuario modifica su nombre o apellido, THE API_Backend SHALL validar que los campos no estén vacíos y tengan un máximo de 50 caracteres
3. WHEN el Usuario modifica su número de teléfono, THE API_Backend SHALL validar que el formato contenga entre 7 y 30 caracteres
4. WHEN el Usuario intenta modificar su email, THE API_Backend SHALL verificar que el nuevo email no esté registrado por otro usuario antes de guardar el cambio
5. WHEN los datos se actualizan exitosamente, THE App_Flutter SHALL refrescar la información del perfil en la pantalla y en el almacenamiento local
6. IF la solicitud de actualización contiene campos con formato inválido, THEN THE API_Backend SHALL retornar un error 400 con los detalles de validación por cada campo incorrecto

### Requisito 3: Asignación de Roles por Administrador

**Historia de Usuario:** Como administrador, quiero asignar roles a cualquier usuario, para gestionar los permisos y accesos dentro de la plataforma.

#### Criterios de Aceptación

1. WHEN el Administrador selecciona un usuario y asigna un nuevo rol, THE API_Backend SHALL actualizar el rol del usuario en la base de datos
2. WHEN el Administrador solicita la lista de roles disponibles, THE API_Backend SHALL retornar los roles ROLE_USER, ROLE_MODERATOR y ROLE_ADMIN (excluyendo ROLE_SUPER_ADMIN)
3. WHEN el Administrador intenta asignar el rol ROLE_SUPER_ADMIN a un usuario, THE API_Backend SHALL rechazar la operación con un error 403
4. WHEN un usuario con rol ROLE_USER intenta asignar roles, THE API_Backend SHALL rechazar la solicitud con un error 403 indicando permisos insuficientes
5. WHEN el rol se asigna exitosamente, THE App_Flutter SHALL actualizar la lista de usuarios reflejando el nuevo rol asignado
6. THE API_Backend SHALL registrar en un log cada cambio de rol incluyendo el administrador que realizó el cambio, el usuario afectado y el rol anterior y nuevo

### Requisito 4: Ocultamiento del Superadministrador

**Historia de Usuario:** Como superadministrador, quiero que mi cuenta sea invisible para los administradores regulares, para mantener un nivel de control superior sin interferencia.

#### Criterios de Aceptación

1. WHEN el Administrador solicita la lista de todos los usuarios, THE API_Backend SHALL excluir de la respuesta a los usuarios con rol ROLE_SUPER_ADMIN
2. WHEN el Administrador busca usuarios por nombre, email o cualquier criterio, THE API_Backend SHALL excluir de los resultados a los usuarios con rol ROLE_SUPER_ADMIN
3. WHEN el Superadministrador solicita la lista de todos los usuarios, THE API_Backend SHALL incluir a todos los usuarios sin excepción
4. WHEN el Administrador intenta acceder al perfil de un Superadministrador por ID directo, THE API_Backend SHALL retornar un error 404 como si el usuario no existiera
5. THE App_Flutter SHALL ocultar el rol ROLE_SUPER_ADMIN de la lista de roles disponibles para asignación cuando el usuario autenticado es un Administrador

### Requisito 5: Visualización del Perfil Propio

**Historia de Usuario:** Como usuario, quiero ver mi información de perfil completa en una pantalla dedicada, para revisar mis datos actuales.

#### Criterios de Aceptación

1. WHEN el Usuario accede a la pantalla de perfil, THE App_Flutter SHALL mostrar todos los datos personales del usuario incluyendo nombre, apellido, email, teléfono, dirección, ciudad, país y código postal
2. WHEN el Usuario accede a la pantalla de perfil, THE App_Flutter SHALL obtener los datos más recientes del API_Backend antes de mostrarlos
3. WHILE la App_Flutter está cargando los datos del perfil, THE App_Flutter SHALL mostrar un indicador de carga al Usuario
4. IF la solicitud de datos del perfil falla por error de red, THEN THE App_Flutter SHALL mostrar un mensaje de error con opción de reintentar

### Requisito 6: Gestión de Roles por Superadministrador

**Historia de Usuario:** Como superadministrador, quiero tener acceso completo a la gestión de roles incluyendo la capacidad de asignar el rol de administrador y ver todos los usuarios, para mantener el control total de la plataforma.

#### Criterios de Aceptación

1. WHEN el Superadministrador solicita la lista de roles disponibles, THE API_Backend SHALL retornar todos los roles incluyendo ROLE_USER, ROLE_MODERATOR, ROLE_ADMIN y ROLE_SUPER_ADMIN
2. WHEN el Superadministrador asigna el rol ROLE_SUPER_ADMIN a un usuario, THE API_Backend SHALL ejecutar la operación exitosamente
3. WHEN el Superadministrador solicita estadísticas de usuarios, THE API_Backend SHALL incluir en el conteo a todos los usuarios sin excluir superadministradores
4. THE API_Backend SHALL permitir al Superadministrador realizar todas las operaciones disponibles para el Administrador sin restricciones adicionales
