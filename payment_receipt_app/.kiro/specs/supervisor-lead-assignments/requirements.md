# Documento de Requerimientos

## Introducción

Este feature agrega un nuevo rol SUPERVISOR al sistema TrustBank. El rol de supervisor permite a usuarios designados visualizar y editar leads importados desde archivos Excel, con restricciones específicas: solo pueden editar (no crear ni eliminar), y los campos del lead no son obligatorios al editar (actualizaciones parciales). Además, se introduce un módulo de "Tipos de Asignación" que permite al administrador crear y gestionar tipos de asignación desde el panel administrativo. Al asignar el rol SUPERVISOR a un usuario, se abre un diálogo para seleccionar qué tipo de asignación recibe ese supervisor.

## Glosario

- **Sistema**: La aplicación TrustBank compuesta por el frontend Flutter web y el backend Spring Boot
- **Administrador**: Usuario con rol ROLE_ADMIN que gestiona roles, módulos y configuraciones del sistema
- **Supervisor**: Usuario con rol ROLE_SUPERVISOR que puede visualizar y editar leads asignados según su tipo de asignación
- **Lead**: Registro de prospecto importado desde un archivo Excel, almacenado en la tabla `leads`
- **Tipo_de_Asignación**: Categoría configurable que define qué grupo de leads puede gestionar un supervisor (ej: por campaña, por país, por fecha de importación)
- **Asignación_Supervisor**: Relación entre un usuario con rol SUPERVISOR y un Tipo_de_Asignación específico
- **Panel_Supervisor**: Vista dedicada donde el supervisor visualiza y edita los leads que le corresponden según su asignación
- **Panel_Administrativo**: Dashboard principal de administración de TrustBank
- **API_Backend**: Servicio REST Spring Boot que gestiona la lógica de negocio y persistencia
- **Módulo_Asignaciones**: Módulo del catálogo del sistema que permite gestionar los tipos de asignación desde el panel administrativo
- **Actualización_Parcial**: Operación de edición donde solo se envían y actualizan los campos modificados, sin requerir que todos los campos tengan valor

## Requerimientos

### Requerimiento 1: Creación del Rol SUPERVISOR

**User Story:** Como Administrador, quiero disponer de un rol SUPERVISOR en el sistema, para poder asignar a usuarios un nivel de acceso intermedio enfocado en la gestión de leads.

#### Criterios de Aceptación

1. THE API_Backend SHALL registrar el rol ROLE_SUPERVISOR en la base de datos como un rol válido del sistema
2. WHEN el Administrador accede a la pantalla de gestión de usuarios, THE Sistema SHALL mostrar ROLE_SUPERVISOR como opción seleccionable mediante un radio button
3. THE Sistema SHALL permitir que el rol ROLE_SUPERVISOR coexista con los roles existentes ROLE_USER, ROLE_ADMIN y ROLE_SUPER_ADMIN sin conflictos
4. WHEN un usuario tiene asignado el rol ROLE_SUPERVISOR, THE Sistema SHALL otorgar acceso únicamente al Panel_Supervisor y a los módulos configurados para ese rol

### Requerimiento 2: Módulo de Gestión de Tipos de Asignación

**User Story:** Como Administrador, quiero crear y gestionar tipos de asignación desde el panel administrativo, para poder definir las categorías bajo las cuales los supervisores acceden a los leads.

#### Criterios de Aceptación

1. THE API_Backend SHALL proporcionar un endpoint CRUD para gestionar los tipos de asignación (crear, listar, actualizar, eliminar)
2. WHEN el Administrador crea un nuevo Tipo_de_Asignación, THE API_Backend SHALL persistir el registro con un nombre único, una descripción y un estado activo/inactivo
3. WHEN el Administrador solicita la lista de tipos de asignación, THE API_Backend SHALL retornar todos los registros con su nombre, descripción y estado
4. WHEN el Administrador actualiza un Tipo_de_Asignación existente, THE API_Backend SHALL modificar los campos proporcionados y retornar el registro actualizado
5. IF el Administrador solicita eliminar un Tipo_de_Asignación que tiene supervisores asociados, THEN THE API_Backend SHALL impedir la eliminación y retornar un mensaje indicando que existen supervisores vinculados
6. WHEN el Administrador solicita eliminar un Tipo_de_Asignación sin supervisores asociados, THE API_Backend SHALL eliminar el registro de la base de datos
7. THE Sistema SHALL incluir el Módulo_Asignaciones en el catálogo de módulos del sistema con el código "SUPERVISOR_ASSIGNMENTS"

### Requerimiento 3: Interfaz de Gestión de Tipos de Asignación

**User Story:** Como Administrador, quiero una pantalla dedicada en el panel administrativo para gestionar los tipos de asignación, para poder configurar las categorías de forma visual.

#### Criterios de Aceptación

1. THE Sistema SHALL proporcionar una pantalla de gestión de tipos de asignación accesible desde el Panel_Administrativo
2. WHEN el Administrador accede a la pantalla de tipos de asignación, THE Sistema SHALL mostrar la lista de todos los tipos existentes con su nombre, descripción y estado
3. WHEN el Administrador presiona el botón de crear nuevo tipo, THE Sistema SHALL mostrar un formulario con campos para nombre, descripción y estado
4. WHEN el Administrador guarda un nuevo tipo de asignación con datos válidos, THE Sistema SHALL enviar la solicitud al API_Backend y confirmar la creación exitosa
5. IF ocurre un error al guardar el tipo de asignación, THEN THE Sistema SHALL mostrar un mensaje de error descriptivo y mantener los datos del formulario

### Requerimiento 4: Diálogo de Selección de Tipo de Asignación al Asignar Rol SUPERVISOR

**User Story:** Como Administrador, quiero que al seleccionar el rol SUPERVISOR para un usuario se abra un diálogo para elegir el tipo de asignación, para poder vincular al supervisor con su categoría de leads correspondiente.

#### Criterios de Aceptación

1. WHEN el Administrador selecciona el radio button de ROLE_SUPERVISOR en la pantalla de asignación de rol, THE Sistema SHALL abrir un diálogo modal con la lista de tipos de asignación activos
2. WHEN el Administrador selecciona un Tipo_de_Asignación en el diálogo y confirma, THE Sistema SHALL crear la Asignación_Supervisor vinculando al usuario con el tipo seleccionado
3. IF el Administrador cancela el diálogo de selección de tipo de asignación, THEN THE Sistema SHALL revertir la selección del radio button al rol anterior del usuario
4. WHEN el Administrador confirma la asignación, THE API_Backend SHALL persistir la relación entre el usuario, el rol ROLE_SUPERVISOR y el Tipo_de_Asignación seleccionado
5. IF no existen tipos de asignación activos al momento de seleccionar ROLE_SUPERVISOR, THEN THE Sistema SHALL mostrar un mensaje indicando que se deben crear tipos de asignación primero y no permitir la asignación del rol

### Requerimiento 5: Panel del Supervisor (Visualización de Leads)

**User Story:** Como Supervisor, quiero ver los leads asignados a mi tipo de asignación en un panel dedicado, para poder gestionar los prospectos que me corresponden.

#### Criterios de Aceptación

1. WHEN un usuario con rol ROLE_SUPERVISOR inicia sesión, THE Sistema SHALL mostrar el Panel_Supervisor como vista principal
2. WHEN el Panel_Supervisor se carga, THE Sistema SHALL obtener del API_Backend la lista de leads filtrados según el Tipo_de_Asignación del supervisor
3. THE Panel_Supervisor SHALL mostrar los leads en formato de tabla con paginación, incluyendo los campos: nombre, apellido, teléfono, email, país, campaña, estado de última llamada y comentarios
4. WHEN el Supervisor utiliza el campo de búsqueda, THE Sistema SHALL filtrar los leads visibles por término en los campos nombre, apellido, teléfono y email
5. THE API_Backend SHALL proporcionar un endpoint que retorne leads paginados filtrados por el Tipo_de_Asignación del supervisor autenticado

### Requerimiento 6: Edición de Leads por el Supervisor (Solo Edición)

**User Story:** Como Supervisor, quiero poder editar los campos de los leads asignados, para poder actualizar la información de los prospectos durante mi gestión.

#### Criterios de Aceptación

1. WHEN el Supervisor selecciona un lead del Panel_Supervisor, THE Sistema SHALL mostrar un formulario de edición con todos los campos del lead
2. THE Sistema SHALL permitir al Supervisor modificar cualquier campo individual del lead sin requerir que los demás campos tengan valor
3. WHEN el Supervisor guarda los cambios de un lead, THE API_Backend SHALL aplicar una Actualización_Parcial actualizando únicamente los campos que fueron modificados
4. THE API_Backend SHALL aceptar solicitudes de actualización donde uno o más campos tengan valor nulo o vacío sin retornar error de validación
5. IF el Supervisor intenta acceder a un endpoint de creación de leads, THEN THE API_Backend SHALL retornar un código HTTP 403
6. IF el Supervisor intenta acceder a un endpoint de eliminación de leads, THEN THE API_Backend SHALL retornar un código HTTP 403
7. WHEN el Supervisor guarda cambios exitosamente, THE Sistema SHALL mostrar un mensaje de confirmación y actualizar la vista del lead en la tabla

### Requerimiento 7: Restricciones de Acceso del Rol SUPERVISOR

**User Story:** Como desarrollador del sistema, quiero que el backend valide las restricciones del rol SUPERVISOR, para garantizar que los supervisores solo puedan realizar operaciones de edición sobre leads asignados.

#### Criterios de Aceptación

1. WHEN un usuario con rol ROLE_SUPERVISOR realiza una petición GET a los endpoints de leads, THE API_Backend SHALL retornar únicamente los leads correspondientes a su Tipo_de_Asignación
2. WHEN un usuario con rol ROLE_SUPERVISOR realiza una petición PUT a un lead que pertenece a su asignación, THE API_Backend SHALL procesar la actualización
3. IF un usuario con rol ROLE_SUPERVISOR realiza una petición PUT a un lead que no pertenece a su asignación, THEN THE API_Backend SHALL retornar un código HTTP 403
4. IF un usuario con rol ROLE_SUPERVISOR realiza una petición POST al endpoint de importación de leads, THEN THE API_Backend SHALL retornar un código HTTP 403
5. IF un usuario con rol ROLE_SUPERVISOR realiza una petición DELETE a cualquier endpoint de leads, THEN THE API_Backend SHALL retornar un código HTTP 403
6. THE API_Backend SHALL registrar en los logs del sistema los intentos de acceso no autorizado por parte de supervisores

### Requerimiento 8: Gestión de Asignaciones de Supervisores

**User Story:** Como Administrador, quiero poder ver y modificar las asignaciones de los supervisores, para poder reasignar categorías de leads según las necesidades operativas.

#### Criterios de Aceptación

1. WHEN el Administrador consulta el detalle de un usuario con rol SUPERVISOR, THE Sistema SHALL mostrar el Tipo_de_Asignación actualmente vinculado
2. WHEN el Administrador cambia el Tipo_de_Asignación de un supervisor existente, THE API_Backend SHALL actualizar la relación y retornar la confirmación del cambio
3. WHEN el Administrador cambia el rol de un supervisor a otro rol diferente, THE API_Backend SHALL eliminar la Asignación_Supervisor asociada
4. THE API_Backend SHALL proporcionar un endpoint para consultar todos los supervisores con su tipo de asignación asociado
