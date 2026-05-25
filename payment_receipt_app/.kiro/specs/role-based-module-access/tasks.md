# Implementation Plan: Role-Based Module Access

## Overview

Implementación del sistema dinámico de acceso a módulos basado en roles para TrustBank. Se reemplaza el sistema estático de permisos (enum `Permission` + mapa `RolePermissions`) por uno dinámico gestionado desde la base de datos. El plan sigue un enfoque incremental: primero la capa de datos, luego el backend (entidades → servicios → controlador → seguridad), después el frontend (modelos → servicios → BLoC → UI), y finalmente la integración.

## Tasks

- [x] 1. Database schema and seed data
  - [x] 1.1 Create SQL migration for modules table and role_modules junction table
    - Create `modules` table with columns: id, code, name, description, icon, display_order
    - Create `role_modules` junction table with composite PK (role_id, module_id) and foreign keys to `rolsbank` and `modules`
    - Add seed data for the 5 initial modules: LEADS, DOCUMENTS, DOCUMENT_APPROVAL, USER_MANAGEMENT, ROLE_MANAGEMENT
    - _Requirements: 6.1, 6.2_

- [x] 2. Backend entities and repositories
  - [x] 2.1 Create ModuleEntity JPA entity
    - Create `ModuleEntity` class in `models.entity` package with fields: id, code, name, description, icon, displayOrder
    - Add JPA annotations: `@Entity`, `@Table(name = "modules")`, `@Column` constraints (unique code, not-null name)
    - Implement `Serializable`
    - _Requirements: 6.2, 6.4_

  - [x] 2.2 Extend RolEntity with modules relationship
    - Add `@ManyToMany(fetch = FetchType.EAGER)` relationship to `ModuleEntity`
    - Configure `@JoinTable` with name "role_modules", join/inverse join columns
    - Add getter/setter for modules `Set<ModuleEntity>`
    - _Requirements: 2.1, 2.5_

  - [x] 2.3 Create IModuleDao repository interface
    - Create `IModuleDao` extending `JpaRepository<ModuleEntity, Long>`
    - Add `findByCode(String code)` method
    - Add `findAllByOrderByDisplayOrderAsc()` method
    - _Requirements: 6.3_

  - [x] 2.4 Add user count query to IRolDao
    - Add custom query method to count users per role: `@Query("SELECT COUNT(u) FROM UserEntity u JOIN u.roles r WHERE r.id = :roleId")`
    - _Requirements: 5.2_

- [x] 3. Backend DTOs
  - [x] 3.1 Create request and response DTOs for roles and modules
    - Create `RolRequest` with `@NotBlank`, `@Size(min=3, max=50)`, `@Pattern` validation
    - Create `RoleModulesRequest` with `@NotNull List<Long> moduleIds`
    - Create `RolResponse` (id, name, modules list, userCount)
    - Create `ModuleResponse` (id, code, name, description, icon, displayOrder)
    - Create `RoleConfigResponse` (roleId, roleName, list of ModuleAssignmentResponse)
    - Create `ModuleAssignmentResponse` (moduleId, code, name, description, icon, assigned boolean)
    - _Requirements: 1.6, 2.3, 5.2_

- [x] 4. Backend services
  - [x] 4.1 Create ModuleService
    - Implement `findAll()` returning all modules ordered by displayOrder
    - Implement `findById(Long id)` with proper exception handling
    - Implement `findByCode(String code)`
    - _Requirements: 6.3_

  - [x] 4.2 Create RolService with CRUD operations
    - Implement `findAll()` returning roles with user counts
    - Implement `findById(Long id)` with 404 handling
    - Implement `create(RolRequest)` with duplicate name validation
    - Implement `update(Long id, RolRequest)` with duplicate name validation
    - Implement `delete(Long id)` with user-assignment check (reject if users > 0)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

  - [x] 4.3 Implement module assignment logic in RolService
    - Implement `updateRoleModules(Long roleId, List<Long> moduleIds)` for batch module assignment
    - Implement `getRoleConfig(Long roleId)` returning all modules with assigned status
    - Implement `getUserModules(Long userId)` returning modules for the user's role
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x]* 4.4 Write property tests for RolService (jqwik)
    - **Property 1: Role Creation Round-Trip** — Generate valid random names, create roles, verify persistence
    - **Property 2: Role Name Validation** — Generate random strings, verify only valid ones are accepted
    - **Property 3: Duplicate Role Name Rejection** — Create role, attempt duplicate, verify rejection
    - **Validates: Requirements 1.1, 1.2, 1.6**

  - [x]* 4.5 Write property tests for module assignment (jqwik)
    - **Property 5: Module Assignment Round-Trip** — Assign random subsets of modules, verify query returns exactly those
    - **Property 6: Module Configuration Query Completeness** — For any role, verify query returns ALL catalog modules
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4**

  - [x]* 4.6 Write property tests for role deletion (jqwik)
    - **Property 4: Role Deletion Depends on User Assignment** — Create roles with/without users, verify only those without users can be deleted
    - **Validates: Requirements 1.4, 1.5**

- [x] 5. Backend controller
  - [x] 5.1 Create RolController with all CRUD endpoints
    - Implement `GET /api/roles` — list all roles with user counts
    - Implement `GET /api/roles/{id}` — get role with modules
    - Implement `POST /api/roles` — create new role with validation
    - Implement `PUT /api/roles/{id}` — update role name
    - Implement `DELETE /api/roles/{id}` — delete role (reject if has users)
    - Implement `PUT /api/roles/{id}/modules` — batch assign modules to role
    - Implement `GET /api/modules` — list module catalog
    - Implement `GET /api/users/me/modules` — get current user's allowed modules
    - Secure all endpoints with `@Secured("ROLE_ADMIN")` except `/api/users/me/modules`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 6.3, 4.1, 7.3_

  - [x]* 5.2 Write unit tests for RolController
    - Test successful CRUD operations return correct HTTP codes (200, 201, 204)
    - Test validation errors return 400
    - Test role not found returns 404
    - Test delete role with users returns 409
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 6. Backend security filter
  - [x] 6.1 Create ModuleAccessFilter
    - Extend `OncePerRequestFilter`
    - Define URL-to-module mapping: `/api/leads/**` → LEADS, `/api/documents/**` → DOCUMENTS, etc.
    - Extract user from SecurityContext, load user's role modules
    - If endpoint requires a module the user's role doesn't have, return 403 with error body
    - Log unauthorized access attempts: `WARN [ModuleAccessFilter] userId={}, endpoint={}, requiredModule={}`
    - Skip filter for `/api/users/me/modules` and `/api/roles/**` (handled by @Secured)
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [x] 6.2 Register ModuleAccessFilter in Spring Security configuration
    - Add filter to the security filter chain after authentication filter
    - Ensure filter runs only for authenticated requests
    - _Requirements: 7.1_

  - [x]* 6.3 Write property tests for ModuleAccessFilter (jqwik)
    - **Property 11: Route Guard Denies Unassigned Modules** — Verify requests to endpoints without assigned module return 403
    - **Property 10: User Sees Only Assigned Modules** — Configure roles with random modules, verify endpoint returns only assigned
    - **Validates: Requirements 7.1, 7.2, 4.1**

- [x] 7. Checkpoint - Backend complete
  - Ensure all backend tests pass, ask the user if questions arise.

- [x] 8. Frontend models
  - [x] 8.1 Create ModulePermission model
    - Create `lib/models/module_permission.dart` with fields: id, code, name, description, icon, displayOrder
    - Implement `fromJson` factory constructor
    - Implement `toJson` method
    - _Requirements: 4.1, 6.2_

  - [x] 8.2 Create RoleModel
    - Create `lib/models/role_model.dart` with fields: id, name, modules (List<ModulePermission>), userCount
    - Implement `fromJson` factory constructor
    - Implement `toJson` method
    - _Requirements: 5.2_

- [x] 9. Frontend services
  - [x] 9.1 Create PermissionService (singleton)
    - Create `lib/services/permission_service.dart`
    - Implement singleton pattern
    - Implement `loadPermissions()` — calls `GET /api/users/me/modules` and stores result
    - Implement `hasModuleAccess(String moduleCode)` — checks if module is in allowed list
    - Implement `allowedModules` getter
    - Implement `clear()` for logout
    - _Requirements: 4.1, 4.2_

  - [x] 9.2 Create RolesService for admin API calls
    - Create `lib/features/admin/roles/services/roles_service.dart`
    - Implement `getRoles()` — GET /api/roles
    - Implement `getRoleById(int id)` — GET /api/roles/{id}
    - Implement `createRole(String name)` — POST /api/roles
    - Implement `updateRole(int id, String name)` — PUT /api/roles/{id}
    - Implement `deleteRole(int id)` — DELETE /api/roles/{id}
    - Implement `updateRoleModules(int roleId, List<int> moduleIds)` — PUT /api/roles/{id}/modules
    - Implement `getModules()` — GET /api/modules
    - _Requirements: 1.1, 1.3, 1.4, 2.1, 2.2, 2.4, 6.3_

  - [x] 9.3 Integrate PermissionService into login flow
    - After successful login in AuthBloc, call `PermissionService().loadPermissions()`
    - On logout, call `PermissionService().clear()`
    - _Requirements: 4.1_

- [x] 10. Frontend BLoC
  - [x] 10.1 Create RolesBloc with events and states
    - Create `lib/features/admin/roles/bloc/roles_bloc.dart`
    - Define events: LoadRoles, CreateRole, UpdateRole, DeleteRole, UpdateRoleModules
    - Define states: RolesInitial, RolesLoading, RolesLoaded (roles + allModules), RolesError
    - Implement event handlers calling RolesService
    - Handle errors with descriptive messages
    - _Requirements: 5.1, 5.4, 5.5_

  - [x]* 10.2 Write unit tests for RolesBloc
    - Test LoadRoles emits RolesLoading then RolesLoaded
    - Test CreateRole with valid name succeeds
    - Test DeleteRole with users shows error
    - Test UpdateRoleModules updates correctly
    - _Requirements: 5.4, 5.5_

- [x] 11. Frontend screens
  - [x] 11.1 Create RolesManagementScreen
    - Create `lib/features/admin/roles/screens/roles_management_screen.dart`
    - Display list of roles with name and user count using TBTypography and TBColors
    - Add "Create Role" button with name input dialog (validate 3-50 chars)
    - Add edit/delete actions per role (disable delete if userCount > 0)
    - Add module assignment view: show all modules with toggles/checkboxes per role
    - Use TBSpacing for consistent layout
    - Show loading states and error snackbars
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 11.2 Update AdminDashboard to use PermissionService for module visibility
    - Replace hardcoded module list with `PermissionService().allowedModules`
    - Render only modules the user has access to
    - Add "Gestión de Roles" menu item (visible only if user has ROLE_MANAGEMENT module)
    - _Requirements: 4.2_

- [x] 12. Frontend ModuleGuard widget
  - [x] 12.1 Create ModuleGuard widget replacing RoleGuard
    - Create `lib/widgets/module_guard.dart`
    - Accept `requiredModule` (String code) and `child` widget
    - Accept optional `fallback` widget (default: redirect to dashboard with "Acceso denegado" message)
    - Use `PermissionService().hasModuleAccess(moduleCode)` for access check
    - _Requirements: 4.2, 4.3_

  - [x] 12.2 Replace RoleGuard usages with ModuleGuard across the app
    - Find all existing `RoleGuard` widget usages
    - Replace with `ModuleGuard` using appropriate module codes
    - Update route definitions to use ModuleGuard for protected routes
    - _Requirements: 4.3_

  - [x]* 12.3 Write widget tests for ModuleGuard
    - Test renders child when module is assigned
    - Test renders fallback/redirect when module is not assigned
    - Test handles edge case of empty permissions list
    - _Requirements: 4.2, 4.3_

- [x] 13. Checkpoint - Frontend complete
  - Ensure all frontend tests pass, ask the user if questions arise.

- [x] 14. Integration and wiring
  - [x] 14.1 Wire default role assignment for new user registration
    - In the user registration flow, ensure new users get the default role assigned automatically
    - Verify the default role exists in the system
    - _Requirements: 3.1, 3.4_

  - [x] 14.2 Add role change functionality to user management
    - Add endpoint or extend existing user update to allow changing a user's role
    - Validate that the target role exists before assignment
    - _Requirements: 3.2, 3.3, 3.4_

  - [x]* 14.3 Write integration tests for end-to-end flow
    - Test: create role → assign modules → assign to user → login → verify only assigned modules returned
    - Test: modify role modules → next login reflects changes
    - Test: access endpoint without module → 403
    - **Property 8: User Role Assignment Round-Trip**
    - **Property 9: Invalid Role Assignment Rejection**
    - **Property 12: Roles List Shows Correct User Counts**
    - **Validates: Requirements 3.2, 3.3, 3.4, 4.4, 5.2, 7.1, 7.2**

- [x] 15. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using jqwik (backend) and dart test (frontend)
- Unit tests validate specific examples and edge cases
- The backend uses Java (Spring Boot) and the frontend uses Dart (Flutter)
- Design system tokens (TBColors, TBTypography, TBSpacing) should be used consistently in all UI components

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["2.1", "2.3", "2.4"] },
    { "id": 2, "tasks": ["2.2", "3.1"] },
    { "id": 3, "tasks": ["4.1", "4.2"] },
    { "id": 4, "tasks": ["4.3", "4.4", "4.5", "4.6"] },
    { "id": 5, "tasks": ["5.1", "8.1", "8.2"] },
    { "id": 6, "tasks": ["5.2", "6.1", "9.1", "9.2"] },
    { "id": 7, "tasks": ["6.2", "6.3", "9.3"] },
    { "id": 8, "tasks": ["10.1"] },
    { "id": 9, "tasks": ["10.2", "11.1", "11.2"] },
    { "id": 10, "tasks": ["12.1"] },
    { "id": 11, "tasks": ["12.2", "12.3"] },
    { "id": 12, "tasks": ["14.1", "14.2"] },
    { "id": 13, "tasks": ["14.3"] }
  ]
}
```
