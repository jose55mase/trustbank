# Implementation Plan: Protected Lead Comments

## Overview

This plan implements a protected, author-tracked commenting system for the Leads module. The backend (Spring Boot / Java) is built first — database migration, entity, DAO, service, controller — followed by the Flutter frontend. The existing `comentarios` field is never modified (non-destructive migration).

## Tasks

- [x] 1. Database migration and JPA entity
  - [x] 1.1 Create the SQL migration script for `lead_comments` table
    - Add a new SQL migration file (e.g., `V__create_lead_comments_table.sql` or `import.sql` addition) that creates the `lead_comments` table with all columns, foreign keys, and indexes as specified in the design
    - Include `ON DELETE CASCADE` for `lead_id` and `ON DELETE RESTRICT` for `user_id`
    - DO NOT touch the existing `comentarios` column
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [x] 1.2 Create `LeadCommentEntity` JPA entity class
    - Create `LeadCommentEntity.java` in `com.bolsadeideas.springboot.backend.apirest.models.entity`
    - Map to `lead_comments` table with fields: `id`, `leadId`, `user` (ManyToOne to UserEntity), `text`, `createdAt`, `editedAt`
    - Add `@PrePersist` to auto-set `createdAt`
    - Use `@JsonIgnoreProperties` on the user relation to avoid serialization cycles
    - _Requirements: 1.1_

- [x] 2. Repository and service layer
  - [x] 2.1 Create `ILeadCommentDao` repository interface
    - Create `ILeadCommentDao.java` in `com.bolsadeideas.springboot.backend.apirest.models.dao`
    - Extend `JpaRepository<LeadCommentEntity, Long>`
    - Add query method: `findByLeadIdOrderByCreatedAtAsc(Long leadId)`
    - _Requirements: 5.3_

  - [x] 2.2 Create `ILeadCommentService` service interface
    - Create `ILeadCommentService.java` in `com.bolsadeideas.springboot.backend.apirest.models.services`
    - Define methods: `findByLeadId`, `create`, `update`, `delete`
    - _Requirements: 2.1, 3.1, 4.1, 5.1_

  - [x] 2.3 Create `LeadCommentServiceImpl` service implementation
    - Create `LeadCommentServiceImpl.java` in `com.bolsadeideas.springboot.backend.apirest.models.services`
    - Implement `create`: validate lead exists via `ILeadDao`, persist with userId
    - Implement `update`: fetch comment, validate ownership (`comment.user.id == userId`), update text and set `editedAt`
    - Implement `delete`: fetch comment, validate ownership, remove from DB
    - Throw `ResourceNotFoundException` (404) when lead/comment not found
    - Throw `ForbiddenOperationException` (403) when ownership mismatch
    - _Requirements: 2.1, 2.4, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4_

  - [x] 2.4 Create custom exception classes
    - Create `ResourceNotFoundException.java` in `com.bolsadeideas.springboot.backend.apirest.exceptions` (if not already present)
    - Create `ForbiddenOperationException.java` in `com.bolsadeideas.springboot.backend.apirest.exceptions`
    - _Requirements: 3.2, 4.2, 2.4, 4.4_

- [x] 3. REST controller
  - [x] 3.1 Create `LeadCommentController` REST controller
    - Create `LeadCommentController.java` in `com.bolsadeideas.springboot.backend.apirest.controllers`
    - Base path: `/api/leads/{leadId}/comments`
    - Implement `GET` — returns legacy comment (from `ILeadDao`) + authored comments
    - Implement `POST` — extracts userId from `SecurityContextHolder`, validates `@NotBlank` and `@Size(max=2000)` on text, delegates to service
    - Implement `PUT /{commentId}` — validates text, delegates to service with ownership check
    - Implement `DELETE /{commentId}` — delegates to service with ownership check
    - Return proper HTTP status codes: 201 on create, 204 on delete, 400/403/404 on errors
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 8.1, 8.2, 8.3_

  - [x] 3.2 Create DTO for the GET response
    - Create a response DTO class (or build inline map) that structures the response as `{ legacyComment: {...}, comments: [...] }`
    - Include `authorName` field composed from user's firstName + lastName
    - Mark legacy comment with `isLegacy: true` and no author
    - _Requirements: 5.2, 5.4, 7.2_

- [x] 4. Checkpoint - Backend API complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Backend tests
  - [ ]* 5.1 Write property test: Ownership enforcement on mutations (Property 1)
    - **Property 1: Ownership enforcement on mutations**
    - Generate random (ownerUserId, requesterUserId) pairs where owner ≠ requester; verify edit/delete rejected with 403 and comment unchanged
    - Use jqwik library with @Property annotation
    - **Validates: Requirements 3.1, 3.2, 4.1, 4.2, 8.3**

  - [ ]* 5.2 Write property test: Whitespace-only text rejection (Property 2)
    - **Property 2: Whitespace-only text rejection**
    - Generate random whitespace-only strings (spaces, tabs, newlines); verify create and edit return 400 with no DB change
    - **Validates: Requirements 2.2, 3.4**

  - [ ]* 5.3 Write property test: Over-length text rejection (Property 3)
    - **Property 3: Over-length text rejection**
    - Generate random strings with length 2001–10000; verify create returns 400 and no comment persisted
    - **Validates: Requirements 2.3**

  - [ ]* 5.4 Write property test: Create preserves author identity (Property 4)
    - **Property 4: Create preserves author identity**
    - Generate random valid text + userId pairs; verify created entity has correct userId and non-null createdAt
    - **Validates: Requirements 2.1**

  - [ ]* 5.5 Write property test: Delete removes permanently (Property 5)
    - **Property 5: Delete removes permanently**
    - Generate comments, delete as owner, verify not found in repository
    - **Validates: Requirements 4.3**

  - [ ]* 5.6 Write property test: Edit updates text and sets edited timestamp (Property 6)
    - **Property 6: Edit updates text and sets edited timestamp**
    - Generate existing comments + new valid text; verify edit returns updated text and non-null editedAt with unchanged createdAt
    - **Validates: Requirements 3.3**

  - [ ]* 5.7 Write property test: List returns complete ordered results (Property 7)
    - **Property 7: List returns complete ordered results**
    - Generate leads with N random comments; verify list returns exactly N items in createdAt ASC order with legacy comment first if present
    - **Validates: Requirements 5.1, 5.3, 7.1**

  - [ ]* 5.8 Write property test: Author information present in responses (Property 8)
    - **Property 8: Author information present in responses**
    - Generate comments by different users; verify authorName is present and matches user's firstName + lastName
    - **Validates: Requirements 5.4, 7.2**

  - [ ]* 5.9 Write unit tests for LeadCommentController
    - Test 404 when lead does not exist on create
    - Test 404 when comment does not exist on delete
    - Test legacy comment has `isLegacy: true` and no author in GET response
    - Test legacy comment omitted when `comentarios` is null/empty
    - Test user ID correctly extracted from SecurityContextHolder
    - _Requirements: 2.4, 4.4, 5.2, 6.2, 6.3, 8.2_

- [x] 6. Checkpoint - Backend tests complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Frontend model and API service
  - [x] 7.1 Create `LeadCommentModel` Dart model
    - Create `lead_comment_model.dart` in `lib/features/admin/leads/models/`
    - Fields: `id`, `leadId`, `userId`, `authorName`, `text`, `createdAt`, `editedAt`, `isLegacy`
    - Implement `fromJson` factory constructor and `toJson` method
    - Implement `copyWith` for immutable updates
    - _Requirements: 5.4, 7.2, 7.3_

  - [x] 7.2 Create `LeadCommentsApiService` HTTP service
    - Create `lead_comments_service.dart` in `lib/features/admin/leads/services/`
    - Follow existing `LeadsService` static method pattern
    - Implement: `getComments(int leadId)`, `createComment(int leadId, String text)`, `updateComment(int leadId, int commentId, String text)`, `deleteComment(int leadId, int commentId)`
    - Include JWT token in Authorization header from stored auth state
    - _Requirements: 2.1, 3.1, 4.1, 5.1, 8.1_

- [x] 8. Frontend BLoC state management
  - [x] 8.1 Create `LeadCommentsBloc` with events and states
    - Create `lead_comments_bloc.dart`, `lead_comments_event.dart`, `lead_comments_state.dart` in `lib/features/admin/leads/bloc/`
    - Events: `LoadComments`, `AddComment`, `EditComment`, `DeleteComment`
    - States: `CommentsInitial`, `CommentsLoading`, `CommentsLoaded`, `CommentsError`
    - Handle API calls and emit corresponding states
    - Handle error responses (400, 403, 404) with appropriate error messages
    - _Requirements: 2.1, 3.1, 4.1, 5.1_

- [x] 9. Frontend UI widgets
  - [x] 9.1 Create `CommentsSection` widget
    - Create `comments_section.dart` in `lib/features/admin/leads/widgets/`
    - Display legacy comment first (if exists) with "Legacy" badge, no edit/delete controls
    - Display authored comments in chronological order (oldest first)
    - Show author name, creation timestamp, and "editado" badge when `editedAt` is non-null
    - Show edit/delete action buttons ONLY on comments where `userId` matches the current logged-in user
    - Provide text input field and submit button at the bottom for new comments
    - Wire to `LeadCommentsBloc` for event dispatching and state rendering
    - _Requirements: 6.2, 6.3, 7.1, 7.2, 7.3, 7.4, 7.5_

  - [x] 9.2 Integrate `CommentsSection` into Lead Detail Panel
    - Modify `lead_detail_screen.dart` to include the `CommentsSection` widget
    - Provide `LeadCommentsBloc` via `BlocProvider` with the lead's ID
    - Dispatch `LoadComments` event on screen initialization
    - _Requirements: 5.1, 7.1_

- [x] 10. Frontend error handling and polish
  - [x] 10.1 Implement frontend error handling
    - Show snackbar with retry option on network errors
    - Show inline validation message for 400 errors (blank/over-length text)
    - Show "No tienes permiso" dialog for 403 errors
    - Refresh comments list on 404 errors (stale data)
    - Redirect to login on 401 errors
    - _Requirements: 8.1_

  - [ ]* 10.2 Write unit tests for LeadCommentModel and BLoC
    - Test `LeadCommentModel.fromJson` correctly parses all fields including nullable ones
    - Test BLoC emits correct states on successful operations
    - Test BLoC emits error states on API failures
    - Use `bloc_test` and `mockito` packages
    - _Requirements: 5.4, 7.2, 7.3_

- [x] 11. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests use jqwik (JUnit 5 compatible PBT library for Java)
- The backend is at `/Users/ojc04152/Desktop/dev/trustbank/spring-boot-backend-apirest/`
- The frontend is at `/Users/ojc04152/Desktop/dev/trustbank/payment_receipt_app/`
- Backend package root: `com.bolsadeideas.springboot.backend.apirest`
- The existing `comentarios` field on the `leads` table is NEVER modified by this implementation

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "2.4"] },
    { "id": 1, "tasks": ["1.2"] },
    { "id": 2, "tasks": ["2.1", "2.2"] },
    { "id": 3, "tasks": ["2.3"] },
    { "id": 4, "tasks": ["3.1", "3.2"] },
    { "id": 5, "tasks": ["5.1", "5.2", "5.3", "5.4", "5.5", "5.6", "5.7", "5.8", "5.9"] },
    { "id": 6, "tasks": ["7.1"] },
    { "id": 7, "tasks": ["7.2"] },
    { "id": 8, "tasks": ["8.1"] },
    { "id": 9, "tasks": ["9.1"] },
    { "id": 10, "tasks": ["9.2", "10.1"] },
    { "id": 11, "tasks": ["10.2"] }
  ]
}
```
