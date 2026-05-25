# Implementation Plan: Supervisor Lead Assignments

## Overview

Implementación del rol SUPERVISOR y el sistema de asignación de leads por tipo para TrustBank. El plan sigue un enfoque incremental: primero la capa de datos (schema + seed), luego el backend (entidades → repositorios → servicios → controladores → filtro de seguridad), después el frontend (modelos → servicios → BLoC → pantallas), y finalmente la integración con el flujo de asignación de rol y el diálogo modal.

## Tasks

- [x] 1. Database schema y seed data
  - [x] 1.1 Crear migración SQL para tablas assignment_types y supervisor_assignments
    - Crear tabla `assignment_types` con columnas: id, name (unique), description, active, filter_value, created_at, updated_at
    - Crear tabla `supervisor_assignments` con columnas: id, user_id (FK → usersbank), assignment_type_id (FK → assignment_types), assigned_at, UNIQUE(user_id)
    - Agregar seed data: INSERT del rol ROLE_SUPERVISOR (id=4) en `rolsbank`
    - Agregar seed data: INSERT del módulo SUPERVISOR_ASSIGNMENTS (id=6, code='SUPERVISOR_ASSIGNMENTS') en `modules`
    - Agregar seed data: INSERT en `role_modules` para asignar módulo SUPERVISOR_ASSIGNMENTS a ROLE_ADMIN y ROLE_SUPER_ADMIN
    - Agregar seed data: INSERT en `role_modules` para asignar módulo LEADS a ROLE_SUPERVISOR
    - _Requirements: 1.1, 1.3, 2.7, 7.1_

- [x] 2. Backend entidades y repositorios
  - [x] 2.1 Crear entidad AssignmentTypeEntity
    - Crear clase `AssignmentTypeEntity` en el paquete `models.entity` con campos: id, name, description, active, filterValue, createdAt, updatedAt
    - Agregar anotaciones JPA: `@Entity`, `@Table(name = "assignment_types")`, `@Column` con constraints (unique name, not-null name)
    - Implementar `Serializable`
    - _Requirements: 2.1, 2.2_

  - [x] 2.2 Crear entidad SupervisorAssignmentEntity
    - Crear clase `SupervisorAssignmentEntity` en el paquete `models.entity` con campos: id, user (ManyToOne → UserEntity), assignmentType (ManyToOne → AssignmentTypeEntity), assignedAt
    - Agregar anotaciones JPA con `@JoinColumn` para user_id y assignment_type_id
    - Implementar `Serializable`
    - _Requirements: 4.4, 8.1_

  - [x] 2.3 Crear repositorio IAssignmentTypeDao
    - Crear interfaz `IAssignmentTypeDao` extendiendo `JpaRepository<AssignmentTypeEntity, Long>`
    - Agregar método `findByActiveTrue()` para listar tipos activos
    - Agregar método `findByName(String name)` para validar unicidad
    - Agregar método `existsByName(String name)` para verificación rápida
    - _Requirements: 2.1, 2.3_

  - [x] 2.4 Crear repositorio ISupervisorAssignmentDao
    - Crear interfaz `ISupervisorAssignmentDao` extendiendo `JpaRepository<SupervisorAssignmentEntity, Long>`
    - Agregar método `findByUserId(Long userId)` para obtener asignación de un supervisor
    - Agregar método `findByAssignmentTypeId(Long assignmentTypeId)` para verificar supervisores asociados a un tipo
    - Agregar método `countByAssignmentTypeId(Long assignmentTypeId)` para contar supervisores por tipo
    - Agregar método `deleteByUserId(Long userId)` para limpiar asignación al cambiar rol
    - Agregar método `existsByUserId(Long userId)` para verificar si ya tiene asignación
    - _Requirements: 2.5, 4.4, 8.2, 8.3, 8.4_

- [x] 3. Backend DTOs
  - [x] 3.1 Crear DTOs de request y response para tipos de asignación y asignaciones de supervisor
    - Crear `AssignmentTypeRequest` con validaciones: `@NotBlank @Size(max=100)` name, `@Size(max=255)` description, Boolean active, `@Size(max=100)` filterValue
    - Crear `AssignmentTypeResponse` con campos: id, name, description, active, filterValue, supervisorCount, createdAt
    - Crear `SupervisorAssignmentRequest` con `@NotNull Long userId`, `@NotNull Long assignmentTypeId`
    - Crear `SupervisorAssignmentResponse` con campos: id, userId, userName, userEmail, assignmentTypeId, assignmentTypeName, assignedAt
    - Crear `LeadPartialUpdateRequest` con todos los campos opcionales: nombre, apellido, telefono, email, pais, campana, lastCallStatus, comentarios
    - _Requirements: 2.2, 2.3, 4.4, 6.2, 6.3, 6.4_

- [x] 4. Backend servicios
  - [x] 4.1 Crear AssignmentTypeService con operaciones CRUD
    - Implementar `findAll()` retornando todos los tipos con conteo de supervisores
    - Implementar `findActive()` retornando solo tipos activos
    - Implementar `findById(Long id)` con manejo de 404
    - Implementar `create(AssignmentTypeRequest)` con validación de nombre único
    - Implementar `update(Long id, AssignmentTypeRequest)` con validación de nombre único (excluyendo el actual)
    - Implementar `delete(Long id)` con verificación de supervisores asociados (rechazar si count > 0)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [x] 4.2 Crear SupervisorAssignmentService
    - Implementar `findAll()` retornando todas las asignaciones con datos de usuario y tipo
    - Implementar `findByUserId(Long userId)` para obtener asignación de un supervisor
    - Implementar `create(SupervisorAssignmentRequest)` con validación de que el usuario no tenga asignación previa
    - Implementar `updateAssignment(Long userId, Long newAssignmentTypeId)` para cambiar tipo de asignación
    - Implementar `deleteByUserId(Long userId)` para eliminar asignación al cambiar rol
    - Agregar logging para cambios de asignación y eliminaciones
    - _Requirements: 4.2, 4.4, 8.1, 8.2, 8.3, 8.4_

  - [x] 4.3 Extender LeadService con lógica de filtrado para supervisores
    - Implementar `findLeadsBySupervisor(Long userId, Pageable pageable)` que obtiene el tipo de asignación del supervisor y filtra leads por el campo `campana` usando el `filterValue`
    - Implementar `searchLeadsBySupervisor(Long userId, String term, Pageable pageable)` que busca dentro de los leads asignados
    - Implementar `updateLeadPartial(Long leadId, Long userId, LeadPartialUpdateRequest request)` que verifica pertenencia y aplica actualización parcial
    - Implementar `isLeadInSupervisorAssignment(Long leadId, Long userId)` para verificar acceso
    - _Requirements: 5.2, 5.4, 5.5, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3_

  - [ ]* 4.4 Escribir property tests para AssignmentTypeService (jqwik)
    - **Property 1: Round-trip de creación de Tipo de Asignación** — Generar nombres y descripciones aleatorios válidos, crear tipos, verificar persistencia y aparición en lista
    - **Property 2: Round-trip de actualización de Tipo de Asignación** — Crear tipo, generar actualizaciones aleatorias, verificar que los campos se actualizan correctamente
    - **Property 3: Eliminación depende de supervisores asociados** — Crear tipos con/sin supervisores, verificar que solo los sin supervisores se eliminan
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6**

  - [ ]* 4.5 Escribir property tests para SupervisorAssignmentService (jqwik)
    - **Property 4: Creación de Asignación Supervisor persiste correctamente** — Generar usuarios y tipos aleatorios, crear asignaciones, verificar persistencia
    - **Property 11: Cambio de tipo de asignación actualiza el registro** — Cambiar tipos de asignación, verificar que el registro se actualiza
    - **Property 12: Cambio de rol elimina la asignación de supervisor** — Cambiar rol de supervisor a otro, verificar que la asignación se elimina
    - **Property 13: Lista de asignaciones de supervisores es completa** — Crear N asignaciones, verificar que el endpoint retorna todas
    - **Validates: Requirements 4.2, 4.4, 8.2, 8.3, 8.4**

  - [ ]* 4.6 Escribir property tests para filtrado de leads del supervisor (jqwik)
    - **Property 5: Supervisor solo ve leads de su tipo de asignación** — Configurar supervisores con diferentes tipos, crear leads con diferentes campañas, verificar filtrado correcto
    - **Property 6: Búsqueda filtra dentro de leads asignados** — Generar términos de búsqueda aleatorios, verificar que resultados cumplen ambos criterios (término + asignación)
    - **Property 7: Actualización parcial modifica solo campos especificados** — Generar subconjuntos aleatorios de campos, aplicar actualización, verificar que solo esos campos cambian
    - **Property 8: Campos nulos/vacíos aceptados sin error de validación** — Generar requests con combinaciones aleatorias de campos nulos/vacíos, verificar HTTP 200
    - **Validates: Requirements 5.2, 5.4, 5.5, 6.2, 6.3, 6.4, 7.1**

- [x] 5. Backend controladores
  - [x] 5.1 Crear AssignmentTypeController con endpoints CRUD
    - Implementar `GET /api/assignment-types` — listar todos los tipos con conteo de supervisores
    - Implementar `GET /api/assignment-types/active` — listar solo tipos activos
    - Implementar `GET /api/assignment-types/{id}` — obtener tipo por ID
    - Implementar `POST /api/assignment-types` — crear nuevo tipo con validación
    - Implementar `PUT /api/assignment-types/{id}` — actualizar tipo existente
    - Implementar `DELETE /api/assignment-types/{id}` — eliminar tipo (rechazar si tiene supervisores)
    - Asegurar todos los endpoints con `@Secured("ROLE_ADMIN")`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [x] 5.2 Crear SupervisorAssignmentController
    - Implementar `GET /api/supervisor-assignments` — listar todas las asignaciones (ROLE_ADMIN)
    - Implementar `POST /api/supervisor-assignments` — crear asignación (ROLE_ADMIN)
    - Implementar `PUT /api/supervisor-assignments/{userId}` — cambiar tipo de asignación (ROLE_ADMIN)
    - Implementar `DELETE /api/supervisor-assignments/{userId}` — eliminar asignación (ROLE_ADMIN)
    - Implementar `GET /api/supervisor-assignments/me` — obtener mi asignación (ROLE_SUPERVISOR)
    - _Requirements: 4.2, 4.4, 8.1, 8.2, 8.3, 8.4_

  - [x] 5.3 Crear endpoints de leads para supervisor (extensión de LeadController o nuevo controlador)
    - Implementar `GET /api/supervisor/leads?page=X&size=Y` — leads filtrados por asignación del supervisor
    - Implementar `GET /api/supervisor/leads/search?term=X&page=Y&size=Z` — buscar en leads asignados
    - Implementar `GET /api/supervisor/leads/{id}` — detalle de un lead asignado (verificar pertenencia)
    - Implementar `PUT /api/supervisor/leads/{id}` — actualización parcial de lead (verificar pertenencia)
    - Asegurar todos los endpoints con `@Secured("ROLE_SUPERVISOR")`
    - _Requirements: 5.2, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

  - [ ]* 5.4 Escribir unit tests para controladores del backend
    - Test CRUD de AssignmentTypeController: códigos HTTP correctos (200, 201, 204, 400, 404, 409)
    - Test SupervisorAssignmentController: creación, actualización, eliminación
    - Test endpoints de leads para supervisor: filtrado, búsqueda, actualización parcial, acceso denegado
    - _Requirements: 2.1, 2.5, 5.5, 6.5, 6.6, 7.2, 7.3_

- [x] 6. Backend filtro de seguridad para supervisores
  - [x] 6.1 Crear SupervisorAccessFilter
    - Extender `OncePerRequestFilter`
    - Interceptar requests de usuarios con ROLE_SUPERVISOR
    - Bloquear POST y DELETE en `/api/leads/**` para supervisores → retornar 403
    - Verificar que PUT en `/api/supervisor/leads/{id}` solo accede a leads de su asignación
    - Registrar intentos de acceso no autorizado: `WARN [SupervisorAccessFilter] Unauthorized access: userId={}, endpoint={}, method={}, leadId={}`
    - _Requirements: 6.5, 6.6, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

  - [x] 6.2 Registrar SupervisorAccessFilter en la configuración de Spring Security
    - Agregar filtro a la cadena de seguridad después del filtro de autenticación
    - Asegurar que el filtro solo se ejecuta para requests autenticados
    - _Requirements: 7.1_

  - [ ]* 6.3 Escribir property tests para SupervisorAccessFilter (jqwik)
    - **Property 9: Supervisor no puede crear ni eliminar leads** — Para cualquier supervisor, verificar que POST y DELETE retornan 403
    - **Property 10: Supervisor solo puede actualizar leads de su asignación** — Crear leads dentro y fuera de la asignación, verificar que PUT solo funciona para los asignados
    - **Validates: Requirements 6.5, 6.6, 7.2, 7.3, 7.4, 7.5**

- [x] 7. Checkpoint - Backend completo
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Frontend modelos
  - [x] 8.1 Crear modelo AssignmentType
    - Crear `lib/models/assignment_type.dart` con campos: id, name, description, active, filterValue, supervisorCount, createdAt
    - Implementar factory constructor `fromJson`
    - Implementar método `toJson`
    - _Requirements: 2.2, 2.3_

  - [x] 8.2 Crear modelo SupervisorAssignment
    - Crear `lib/models/supervisor_assignment.dart` con campos: id, userId, userName, assignmentTypeId, assignmentTypeName, assignedAt
    - Implementar factory constructor `fromJson`
    - _Requirements: 4.4, 8.1_

  - [x] 8.3 Crear/extender modelo LeadModel para supervisor
    - Crear o extender `lib/models/lead_model.dart` con todos los campos del lead (todos opcionales/nullable)
    - Implementar factory constructor `fromJson`
    - Implementar método `toEditJson()` que solo incluye campos editables con valor no nulo
    - _Requirements: 5.3, 6.2_

- [x] 9. Frontend servicios
  - [x] 9.1 Crear AssignmentTypesService
    - Crear `lib/services/assignment_types_service.dart`
    - Implementar `getAll()` — GET /api/assignment-types
    - Implementar `getActive()` — GET /api/assignment-types/active
    - Implementar `create(AssignmentTypeRequest)` — POST /api/assignment-types
    - Implementar `update(int id, AssignmentTypeRequest)` — PUT /api/assignment-types/{id}
    - Implementar `delete(int id)` — DELETE /api/assignment-types/{id}
    - _Requirements: 2.1, 3.1, 3.4_

  - [x] 9.2 Crear SupervisorService
    - Crear `lib/services/supervisor_service.dart`
    - Implementar `getLeads({int page, int size})` — GET /api/supervisor/leads
    - Implementar `searchLeads({String term, int page, int size})` — GET /api/supervisor/leads/search
    - Implementar `getLeadById(int id)` — GET /api/supervisor/leads/{id}
    - Implementar `updateLead(int id, Map<String, dynamic> fields)` — PUT /api/supervisor/leads/{id}
    - Implementar `getMyAssignment()` — GET /api/supervisor-assignments/me
    - _Requirements: 5.2, 5.4, 6.1, 6.2, 6.7_

  - [x] 9.3 Crear SupervisorAssignmentsService (para admin)
    - Crear `lib/services/supervisor_assignments_service.dart`
    - Implementar `getAll()` — GET /api/supervisor-assignments
    - Implementar `create(SupervisorAssignmentRequest)` — POST /api/supervisor-assignments
    - Implementar `update(int userId, int assignmentTypeId)` — PUT /api/supervisor-assignments/{userId}
    - Implementar `delete(int userId)` — DELETE /api/supervisor-assignments/{userId}
    - _Requirements: 4.2, 8.2, 8.3, 8.4_

- [x] 10. Frontend BLoCs
  - [x] 10.1 Crear AssignmentTypesBloc
    - Crear `lib/features/admin/assignment_types/bloc/assignment_types_bloc.dart`
    - Definir events: LoadAssignmentTypes, CreateAssignmentType, UpdateAssignmentType, DeleteAssignmentType
    - Definir states: AssignmentTypesInitial, AssignmentTypesLoading, AssignmentTypesLoaded, AssignmentTypesError
    - Implementar event handlers llamando a AssignmentTypesService
    - Manejar errores con mensajes descriptivos
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 10.2 Crear SupervisorBloc
    - Crear `lib/features/supervisor/bloc/supervisor_bloc.dart`
    - Definir events: LoadSupervisorLeads, SearchSupervisorLeads, SelectLead, UpdateLead
    - Definir states: SupervisorInitial, SupervisorLoading, SupervisorLeadsLoaded, SupervisorLeadDetail, SupervisorLeadUpdated, SupervisorError
    - Implementar event handlers llamando a SupervisorService
    - Manejar paginación y estados de carga
    - _Requirements: 5.1, 5.2, 5.4, 6.1, 6.7_

  - [ ]* 10.3 Escribir unit tests para BLoCs
    - Test AssignmentTypesBloc: transiciones de estado para CRUD de tipos
    - Test SupervisorBloc: transiciones de estado para carga, búsqueda, edición de leads
    - _Requirements: 3.4, 3.5, 5.4, 6.7_

- [x] 11. Frontend pantallas de administración
  - [x] 11.1 Crear pantalla AssignmentTypesManagementScreen
    - Crear `lib/features/admin/assignment_types/screens/assignment_types_management_screen.dart`
    - Mostrar lista de tipos de asignación con nombre, descripción, estado y conteo de supervisores
    - Agregar botón "Crear nuevo tipo" con formulario (nombre, descripción, estado)
    - Agregar acciones de editar/eliminar por tipo (deshabilitar eliminar si supervisorCount > 0)
    - Usar design tokens: TBColors, TBTypography, TBSpacing
    - Mostrar estados de carga y snackbars de error/éxito
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 11.2 Crear RoleAssignmentDialog
    - Crear `lib/features/admin/users/widgets/role_assignment_dialog.dart`
    - Cargar tipos de asignación activos desde el backend al abrir el diálogo
    - Mostrar lista seleccionable con radio buttons
    - Botones "Confirmar" y "Cancelar"
    - Si no hay tipos activos, mostrar mensaje informativo y deshabilitar botón de confirmar
    - Al cancelar, revertir la selección del radio button al rol anterior
    - _Requirements: 4.1, 4.2, 4.3, 4.5_

  - [x] 11.3 Integrar RoleAssignmentDialog en la pantalla de gestión de usuarios
    - Modificar la pantalla de asignación de roles para detectar selección de ROLE_SUPERVISOR
    - Al seleccionar ROLE_SUPERVISOR, abrir RoleAssignmentDialog antes de confirmar
    - Enviar la asignación al backend solo si el diálogo se confirma
    - Si se cancela, revertir la selección del radio button
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 12. Checkpoint - Administración completa
  - Ensure all tests pass, ask the user if questions arise.

- [x] 13. Frontend Panel del Supervisor
  - [x] 13.1 Crear SupervisorPanel Screen
    - Crear `lib/features/supervisor/screens/supervisor_panel_screen.dart`
    - Header con información del tipo de asignación actual del supervisor
    - Tabla de leads con paginación mostrando: nombre, apellido, teléfono, email, país, campaña, estado de última llamada, comentarios
    - Campo de búsqueda para filtrar leads
    - Usar design tokens: TBColors, TBTypography, TBSpacing
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [x] 13.2 Crear formulario de edición de lead para supervisor
    - Crear `lib/features/supervisor/widgets/lead_edit_form.dart`
    - Mostrar todos los campos del lead en un formulario
    - Todos los campos son opcionales (sin validación de requeridos)
    - Al guardar, enviar solo los campos modificados (actualización parcial)
    - Mostrar mensaje de confirmación al guardar exitosamente
    - Mostrar mensaje de error si falla la actualización
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.7_

  - [x] 13.3 Integrar navegación del supervisor en el flujo de login
    - Modificar el flujo de login para detectar ROLE_SUPERVISOR
    - Redirigir al SupervisorPanel como vista principal cuando el usuario es supervisor
    - Asegurar que el supervisor no ve el panel administrativo
    - _Requirements: 1.4, 5.1_

  - [ ]* 13.4 Escribir widget tests para el Panel del Supervisor
    - Test renderizado de tabla de leads con datos mock
    - Test campo de búsqueda filtra correctamente
    - Test formulario de edición envía solo campos modificados
    - Test navegación correcta al login como supervisor
    - _Requirements: 5.1, 5.3, 5.4, 6.1, 6.7_

- [x] 14. Integración y wiring final
  - [x] 14.1 Registrar módulo SUPERVISOR_ASSIGNMENTS en la navegación del admin
    - Agregar entrada de menú "Tipos de Asignación" en el panel administrativo
    - Proteger con ModuleGuard usando código "SUPERVISOR_ASSIGNMENTS"
    - Configurar ruta hacia AssignmentTypesManagementScreen
    - _Requirements: 2.7, 3.1_

  - [x] 14.2 Integrar lógica de eliminación de asignación al cambiar rol
    - En el flujo de cambio de rol de usuario, si el usuario tenía ROLE_SUPERVISOR, eliminar su asignación
    - Llamar a `DELETE /api/supervisor-assignments/{userId}` cuando se cambia de ROLE_SUPERVISOR a otro rol
    - _Requirements: 8.3_

  - [x] 14.3 Mostrar tipo de asignación en detalle de usuario supervisor
    - En la pantalla de detalle/edición de usuario, si tiene ROLE_SUPERVISOR, mostrar su tipo de asignación actual
    - Permitir cambiar el tipo de asignación desde la vista de detalle
    - _Requirements: 8.1, 8.2_

  - [ ]* 14.4 Escribir integration tests para flujo end-to-end
    - Test: crear tipo de asignación → asignar supervisor → login como supervisor → ver leads filtrados → editar lead
    - Test: cambiar tipo de asignación → verificar que leads visibles cambian
    - Test: eliminar rol SUPERVISOR → verificar que asignación se elimina
    - Test: supervisor intenta crear/eliminar lead → verificar 403
    - Test: diálogo de asignación con/sin tipos activos
    - **Validates: Requirements 4.2, 5.2, 6.3, 7.2, 7.3, 7.4, 7.5, 8.2, 8.3**

- [x] 15. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using jqwik (backend Java)
- Unit tests validate specific examples and edge cases
- El backend usa Java (Spring Boot) y el frontend usa Dart (Flutter)
- Design system tokens (TBColors, TBTypography, TBSpacing) deben usarse consistentemente en todos los componentes UI
- El filtrado de leads se basa en el campo `campana` de la tabla `leads` vinculado al `filterValue` del tipo de asignación
- La actualización parcial de leads no requiere validación de campos obligatorios

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["2.1", "2.3", "2.4"] },
    { "id": 2, "tasks": ["2.2", "3.1"] },
    { "id": 3, "tasks": ["4.1", "4.2"] },
    { "id": 4, "tasks": ["4.3", "4.4", "4.5"] },
    { "id": 5, "tasks": ["4.6", "5.1", "5.2"] },
    { "id": 6, "tasks": ["5.3", "5.4", "8.1", "8.2", "8.3"] },
    { "id": 7, "tasks": ["6.1", "9.1", "9.2", "9.3"] },
    { "id": 8, "tasks": ["6.2", "6.3", "10.1", "10.2"] },
    { "id": 9, "tasks": ["10.3", "11.1", "11.2"] },
    { "id": 10, "tasks": ["11.3", "13.1"] },
    { "id": 11, "tasks": ["13.2", "13.3"] },
    { "id": 12, "tasks": ["13.4", "14.1", "14.2", "14.3"] },
    { "id": 13, "tasks": ["14.4"] }
  ]
}
```
