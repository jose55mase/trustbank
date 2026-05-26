# Implementation Plan: Flutter Portfolio CMS

## Overview

This plan implements a Flutter web portfolio with integrated CMS, structured as a module within the existing `delivery_app` project. The implementation progresses from core infrastructure (models, repositories, theme) through public-facing components (carousel, catalog, navigation) to the admin panel (auth, project management, content editing), with property-based tests validating correctness properties throughout.

## Tasks

- [x] 1. Set up portfolio module structure and core models
  - [x] 1.1 Create directory structure and domain models
    - Create `lib/portfolio/` module with subdirectories: `models/`, `repositories/`, `providers/`, `screens/`, `widgets/`, `theme/`
    - Implement `PortfolioProject`, `CarouselItem`, `EditableContent`, and `ContentType` model classes with serialization (toJson/fromJson)
    - Implement `PortfolioAuthState` model class
    - Implement `OperationResult` sealed class with `Success` and `Failure` subtypes, and `FailureType` enum
    - _Requirements: 2.1, 3.1, 5.1, 4.1_

  - [x] 1.2 Create repository interfaces and Firebase implementations
    - Define `PortfolioProjectRepository` abstract class with all CRUD and query methods
    - Define `EditableContentRepository` abstract class with content query and update methods
    - Define `ImageStorageRepository` abstract class with upload, delete, and validate methods
    - Implement `FirebaseProjectRepository` using Firestore collection `portfolio_projects/`
    - Implement `FirebaseContentRepository` using Firestore collection `editable_content/`
    - Implement `FirebaseImageStorageRepository` using Firebase Storage path `portfolio/`
    - _Requirements: 5.1, 5.2, 6.1, 6.2, 6.3_

  - [x] 1.3 Create Riverpod providers for portfolio state
    - Implement `projectRepositoryProvider`, `contentRepositoryProvider`, `imageStorageProvider`
    - Implement `allProjectsProvider` (StreamProvider) and `featuredProjectsProvider` (StreamProvider)
    - Implement `editableContentProvider` (StreamProvider.family by section)
    - Implement `portfolioAuthProvider` (StateNotifierProvider) with `PortfolioAuthNotifier`
    - _Requirements: 2.1, 3.1, 4.1, 6.1_

- [x] 2. Implement portfolio theme and responsive layout
  - [x] 2.1 Create PortfolioTheme with pastel color palette
    - Define HSL-based color constants: primary blue (H:210, S:40%, L:75%), secondary orange (H:25, S:45%, L:75%), accent black (H:0, S:2%, L:20%)
    - Create `PortfolioTheme` class with Material 3 `ThemeData` using the pastel palette
    - Implement contrast-checking utility that falls back to accent color when WCAG AA ratio is not met
    - Define text styles, button styles, and surface colors derived from the three color roles
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

  - [x]* 2.2 Write property test for WCAG contrast compliance
    - **Property 15: Theme WCAG contrast compliance**
    - **Validates: Requirements 7.5**

  - [x] 2.3 Create responsive layout scaffold and breakpoint utilities
    - Implement `PortfolioResponsiveLayout` widget with breakpoints: mobile (<768px), tablet (768-1024px), desktop (>1024px)
    - Implement max content width of 1200px centered for desktop, margins of 24px for tablet
    - Ensure no horizontal scrolling and images maintain aspect ratio within containers
    - _Requirements: 8.1, 8.2, 8.3, 8.5_

  - [x]* 2.4 Write property test for touch target minimum size
    - **Property 16: Touch target minimum size**
    - **Validates: Requirements 8.1**

- [x] 3. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implement navigation and routing
  - [x] 4.1 Configure GoRouter with portfolio routes and auth guard
    - Add portfolio public routes: `/portfolio`, `/portfolio/project/:id`
    - Add admin routes: `/portfolio/admin`, `/portfolio/admin/login`, `/portfolio/admin/projects`, `/portfolio/admin/content`
    - Implement auth guard redirect that sends unauthenticated users to login, preserving return URL
    - Implement session expiry check (60 min inactivity) in the guard
    - _Requirements: 1.1, 4.3, 4.4_

  - [x]* 4.2 Write property test for auth guard redirect
    - **Property 9: Auth guard redirect**
    - **Validates: Requirements 4.3, 4.4**

  - [x] 4.3 Implement PortfolioNavBar widget
    - Create fixed-position navigation bar with links to all public sections
    - Implement smooth scroll animation (300-500ms) when a nav link is selected
    - Implement hamburger menu collapse for screens < 768px with expand/collapse panel
    - Apply portfolio theme colors to the navigation bar
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 5. Implement interactive carousel
  - [x] 5.1 Build InteractiveCarousel widget
    - Create carousel that displays only projects with `isFeatured == true`
    - Implement swipe gestures and navigation buttons for manual advance
    - Implement auto-advance every 5 seconds with timer reset on user interaction
    - Implement cyclic navigation: after last item, return to first
    - Display title (max 60 chars), description (max 200 chars), and image with entry animations (≤400ms)
    - Show position indicator (current/total)
    - Implement fallback placeholder when image fails to load (primary color background + project title)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [x]* 5.2 Write property test for carousel featured filter
    - **Property 1: Carousel displays exactly featured projects**
    - **Validates: Requirements 2.1**

  - [x]* 5.3 Write property test for carousel text truncation
    - **Property 2: Carousel text truncation**
    - **Validates: Requirements 2.3**

  - [x]* 5.4 Write property test for cyclic carousel advance
    - **Property 3: Cyclic carousel advance**
    - **Validates: Requirements 2.4**

  - [x]* 5.5 Write property test for carousel position indicator
    - **Property 4: Carousel position indicator correctness**
    - **Validates: Requirements 2.7**

- [x] 6. Implement project catalog and detail view
  - [x] 6.1 Build ProjectCatalog widget
    - Display all projects in a responsive grid (single column <768px, multi-column ≥768px)
    - Show title, truncated description (max 150 chars), and main image per project
    - Show empty state message when no projects exist
    - Implement image fallback placeholder on load failure
    - Navigate to project detail on selection
    - _Requirements: 3.1, 3.2, 3.4, 3.5, 3.6, 3.7_

  - [x]* 6.2 Write property test for catalog completeness
    - **Property 5: Catalog completeness**
    - **Validates: Requirements 3.1**

  - [x]* 6.3 Write property test for catalog description truncation
    - **Property 6: Catalog description truncation**
    - **Validates: Requirements 3.2**

  - [x] 6.4 Build ProjectDetailView widget
    - Display full project title, untruncated description, all images (main + additional), technologies, and external link
    - Implement responsive image gallery
    - _Requirements: 3.3_

  - [x]* 6.5 Write property test for project detail view completeness
    - **Property 7: Project detail view completeness**
    - **Validates: Requirements 3.3**

- [x] 7. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Implement authentication system
  - [x] 8.1 Implement PortfolioAuthNotifier with login/lockout logic
    - Implement login method that validates credentials via Firebase Auth
    - Return generic error message on failure (not revealing which field is wrong)
    - Track consecutive failed attempts; lock account for 15 minutes after 5 failures
    - Reset failure counter on successful login
    - Implement session expiry after 60 minutes of inactivity
    - _Requirements: 4.1, 4.2, 4.4, 4.5_

  - [x]* 8.2 Write property test for authentication correctness
    - **Property 8: Authentication correctness**
    - **Validates: Requirements 4.1, 4.2**

  - [x]* 8.3 Write property test for account lockout
    - **Property 10: Account lockout after consecutive failures**
    - **Validates: Requirements 4.5**

  - [x] 8.4 Build PortfolioLoginScreen                              
    - Create login form with username and password fields
    - Display generic error messages on failure
    - Display lockout countdown when account is locked
    - Redirect to original route after successful login
    - _Requirements: 4.1, 4.2, 4.3, 4.5_

- [x] 9. Implement admin project management
  - [x] 9.1 Build AdminProjectForm for create/edit
    - Create form with fields: title (max 100 chars), description (max 500 chars), main image upload, additional images (max 5), external link, technologies, isFeatured toggle
    - Implement field validation: required fields flagged with inline error messages, preserve other field values on validation failure
    - Implement image validation: accept only PNG/JPG/WebP, max 5MB per file
    - On successful save, project appears in catalog without manual reload (via StreamProvider)
    - _Requirements: 5.1, 5.2, 5.3, 5.5, 5.6_

  - [x]* 9.2 Write property test for project data round-trip
    - **Property 11: Project data round-trip**
    - **Validates: Requirements 5.2, 5.3**

  - [x]* 9.3 Write property test for required field validation
    - **Property 12: Required field validation**
    - **Validates: Requirements 5.5, 6.6**

  - [x]* 9.4 Write property test for image validation
    - **Property 13: Image validation**
    - **Validates: Requirements 6.3, 6.4**

  - [x] 9.5 Implement project deletion with confirmation dialog
    - Show confirmation dialog with project title before deletion
    - Remove project from Firestore and associated images from Storage
    - Show error message and preserve state on failure
    - _Requirements: 5.4, 5.6_

- [x] 10. Implement content editing panel
  - [x] 10.1 Build ContentEditorPanel for editable content management
    - List all editable content items organized by section (hero, about, footer, etc.)
    - Implement inline text/title editing with save functionality
    - Implement image replacement with format/size validation (PNG/JPG/WebP, ≤5MB)
    - Reflect changes in public page within 5 seconds via StreamProvider
    - Validate required fields are not empty/whitespace-only
    - Show error message and preserve edited content on save failure
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.6, 6.7_

  - [x] 10.2 Implement carousel content editing
    - Allow editing carousel item title (max 100 chars), description (max 300 chars), and image
    - Validate character limits and reject inputs exceeding them
    - _Requirements: 6.5_

  - [x]* 10.3 Write property test for content field length validation
    - **Property 14: Content field length validation**
    - **Validates: Requirements 6.5**

- [x] 11. Integration and wiring
  - [x] 11.1 Wire portfolio module into main app
    - Register portfolio routes in the main GoRouter configuration
    - Add portfolio providers to the main ProviderScope
    - Ensure portfolio theme is applied only to portfolio routes (not affecting delivery app)
    - _Requirements: 1.1, 7.4_

  - [x] 11.2 Implement cross-browser compatibility verification
    - Ensure all widgets render correctly without functional differences across Chrome, Firefox, Safari, and Edge
    - Verify no horizontal overflow on any breakpoint
    - Verify images scale maintaining aspect ratio
    - _Requirements: 8.4, 8.5_

  - [x]* 11.3 Write integration tests for project CRUD flow
    - Test full flow: login → create project → verify in catalog → edit → delete
    - Test content editing and verification in public page
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2_

- [x] 12. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using Glados (already in project dependencies)
- Unit tests validate specific examples and edge cases
- The portfolio module is isolated from the existing delivery app code
- All 16 correctness properties from the design document are covered by property test tasks

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.3"] },
    { "id": 2, "tasks": ["2.1", "2.3"] },
    { "id": 3, "tasks": ["2.2", "2.4", "4.1", "4.3"] },
    { "id": 4, "tasks": ["4.2", "5.1"] },
    { "id": 5, "tasks": ["5.2", "5.3", "5.4", "5.5", "6.1", "6.4"] },
    { "id": 6, "tasks": ["6.2", "6.3", "6.5", "8.1"] },
    { "id": 7, "tasks": ["8.2", "8.3", "8.4"] },
    { "id": 8, "tasks": ["9.1", "9.5"] },
    { "id": 9, "tasks": ["9.2", "9.3", "9.4", "10.1"] },
    { "id": 10, "tasks": ["10.2"] },
    { "id": 11, "tasks": ["10.3", "11.1"] },
    { "id": 12, "tasks": ["11.2", "11.3"] }
  ]
}
```
