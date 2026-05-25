# Implementation Plan: Asignación Directa de Leads a Asesores

## Overview

Este plan implementa el cambio del sistema de filtrado de leads por campaña a un modelo de asignación directa lead → asesor. Se modifica el backend Spring Boot para agregar `advisor_id` a la tabla `leads`, se crean nuevos endpoints de administración para asignación masiva, y se actualiza el frontend Flutter con UI de gestión de asignaciones.

## Tasks

- [x] 1. Backend: Schema y Entity modifications
  - [x] 1.1 Add `advisor_id` column to LeadEntity and create DB migration
    - Add `@ManyToOne` relationship to `UserEntity` in `LeadEntity.java` with `@JoinColumn(name = "advisor_id", nullable = true)`
    - Create SQL migration script: `ALTER TABLE leads ADD COLUMN advisor_id BIGINT NULL`, FK constraint, and index
    - Add getter/setter for the `advisor` field
    - _Requirements: 1.1, 1.2, 1.3, 1.5_

  - [x] 1.2 Add new repository methods to ILeadDao
    - Add `findByAdvisorId(Long advisorId, Pageable pageable)` method
    - Add `findByAdvisorIsNull(Pageable pageable)` method
    - Add `searchByAdvisorIdAndTerm` with `@Query` annotation for search within advisor's leads
    - Add `countByAdvisorId` query method
    - Add `bulkAssign` and `bulkUnassign` `@Modifying` query methods
    - _Requirements: 1.1, 2.6, 4.2, 5.1, 5.5_

- [x] 2. Backend: Modify SupervisorLeadServiceImpl for direct assignment
  - [x] 2.1 Refactor SupervisorLeadServiceImpl to filter by advisor_id
    - Change `findLeadsBySupervisor` to use `leadDao.findByAdvisorId(userId, pageable)` instead of `findByCampana`
    - Change `searchLeadsBySupervisor` to use `leadDao.searchByAdvisorIdAndTerm(userId, term, pageable)` instead of `searchByCampanaAndTerm`
    - Change `isLeadInSupervisorAssignment` to check `lead.getAdvisor() != null && lead.getAdvisor().getId().equals(userId)`
    - Remove dependency on `ISupervisorAssignmentDao` and `getFilterValueForSupervisor` method
    - Update `updateLeadPartial` to use the new ownership check
    - _Requirements: 5.1, 5.2, 6.1, 6.2, 6.3, 6.4_

  - [ ]* 2.2 Write unit tests for SupervisorLeadServiceImpl
    - Test that `findLeadsBySupervisor` returns only leads with matching `advisor_id`
    - Test that `isLeadInSupervisorAssignment` returns false for leads assigned to other advisors
    - Test that `updateLeadPartial` throws exception for unauthorized access
    - _Requirements: 5.1, 6.1, 6.3_

- [x] 3. Backend: Create DTOs for assignment operations
  - [x] 3.1 Create request/response DTOs for lead assignment
    - Create `LeadAssignmentRequest` with `leadIds` (List<Long>) and `advisorId` (Long) with validation annotations
    - Create `LeadUnassignRequest` with `leadIds` (List<Long>)
    - Create `LeadReassignRequest` with `fromAdvisorId`, `toAdvisorId`, and `leadIds`
    - Create `AssignmentResultDTO` with `assignedCount`, `advisorName`, `advisorEmail`, `failedLeadIds`
    - Create `AdvisorSummaryDTO` with `advisorId`, `advisorName`, `advisorEmail`, `assignedLeadCount`
    - _Requirements: 2.3, 2.4, 2.6, 3.5, 7.1, 7.2_

- [x] 4. Backend: Create LeadAssignmentService
  - [x] 4.1 Implement LeadAssignmentService with core assignment logic
    - Create `LeadAssignmentService` class with `@Service` annotation
    - Implement `assignLeads(List<Long> leadIds, Long advisorId)` — validates advisor role, performs bulk update, returns result
    - Implement `unassignLeads(List<Long> leadIds)` — sets advisor_id to null
    - Implement `reassignLeads(Long fromAdvisorId, Long toAdvisorId, List<Long> leadIds)` — validates both advisors, performs reassignment
    - Implement `getAdvisorSummary()` — queries all ROLE_SUPERVISOR users with lead counts
    - Implement private `validateAdvisorRole(Long userId)` — checks user exists and has ROLE_SUPERVISOR
    - _Requirements: 1.4, 2.3, 2.6, 3.3, 3.4, 3.5, 7.1_

  - [ ]* 4.2 Write unit tests for LeadAssignmentService
    - Test `assignLeads` validates advisor has ROLE_SUPERVISOR
    - Test `assignLeads` returns correct count and handles non-existent lead IDs
    - Test `unassignLeads` sets advisor_id to null
    - Test `reassignLeads` validates both advisors
    - Test `getAdvisorSummary` includes advisors with 0 leads
    - _Requirements: 1.4, 2.3, 3.3, 7.3_

- [x] 5. Backend: Create LeadAssignmentController
  - [x] 5.1 Implement LeadAssignmentController with admin endpoints
    - Create `LeadAssignmentController` with `@RequestMapping("/api/admin/leads")`
    - Implement `POST /api/admin/leads/assign` — secured with ROLE_ADMIN, calls `assignLeads`
    - Implement `POST /api/admin/leads/unassign` — secured with ROLE_ADMIN, calls `unassignLeads`
    - Implement `POST /api/admin/leads/reassign` — secured with ROLE_ADMIN, calls `reassignLeads`
    - Implement `GET /api/admin/advisors/summary` — secured with ROLE_ADMIN, calls `getAdvisorSummary`
    - Implement `GET /api/admin/advisors/{advisorId}/leads` — secured with ROLE_ADMIN, returns paginated leads for advisor
    - Add proper error handling and response codes
    - _Requirements: 2.6, 3.5, 7.1, 7.4_

  - [ ]* 5.2 Write integration tests for LeadAssignmentController
    - Test assign endpoint with valid data returns 200 and correct count
    - Test assign endpoint with invalid advisor (non-SUPERVISOR) returns 400
    - Test unassign endpoint sets advisor_id to null
    - Test reassign endpoint updates advisor correctly
    - Test advisor summary returns all supervisors with counts
    - Test endpoints require ROLE_ADMIN authentication
    - _Requirements: 2.3, 2.6, 3.3, 3.5, 7.1_

- [x] 6. Backend: Add unassigned leads filter to existing admin lead list
  - [x] 6.1 Add unassigned filter parameter to admin lead list endpoint
    - Modify existing admin leads GET endpoint to accept optional `unassigned=true` query parameter
    - When `unassigned=true`, use `leadDao.findByAdvisorIsNull(pageable)` to return only unassigned leads
    - Add optional `advisorId` filter parameter to filter leads by specific advisor
    - Ensure the `advisor` field is serialized in lead JSON responses (advisor name for display)
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 7. Checkpoint - Backend complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Frontend: Create Flutter models for assignment
  - [x] 8.1 Create AssignmentResult and AdvisorSummary models
    - Create `lib/features/admin/leads/models/assignment_result.dart` with `fromJson` factory
    - Create `lib/features/admin/leads/models/advisor_summary.dart` with `fromJson` factory
    - _Requirements: 2.4, 7.2_

  - [x] 8.2 Modify LeadModel to include advisor fields
    - Add `advisorId` (int?) and `advisorName` (String?) fields to `LeadModel`
    - Update `fromJson` to parse `advisor` object (extract id and nombre/apellido)
    - Update `toJson` and `copyWith` methods
    - _Requirements: 3.1, 4.3_

- [x] 9. Frontend: Create LeadAssignmentService (Flutter)
  - [x] 9.1 Implement LeadAssignmentService for API calls
    - Create `lib/features/admin/leads/services/lead_assignment_service.dart`
    - Implement `assignLeads({required List<int> leadIds, required int advisorId})` → POST /api/admin/leads/assign
    - Implement `unassignLeads(List<int> leadIds)` → POST /api/admin/leads/unassign
    - Implement `reassignLeads({required int fromAdvisorId, required int toAdvisorId, required List<int> leadIds})` → POST /api/admin/leads/reassign
    - Implement `getAdvisorSummary()` → GET /api/admin/advisors/summary
    - Implement `getAdvisorLeads(int advisorId, {int page, int size})` → GET /api/admin/advisors/{advisorId}/leads
    - Use existing auth token pattern from other services in the project
    - _Requirements: 2.1, 2.6, 3.5, 7.1, 7.4_

- [x] 10. Frontend: Create AssignAdvisorDialog widget
  - [x] 10.1 Implement AssignAdvisorDialog for bulk assignment
    - Create `lib/features/admin/leads/widgets/assign_advisor_dialog.dart`
    - Load list of active advisors (ROLE_SUPERVISOR users) from advisor summary endpoint
    - Show dropdown/selector with advisor name and email
    - Display count of selected leads and warning if any already have an advisor assigned
    - Implement confirm/cancel buttons
    - On confirm, call `LeadAssignmentService.assignLeads` and return result
    - Show success snackbar with assigned count and advisor name
    - _Requirements: 2.1, 2.2, 2.4, 2.5_

- [x] 11. Frontend: Create AdvisorSummaryPanel widget
  - [x] 11.1 Implement AdvisorSummaryPanel for admin dashboard
    - Create `lib/features/admin/leads/widgets/advisor_summary_panel.dart`
    - Display table with columns: Nombre, Email, Leads Asignados
    - Load data from `LeadAssignmentService.getAdvisorSummary()`
    - Include advisors with 0 leads in the list
    - On advisor row click, navigate/filter to show that advisor's leads
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 12. Frontend: Modify Admin Lead List for assignment management
  - [x] 12.1 Add advisor column and selection checkboxes to admin lead table
    - Add "Asesor" column to the leads DataTable showing advisor name or "Sin asignar"
    - Add checkbox column for multi-select of leads
    - Add "Select All" checkbox in header
    - Track selected lead IDs in state
    - Add visual indicator (badge/color) for unassigned leads
    - _Requirements: 3.1, 4.3_

  - [x] 12.2 Add assignment action buttons and filter dropdown
    - Add "Asignar a Asesor" button (enabled when leads are selected)
    - Add "Desasignar" button for removing advisor from selected leads
    - Add filter dropdown: "Todos", "Sin asignar", or specific advisor
    - On "Asignar" click, show `AssignAdvisorDialog` with selected lead IDs
    - On filter change, reload leads with appropriate query parameter
    - Refresh table after successful assignment/unassignment
    - _Requirements: 2.1, 2.5, 3.2, 3.4, 4.1_

- [x] 13. Frontend: Update SupervisorPanel for direct assignment model
  - [x] 13.1 Update supervisor panel to handle no-assignment state gracefully
    - Remove dependency on `NoAssignmentConfiguredException` handling (no longer relevant)
    - Show "No tienes leads asignados actualmente" message when API returns empty page
    - Display total lead count in panel header
    - Ensure search still works within advisor's assigned leads
    - _Requirements: 5.3, 5.4_

- [x] 14. Final checkpoint - Full integration
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The backend changes (tasks 1-6) should be completed before frontend changes (tasks 8-13)
- The `SupervisorLeadServiceImpl` refactor (task 2.1) is the critical change that switches the filtering mechanism
- The existing `AssignmentTypeEntity` and `SupervisorAssignmentEntity` tables are NOT deleted — they remain for potential secondary use
- The `campana` field on leads is NOT removed — it remains as metadata from Excel imports
- Property-based tests are not included as the design does not define correctness properties

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "3.1"] },
    { "id": 1, "tasks": ["1.2", "8.1"] },
    { "id": 2, "tasks": ["2.1", "4.1", "8.2"] },
    { "id": 3, "tasks": ["2.2", "4.2", "5.1", "9.1"] },
    { "id": 4, "tasks": ["5.2", "6.1", "10.1"] },
    { "id": 5, "tasks": ["11.1", "12.1"] },
    { "id": 6, "tasks": ["12.2", "13.1"] }
  ]
}
```
