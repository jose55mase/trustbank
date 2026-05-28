# Implementation Plan: Granular Module Permissions

## Overview

This plan implements fine-grained action permissions and campaign-based visibility within the LEADS module. The backend (Spring Boot/Java) is implemented first to establish the API layer, followed by the frontend (Flutter/Dart) integration. Tasks are ordered so each step builds on the previous, with no orphaned code.

## Tasks

- [x] 1. Backend: Database schema and JPA entities
  - [x] 1.1 Create database migration for `role_module_permissions` and `role_campaign_visibility` tables
    - Create SQL migration file with both table definitions, unique constraints, indexes, and foreign keys
    - Include `role_module_permissions` table: id, role_id, module_id, action_code, enabled, created_at, updated_at
    - Include `role_campaign_visibility` table: id, role_id, campaign_id, created_at
    - _Requirements: 1.1, 1.2, 4.1_

  - [x] 1.2 Create `RoleModulePermissionEntity` JPA entity
    - Create entity class with `@Table`, `@UniqueConstraint`, `@ManyToOne` relationships to `RolEntity` and `ModuleEntity`
    - Include fields: id, role, module, actionCode, enabled (default true), createdAt, updatedAt
    - _Requirements: 1.1, 1.2_

  - [x] 1.3 Create `RoleCampaignVisibilityEntity` JPA entity
    - Create entity class with `@Table`, `@UniqueConstraint`, `@ManyToOne` relationships to `RolEntity` and `AssignmentTypeEntity`
    - Include fields: id, role, campaign, createdAt
    - _Requirements: 4.1_

  - [x] 1.4 Create `RoleModulePermissionRepository` (JPA Repository)
    - Define query methods: findByRoleIdAndModuleId, findByRoleIdAndModuleIdAndActionCode, deleteByRoleIdAndModuleId
    - _Requirements: 1.4_

  - [x] 1.5 Create `RoleCampaignVisibilityRepository` (JPA Repository)
    - Define query methods: findByRoleId, deleteByRoleId
    - _Requirements: 4.4_

- [x] 2. Backend: Permission service layer
  - [x] 2.1 Create DTOs for permission API responses and requests
    - Create `ActionPermissionDto` (actionCode, enabled)
    - Create `UserPermissionsDto` (moduleCode, actions map, visibleCampaignIds list)
    - Create `UpdateActionPermissionRequest` (moduleCode, actionCode, enabled)
    - Create `UpdateCampaignVisibilityRequest` (campaignIds list)
    - _Requirements: 7.1, 7.2_

  - [x] 2.2 Create `IPermissionService` interface
    - Define methods: getActionPermissions, updateActionPermission, initializeDefaultPermissions, deletePermissionsForRoleModule, hasActionPermission, getVisibleCampaignIds, updateCampaignVisibility, getUserVisibleCampaignIds, getUserPermissions
    - _Requirements: 1.4, 4.4, 7.1_

  - [x] 2.3 Implement `PermissionServiceImpl`
    - Implement `initializeDefaultPermissions`: create 6 action permission records with enabled=true for ASSIGN_ADVISOR, UNASSIGN_ADVISOR, IMPORT_EXCEL, EXPORT_EXCEL, EDIT_LEADS, DELETE_LEADS
    - Implement `updateActionPermission`: find by role+module+action, update enabled flag
    - Implement `deletePermissionsForRoleModule`: delete all permissions and campaign visibility for role-module
    - Implement `hasActionPermission`: resolve user's role, check permission record
    - Implement `getUserVisibleCampaignIds`: resolve user's role, return campaign IDs
    - Implement `getUserPermissions`: combine action permissions and campaign visibility into response DTO
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.4, 4.1, 4.2, 4.3, 7.1, 7.2_

  - [ ]* 2.4 Write property tests for permission service (Properties 1, 2, 3)
    - **Property 1: Permission Independence** — Generate random permission states, toggle one action, verify all other actions remain unchanged
    - **Property 2: Default Initialization** — Generate random role IDs, verify initialization produces exactly 6 enabled records
    - **Property 3: Action Permission Round-Trip** — Generate random permission maps, save and retrieve, verify equality
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.4**

  - [ ]* 2.5 Write unit tests for `PermissionServiceImpl`
    - Test initialization creates 6 records
    - Test update toggles single permission
    - Test deletion removes all records for role-module
    - Test getUserPermissions returns correct structure
    - _Requirements: 1.1, 1.2, 1.3, 2.4_

- [x] 3. Backend: Permission REST controller
  - [x] 3.1 Create `PermissionController` with endpoints
    - GET `/api/users/me/permissions?module=LEADS` — return current user's permissions
    - GET `/api/roles/{roleId}/permissions?module=LEADS` — return role's action permissions (admin)
    - PUT `/api/roles/{roleId}/permissions` — update single action permission (admin)
    - GET `/api/roles/{roleId}/campaign-visibility` — return role's campaign visibility (admin)
    - PUT `/api/roles/{roleId}/campaign-visibility` — update campaign visibility (admin)
    - _Requirements: 1.4, 4.4, 7.1, 7.2, 7.3_

  - [ ]* 3.2 Write property test for API enforcement (Property 6)
    - **Property 6: API Enforcement of Action Permissions** — Generate random user/action/permission-state combinations, verify 403 when disabled
    - **Validates: Requirements 3.8**

  - [ ]* 3.3 Write property test for response completeness (Property 12)
    - **Property 12: Permissions Response Completeness** — Generate random permission configurations, verify response contains exactly 6 action entries and a visibleCampaignIds list
    - **Validates: Requirements 7.2**

- [ ] 4. Backend: Module access filter extension
  - [x] 4.1 Extend `ModuleAccessFilter` with action-level permission checks
    - Add ACTION_ENDPOINT_MAP mapping HTTP method+path to action codes for LEADS module
    - After module access check passes, resolve action code from request and check permission
    - Return 403 with `ACTION_PERMISSION_DENIED` error if permission is disabled
    - _Requirements: 3.8_

  - [ ]* 4.2 Write unit tests for ModuleAccessFilter action mapping
    - Test each endpoint path maps to correct action code
    - Test 403 response when permission is disabled
    - Test pass-through when permission is enabled
    - _Requirements: 3.8_

- [x] 5. Backend: Campaign visibility filtering in leads queries
  - [x] 5.1 Extend `ILeadDao` with campaign-filtered query methods
    - Add `findByCampanaIn(List<String> campaigns, Pageable pageable)` method
    - Add `findByCampanaInAndAdvisorIsNull(List<String> campaigns, Pageable pageable)` method
    - _Requirements: 6.1, 6.3_

  - [x] 5.2 Modify leads service/controller to apply campaign filtering
    - Resolve user's visible campaign IDs from PermissionService
    - If campaign list is non-empty, use campaign-filtered DAO methods
    - If campaign list is empty, use existing unfiltered queries
    - Apply filtering to all leads list endpoints (paginated, search, unassigned)
    - _Requirements: 6.1, 6.2, 6.3_

  - [x] 5.3 Add direct lead access enforcement for campaign visibility
    - In lead detail/update/delete endpoints, check if lead's campana matches user's visible campaigns
    - Return 403 with `CAMPAIGN_ACCESS_DENIED` if lead is outside visible campaigns
    - _Requirements: 6.4_

  - [ ]* 5.4 Write property tests for campaign filtering (Properties 8, 9, 10)
    - **Property 8: Campaign Filtering Correctness** — Generate random lead sets with various campaigns, apply filter, verify all results match visible campaigns
    - **Property 9: Unrestricted Visibility Returns All Leads** — Generate random lead sets, verify no filtering when campaign set is empty
    - **Property 10: Campaign Filter Pagination Consistency** — Generate random lead sets and page sizes, verify total count matches filter
    - **Validates: Requirements 4.2, 4.3, 6.1, 6.2, 6.3**

- [x] 6. Backend: Hook permission lifecycle into role-module assignment
  - [x] 6.1 Modify role-module assignment logic to initialize permissions
    - When LEADS module is assigned to a role, call `initializeDefaultPermissions`
    - When LEADS module is removed from a role, call `deletePermissionsForRoleModule`
    - _Requirements: 1.3, 2.4_

  - [ ]* 6.2 Write property test for cleanup on module removal (Property 4)
    - **Property 4: Cleanup on Module Removal** — Generate roles with permissions and campaign visibility, remove module, verify zero records remain
    - **Validates: Requirements 2.4**

- [x] 7. Checkpoint - Backend complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Frontend: Permissions provider and data layer
  - [x] 8.1 Create `UserPermissions` model class
    - Define fields: actionPermissions (Map<String, bool>), visibleCampaignIds (List<int>)
    - Add convenience methods: canAssign(), canUnassign(), canImport(), canExport(), canEdit(), canDelete(), hasUnrestrictedVisibility()
    - _Requirements: 3.1, 7.2_

  - [x] 8.2 Create permissions API service
    - Implement `fetchUserPermissions(String moduleCode)` calling GET `/api/users/me/permissions?module=LEADS`
    - Implement `fetchRolePermissions(int roleId, String moduleCode)` for admin
    - Implement `updateActionPermission(int roleId, String moduleCode, String actionCode, bool enabled)`
    - Implement `fetchRoleCampaignVisibility(int roleId)`
    - Implement `updateCampaignVisibility(int roleId, List<int> campaignIds)`
    - _Requirements: 7.1, 2.2, 5.2_

  - [x] 8.3 Create `PermissionsProvider` (or BLoC) for session-level caching
    - Fetch permissions on initialization and cache for session
    - Expose `UserPermissions` to widgets
    - Refresh on navigation to Leads screen
    - Handle fetch failure: default to hiding all action buttons (fail-closed)
    - _Requirements: 3.1, 7.1_

- [x] 9. Frontend: Admin permissions configuration panel
  - [x] 9.1 Create `PermissionsConfigPanel` widget
    - Display checkboxes for each action: Asignar asesor, Desasignar, Importar Excel, Exportar Excel, Editar leads, Eliminar leads
    - Bind each checkbox to the role's action permission state
    - On toggle, call API to update permission and reflect saved state
    - Show error toast and revert on failure
    - _Requirements: 2.1, 2.2_

  - [x] 9.2 Create campaign visibility section in permissions panel
    - Display list of active campaigns with checkboxes
    - Load campaigns from existing assignment types API
    - Show indicator when no campaigns are selected (unrestricted access)
    - On change, call API to update campaign visibility
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [x] 9.3 Integrate permissions panel into `RolesManagementScreen`
    - Show permissions panel when a role has the LEADS module assigned
    - Hide permissions panel when LEADS module is not assigned
    - _Requirements: 2.1, 2.3_

- [x] 10. Frontend: Leads screen permission enforcement
  - [x] 10.1 Modify `LeadsListScreen` to conditionally render action buttons
    - Read permissions from `PermissionsProvider`
    - Conditionally show/hide: "Asignar a Asesor" button (canAssign), "Desasignar" button (canUnassign), "Importar" button (canImport), "Exportar" button (canExport)
    - Conditionally show/hide edit and delete functionality in lead detail panel
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

  - [ ]* 10.2 Write widget tests for LeadsListScreen permission enforcement
    - **Property 5: Button Visibility Matches Permission State** — Test that each button's visibility equals its permission enabled state
    - Test all buttons hidden when all permissions disabled
    - Test all buttons visible when all permissions enabled
    - Test individual button visibility for each permission
    - **Validates: Requirements 3.2, 3.3, 3.4, 3.5, 3.6, 3.7**

- [ ] 11. Frontend: Campaign visibility integration in leads queries
  - [x] 11.1 Ensure leads list respects campaign filtering from backend
    - Verify that the existing leads list API calls work correctly with backend campaign filtering (no frontend query changes needed since filtering is server-side)
    - Confirm pagination and search results are consistent with filtered data
    - _Requirements: 6.1, 6.2, 6.3_

- [x] 12. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Backend tasks (1-7) must be completed before frontend tasks (8-12)
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using jqwik (Java) for backend
- Frontend widget tests validate UI behavior with mocked permissions
- Campaign filtering is enforced at the database query level (backend), so the frontend simply consumes filtered results
- The `ModuleAccessFilter` extension ensures API-level enforcement regardless of frontend behavior

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.3"] },
    { "id": 2, "tasks": ["1.4", "1.5"] },
    { "id": 3, "tasks": ["2.1", "2.2"] },
    { "id": 4, "tasks": ["2.3"] },
    { "id": 5, "tasks": ["2.4", "2.5", "3.1"] },
    { "id": 6, "tasks": ["3.2", "3.3", "4.1", "5.1"] },
    { "id": 7, "tasks": ["4.2", "5.2"] },
    { "id": 8, "tasks": ["5.3", "6.1"] },
    { "id": 9, "tasks": ["5.4", "6.2"] },
    { "id": 10, "tasks": ["8.1", "8.2"] },
    { "id": 11, "tasks": ["8.3"] },
    { "id": 12, "tasks": ["9.1", "9.2"] },
    { "id": 13, "tasks": ["9.3", "10.1", "11.1"] },
    { "id": 14, "tasks": ["10.2"] }
  ]
}
```
