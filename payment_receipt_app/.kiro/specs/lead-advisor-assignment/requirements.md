# Documento de Requerimientos: Asignación Directa de Leads a Asesores

## Introducción

Este feature reemplaza el sistema actual de filtrado de leads por campaña (campo `campana` → `filterValue` del tipo de asignación) con un modelo de asignación directa de leads individuales a usuarios asesores (ROLE_SUPERVISOR). Con este cambio, cada lead importado desde Excel puede ser asignado explícitamente a un asesor específico, y el asesor solo podrá visualizar y gestionar los leads que le fueron asignados directamente. El administrador podrá asignar leads de forma manual, reasignarlos entre asesores, y gestionar leads no asignados.

## Glosario

- **Sistema**: La aplicación TrustBank compuesta por el frontend Flutter web y el backend Spring Boot
- **Administrador**: Usuario con rol ROLE_ADMIN que gestiona la asignación de leads a asesores
- **Asesor**: Usuario con rol ROLE_SUPERVISOR que visualiza y edita únicamente los leads asignados directamente a su cuenta
- **Lead**: Registro de prospecto importado desde un archivo Excel, almacenado en la tabla `leads`
- **Asignación_Directa**: Relación uno-a-uno entre un lead específico y un asesor, almacenada como referencia al asesor en el registro del lead
- **Panel_Asesor**: Vista dedicada donde el asesor visualiza y edita exclusivamente los leads asignados a su cuenta
- **Panel_Administrativo**: Dashboard principal de administración de TrustBank
- **API_Backend**: Servicio REST Spring Boot que gestiona la lógica de negocio y persistencia
- **Lead_No_Asignado**: Lead que no tiene un asesor vinculado (campo de asignación nulo)
- **Asignación_Masiva**: Operación que permite asignar múltiples leads a un asesor en una sola acción

## Requerimientos

### Requerimiento 1: Modelo de Asignación Directa Lead-Asesor

**User Story:** Como Administrador, quiero que cada lead pueda ser asignado directamente a un asesor específico, para que el asesor solo vea los leads que le corresponden sin depender del filtrado por campaña.

#### Criterios de Aceptación

1. THE API_Backend SHALL almacenar una referencia al asesor asignado en cada registro de lead mediante un campo `advisor_id` en la tabla `leads`
2. THE API_Backend SHALL permitir que el campo `advisor_id` de un lead sea nulo, indicando que el lead no está asignado a ningún asesor
3. WHEN un lead tiene un valor en el campo `advisor_id`, THE Sistema SHALL considerar ese lead como asignado al asesor referenciado
4. THE API_Backend SHALL validar que el `advisor_id` referencia a un usuario existente con rol ROLE_SUPERVISOR antes de persistir la asignación
5. THE Sistema SHALL permitir que un lead sea asignado a un único asesor a la vez

### Requerimiento 2: Asignación Manual de Leads por el Administrador

**User Story:** Como Administrador, quiero poder asignar leads individuales o en lote a un asesor desde el panel administrativo, para distribuir la carga de trabajo entre los asesores disponibles.

#### Criterios de Aceptación

1. WHEN el Administrador selecciona uno o más leads desde la lista de leads, THE Sistema SHALL mostrar una opción para asignar los leads seleccionados a un asesor
2. WHEN el Administrador elige la opción de asignar, THE Sistema SHALL mostrar un selector con la lista de asesores activos (usuarios con ROLE_SUPERVISOR)
3. WHEN el Administrador confirma la asignación de leads a un asesor, THE API_Backend SHALL actualizar el campo `advisor_id` de cada lead seleccionado con el ID del asesor elegido
4. WHEN la Asignación_Masiva se completa exitosamente, THE Sistema SHALL mostrar un mensaje de confirmación indicando la cantidad de leads asignados y el nombre del asesor
5. IF algún lead seleccionado ya tiene un asesor asignado, THEN THE Sistema SHALL mostrar una advertencia indicando que se reasignarán esos leads y solicitar confirmación antes de proceder
6. THE API_Backend SHALL proporcionar un endpoint para asignar uno o más leads a un asesor en una sola petición

### Requerimiento 3: Reasignación de Leads entre Asesores

**User Story:** Como Administrador, quiero poder reasignar leads de un asesor a otro, para redistribuir la carga de trabajo cuando sea necesario.

#### Criterios de Aceptación

1. WHEN el Administrador visualiza un lead asignado, THE Sistema SHALL mostrar el nombre del asesor actualmente asignado
2. WHEN el Administrador selecciona la opción de reasignar un lead, THE Sistema SHALL mostrar un selector con los asesores disponibles excluyendo al asesor actualmente asignado
3. WHEN el Administrador confirma la reasignación, THE API_Backend SHALL actualizar el campo `advisor_id` del lead con el ID del nuevo asesor
4. WHEN el Administrador selecciona la opción de desasignar un lead, THE API_Backend SHALL establecer el campo `advisor_id` del lead en nulo
5. THE API_Backend SHALL proporcionar un endpoint para reasignar leads de un asesor a otro en lote

### Requerimiento 4: Gestión de Leads No Asignados

**User Story:** Como Administrador, quiero poder identificar y gestionar los leads que no tienen asesor asignado, para asegurar que todos los prospectos sean atendidos.

#### Criterios de Aceptación

1. WHEN el Administrador accede a la lista de leads, THE Sistema SHALL proporcionar un filtro para mostrar únicamente los leads sin asesor asignado
2. WHEN el Administrador aplica el filtro de leads no asignados, THE API_Backend SHALL retornar todos los leads donde el campo `advisor_id` sea nulo
3. THE Sistema SHALL mostrar un indicador visual en la lista de leads que distinga entre leads asignados y leads no asignados
4. WHEN se importan nuevos leads desde un archivo Excel, THE API_Backend SHALL crear los registros con el campo `advisor_id` en nulo

### Requerimiento 5: Visualización de Leads por el Asesor (Asignación Directa)

**User Story:** Como Asesor, quiero ver únicamente los leads que me fueron asignados directamente, para enfocarme en los prospectos que debo gestionar.

#### Criterios de Aceptación

1. WHEN un usuario con rol ROLE_SUPERVISOR consulta sus leads, THE API_Backend SHALL retornar exclusivamente los leads donde el campo `advisor_id` coincida con el ID del asesor autenticado
2. WHEN el Asesor utiliza el campo de búsqueda, THE Sistema SHALL filtrar únicamente dentro de los leads asignados al asesor autenticado
3. THE Panel_Asesor SHALL mostrar la cantidad total de leads asignados al asesor en la cabecera de la vista
4. IF el Asesor no tiene leads asignados, THEN THE Panel_Asesor SHALL mostrar un mensaje indicando que no tiene leads asignados actualmente
5. THE API_Backend SHALL proporcionar un endpoint paginado que retorne leads filtrados por el `advisor_id` del asesor autenticado

### Requerimiento 6: Restricciones de Acceso del Asesor sobre Leads Asignados

**User Story:** Como desarrollador del sistema, quiero que el backend garantice que un asesor solo pueda acceder y editar leads asignados a su cuenta, para mantener la seguridad y privacidad de los datos.

#### Criterios de Aceptación

1. WHEN un Asesor realiza una petición GET para obtener un lead específico, THE API_Backend SHALL verificar que el campo `advisor_id` del lead coincida con el ID del asesor autenticado antes de retornar los datos
2. IF un Asesor intenta acceder a un lead cuyo `advisor_id` no coincide con su ID, THEN THE API_Backend SHALL retornar un código HTTP 403
3. WHEN un Asesor realiza una petición PUT para actualizar un lead, THE API_Backend SHALL verificar la pertenencia del lead antes de procesar la actualización
4. IF un Asesor intenta actualizar un lead que no le está asignado, THEN THE API_Backend SHALL retornar un código HTTP 403 y registrar el intento en los logs
5. IF un Asesor intenta crear o eliminar leads, THEN THE API_Backend SHALL retornar un código HTTP 403

### Requerimiento 7: Listado de Asesores y sus Leads Asignados

**User Story:** Como Administrador, quiero ver un resumen de cuántos leads tiene asignado cada asesor, para monitorear la distribución de trabajo.

#### Criterios de Aceptación

1. THE API_Backend SHALL proporcionar un endpoint que retorne la lista de asesores con la cantidad de leads asignados a cada uno
2. WHEN el Administrador consulta el resumen de asesores, THE Sistema SHALL mostrar el nombre del asesor, su email y la cantidad de leads asignados
3. THE Sistema SHALL incluir en el resumen a los asesores con cero leads asignados
4. WHEN el Administrador selecciona un asesor del resumen, THE Sistema SHALL mostrar la lista de leads asignados a ese asesor específico

### Requerimiento 8: Compatibilidad con el Sistema de Importación Existente

**User Story:** Como Administrador, quiero que los leads importados desde Excel se creen sin asignación por defecto, para poder asignarlos manualmente después de la importación.

#### Criterios de Aceptación

1. WHEN el Administrador importa leads desde un archivo Excel, THE API_Backend SHALL crear los registros de leads con el campo `advisor_id` en nulo
2. THE Sistema SHALL mantener el proceso de importación de Excel existente sin modificaciones en su flujo actual
3. WHEN la importación finaliza, THE Sistema SHALL mostrar la cantidad de leads importados y un enlace para asignarlos a asesores
4. IF el archivo Excel contiene una columna de asesor, THEN THE API_Backend SHALL ignorar esa columna y crear los leads sin asignación

