# Requirements Document

## Introduction

Sistema de acceso a módulos basado en roles dinámicos para TrustBank. Actualmente, los permisos están codificados de forma estática en el frontend (Flutter) mediante un enum `Permission` y un mapa `RolePermissions`. El backend tiene una entidad `RolEntity` simple con solo un campo `name`. Este feature reemplaza el sistema estático por uno dinámico donde un administrador puede crear/editar roles, asignar/quitar módulos a cada rol, y asignar roles a usuarios registrados. Los usuarios solo verán los módulos que su rol tenga habilitados.

## Glossary

- **Sistema**: La aplicación TrustBank compuesta por el frontend Flutter web y el backend Spring Boot
- **Administrador**: Usuario con el rol que tiene el permiso de gestionar roles y módulos
- **Módulo**: Sección funcional de la aplicación accesible desde el panel administrativo (Leads, Documentos, Aprobación de Documentos, Gestión de Usuarios, Gestión de Roles)
- **Rol**: Entidad configurable que agrupa un conjunto de módulos permitidos y se asigna a usuarios
- **Módulo_Asignado**: Relación entre un Rol y un Módulo que indica que los usuarios con ese Rol pueden acceder a ese Módulo
- **Panel_Administrativo**: Dashboard principal de administración de TrustBank
- **API_Backend**: Servicio REST Spring Boot que gestiona la lógica de negocio y persistencia
- **Catálogo_de_Módulos**: Lista completa de módulos disponibles en el sistema que pueden ser asignados a roles

## Requirements

### Requirement 1: Gestión de Roles (CRUD)

**User Story:** Como Administrador, quiero crear, editar y eliminar roles personalizados, para poder definir diferentes niveles de acceso en la plataforma.

#### Acceptance Criteria

1. WHEN el Administrador solicita crear un nuevo rol con un nombre único, THE API_Backend SHALL persistir el rol en la base de datos y retornar el rol creado con su identificador
2. WHEN el Administrador solicita crear un rol con un nombre que ya existe, THE API_Backend SHALL retornar un error indicando que el nombre del rol ya está en uso
3. WHEN el Administrador solicita editar el nombre de un rol existente, THE API_Backend SHALL actualizar el nombre del rol y retornar el rol actualizado
4. WHEN el Administrador solicita eliminar un rol que no tiene usuarios asignados, THE API_Backend SHALL eliminar el rol de la base de datos
5. IF el Administrador solicita eliminar un rol que tiene usuarios asignados, THEN THE Sistema SHALL impedir la eliminación y mostrar un mensaje indicando que el rol tiene usuarios asociados
6. THE API_Backend SHALL validar que el nombre del rol tenga entre 3 y 50 caracteres alfanuméricos

### Requirement 2: Asignación de Módulos a Roles

**User Story:** Como Administrador, quiero asignar o quitar módulos a un rol, para controlar qué secciones de la aplicación pueden ver los usuarios con ese rol.

#### Acceptance Criteria

1. WHEN el Administrador asigna un módulo del Catálogo_de_Módulos a un rol, THE API_Backend SHALL crear la relación Módulo_Asignado entre el rol y el módulo
2. WHEN el Administrador quita un módulo de un rol, THE API_Backend SHALL eliminar la relación Módulo_Asignado entre el rol y el módulo
3. WHEN el Administrador consulta la configuración de un rol, THE API_Backend SHALL retornar la lista completa de módulos del Catálogo_de_Módulos indicando cuáles están asignados al rol
4. THE API_Backend SHALL permitir asignar múltiples módulos a un rol en una sola operación
5. THE API_Backend SHALL permitir que un módulo esté asignado a múltiples roles simultáneamente

### Requirement 3: Asignación de Roles a Usuarios

**User Story:** Como Administrador, quiero asignar un rol a los usuarios que se registran en la aplicación, para que tengan el nivel de acceso apropiado.

#### Acceptance Criteria

1. WHEN un nuevo usuario se registra en la aplicación, THE API_Backend SHALL asignar automáticamente el rol por defecto al usuario
2. WHEN el Administrador cambia el rol de un usuario existente, THE API_Backend SHALL actualizar la relación usuario-rol y retornar la confirmación del cambio
3. WHEN el Administrador consulta la lista de usuarios, THE Sistema SHALL mostrar el rol asignado a cada usuario
4. THE API_Backend SHALL validar que el rol asignado exista en el sistema antes de asociarlo a un usuario

### Requirement 4: Control de Visibilidad de Módulos en el Frontend

**User Story:** Como usuario registrado, quiero ver solo los módulos que mi rol tiene habilitados, para acceder únicamente a las funcionalidades que me corresponden.

#### Acceptance Criteria

1. WHEN un usuario inicia sesión, THE Sistema SHALL obtener del API_Backend la lista de módulos permitidos para el rol del usuario
2. WHILE un usuario está autenticado, THE Panel_Administrativo SHALL mostrar únicamente los módulos que están asignados al rol del usuario
3. IF un usuario intenta acceder a un módulo no asignado a su rol mediante URL directa, THEN THE Sistema SHALL redirigir al usuario al Panel_Administrativo y mostrar un mensaje de acceso denegado
4. WHEN el Administrador modifica los módulos de un rol, THE Sistema SHALL reflejar los cambios en la próxima sesión de los usuarios afectados

### Requirement 5: Interfaz de Gestión de Roles

**User Story:** Como Administrador, quiero una pantalla dedicada para gestionar roles y sus módulos, para poder configurar el acceso de forma visual e intuitiva.

#### Acceptance Criteria

1. THE Sistema SHALL proporcionar una pantalla de gestión de roles accesible desde el Panel_Administrativo
2. WHEN el Administrador accede a la pantalla de gestión de roles, THE Sistema SHALL mostrar la lista de todos los roles existentes con el número de usuarios asignados a cada uno
3. WHEN el Administrador selecciona un rol para editar, THE Sistema SHALL mostrar el Catálogo_de_Módulos con toggles o checkboxes indicando cuáles módulos están activos para ese rol
4. WHEN el Administrador guarda los cambios de módulos de un rol, THE Sistema SHALL enviar la configuración actualizada al API_Backend y confirmar el guardado exitoso
5. IF ocurre un error al guardar la configuración del rol, THEN THE Sistema SHALL mostrar un mensaje de error descriptivo y mantener el estado anterior de la configuración

### Requirement 6: Catálogo de Módulos del Sistema

**User Story:** Como Administrador, quiero que el sistema mantenga un catálogo de módulos disponibles, para poder asignarlos a los roles de forma consistente.

#### Acceptance Criteria

1. THE API_Backend SHALL mantener un catálogo persistente de módulos disponibles que incluya: Leads, Documentos, Aprobación de Documentos, Gestión de Usuarios, y Gestión de Roles
2. THE API_Backend SHALL almacenar para cada módulo un identificador único, un nombre legible, una descripción y un ícono representativo
3. WHEN el Administrador consulta el Catálogo_de_Módulos, THE API_Backend SHALL retornar todos los módulos disponibles con su información completa
4. THE Sistema SHALL permitir agregar nuevos módulos al catálogo sin requerir cambios en el código del frontend

### Requirement 7: Seguridad y Autorización en el Backend

**User Story:** Como desarrollador del sistema, quiero que el backend valide los permisos de acceso a módulos, para garantizar que la seguridad no dependa únicamente del frontend.

#### Acceptance Criteria

1. WHEN un usuario realiza una petición a un endpoint protegido, THE API_Backend SHALL verificar que el rol del usuario tiene asignado el módulo correspondiente al endpoint
2. IF un usuario sin el módulo requerido intenta acceder a un endpoint protegido, THEN THE API_Backend SHALL retornar un código HTTP 403 con un mensaje de acceso denegado
3. THE API_Backend SHALL proteger los endpoints de gestión de roles para que solo usuarios con el permiso de gestión de roles puedan acceder
4. WHEN el token de autenticación del usuario es válido pero el rol no tiene acceso al módulo solicitado, THE API_Backend SHALL registrar el intento de acceso no autorizado en los logs del sistema
