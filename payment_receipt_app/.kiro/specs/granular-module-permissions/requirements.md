# Requirements Document

## Introduction

This feature extends the existing role-based module system in TrustBank to support granular permissions within the LEADS module. Currently, assigning a module to a role grants full access to all features within that module. This feature allows administrators to configure fine-grained action permissions (assign, unassign, import, export, edit, delete) and campaign-based visibility restrictions per role, enabling more precise access control over lead management operations.

## Glossary

- **Permission_System**: The backend service responsible for storing, retrieving, and evaluating granular permissions for role-module combinations.
- **Admin_UI**: The Flutter web frontend screens used by administrators to configure roles, modules, and permissions.
- **Leads_UI**: The Flutter web frontend screen where users view and manage leads, with action buttons controlled by permissions.
- **Role**: A named entity (stored in `rolsbank` table) that groups users and defines their access to modules and permissions.
- **Module**: A functional area of the application (stored in `modules` table) such as LEADS, DOCUMENTS, etc.
- **Action_Permission**: A boolean flag that controls whether a role can perform a specific action within a module (e.g., assign advisor, export Excel).
- **Campaign**: An assignment type (stored in `assignment_types` table) used to categorize leads and restrict visibility per role.
- **Role_Module_Permission**: A database record linking a role, a module, and a specific action permission with an enabled/disabled state.
- **Role_Campaign_Visibility**: A database record linking a role to one or more campaigns, restricting which leads are visible to users with that role.

## Requirements

### Requirement 1: Store Action Permissions

**User Story:** As an administrator, I want to define which actions each role can perform within the LEADS module, so that I can restrict sensitive operations to authorized roles only.

#### Acceptance Criteria

1. WHEN a role has the LEADS module assigned, THE Permission_System SHALL store individual action permissions for: assign advisor, unassign advisor, import Excel, export Excel, edit leads, and delete leads.
2. THE Permission_System SHALL represent each action permission as an independent boolean value per role-module combination.
3. WHEN a new role-module assignment is created for the LEADS module, THE Permission_System SHALL initialize all action permissions to enabled (true) by default.
4. THE Permission_System SHALL persist action permissions in the database and load them via a REST API endpoint.

### Requirement 2: Configure Action Permissions via Admin UI

**User Story:** As an administrator, I want to toggle individual action permissions on or off for each role in the LEADS module, so that I can customize access without creating multiple roles.

#### Acceptance Criteria

1. WHEN the administrator selects a role that has the LEADS module assigned, THE Admin_UI SHALL display a permissions configuration panel with checkboxes for each action: Asignar asesor, Desasignar, Importar Excel, Exportar Excel, Editar leads, and Eliminar leads.
2. WHEN the administrator toggles an action permission checkbox, THE Admin_UI SHALL send an update request to the Permission_System and reflect the saved state.
3. WHILE the LEADS module is not assigned to a role, THE Admin_UI SHALL hide the permissions configuration panel for that role.
4. WHEN the LEADS module is removed from a role, THE Permission_System SHALL delete all associated action permissions for that role-module combination.

### Requirement 3: Enforce Action Permissions in Leads UI

**User Story:** As a user with a restricted role, I want to only see the action buttons I am authorized to use, so that I have a clear and uncluttered interface.

#### Acceptance Criteria

1. WHEN a user accesses the Leads screen, THE Leads_UI SHALL retrieve the user's action permissions for the LEADS module from the Permission_System.
2. WHILE the "assign advisor" permission is disabled for the user's role, THE Leads_UI SHALL hide the "Asignar a Asesor" button.
3. WHILE the "unassign advisor" permission is disabled for the user's role, THE Leads_UI SHALL hide the "Desasignar" button.
4. WHILE the "import Excel" permission is disabled for the user's role, THE Leads_UI SHALL hide the "Importar" button.
5. WHILE the "export Excel" permission is disabled for the user's role, THE Leads_UI SHALL hide the "Exportar" button.
6. WHILE the "edit leads" permission is disabled for the user's role, THE Leads_UI SHALL hide lead editing functionality (detail panel save button and inline editing).
7. WHILE the "delete leads" permission is disabled for the user's role, THE Leads_UI SHALL hide the "Eliminar" button in the detail panel.
8. IF a user attempts to perform a restricted action via direct API call, THEN THE Permission_System SHALL reject the request with a 403 Forbidden response.

### Requirement 4: Store Campaign-Based Visibility

**User Story:** As an administrator, I want to assign specific campaigns to a role, so that users with that role can only see leads belonging to those campaigns.

#### Acceptance Criteria

1. THE Permission_System SHALL store a many-to-many relationship between roles and campaigns for visibility filtering.
2. WHEN no campaigns are assigned to a role, THE Permission_System SHALL treat the role as having unrestricted lead visibility (all leads are visible).
3. WHEN one or more campaigns are assigned to a role, THE Permission_System SHALL restrict lead visibility to only leads belonging to those assigned campaigns.
4. THE Permission_System SHALL persist campaign visibility assignments in the database and expose them via a REST API endpoint.

### Requirement 5: Configure Campaign Visibility via Admin UI

**User Story:** As an administrator, I want to select which campaigns a role can see in the LEADS module, so that I can segment lead access by campaign.

#### Acceptance Criteria

1. WHEN the administrator selects a role that has the LEADS module assigned, THE Admin_UI SHALL display a campaign visibility section listing all active campaigns with checkboxes.
2. WHEN the administrator checks or unchecks a campaign, THE Admin_UI SHALL update the role-campaign visibility assignment in the Permission_System.
3. WHILE no campaigns are selected for a role, THE Admin_UI SHALL display an indicator that the role has access to all leads.
4. THE Admin_UI SHALL load the list of available campaigns from the existing assignment types API endpoint.

### Requirement 6: Enforce Campaign-Based Visibility in Leads Queries

**User Story:** As a user with campaign-restricted visibility, I want to only see leads from my assigned campaigns, so that I focus on relevant prospects.

#### Acceptance Criteria

1. WHEN a user with campaign restrictions requests the leads list, THE Permission_System SHALL filter the query results to include only leads belonging to the user's assigned campaigns.
2. WHEN a user with no campaign restrictions requests the leads list, THE Permission_System SHALL return all leads without campaign filtering.
3. THE Permission_System SHALL apply campaign filtering at the database query level to ensure consistent pagination and search results.
4. IF a user attempts to access a lead outside their assigned campaigns via direct API call, THEN THE Permission_System SHALL reject the request with a 403 Forbidden response.

### Requirement 7: Permissions API Endpoint

**User Story:** As a frontend developer, I want a single API endpoint that returns all permissions for the current user's role, so that the UI can efficiently determine what to show or hide.

#### Acceptance Criteria

1. THE Permission_System SHALL expose a GET endpoint that returns the current user's action permissions and campaign visibility for the LEADS module.
2. WHEN the endpoint is called, THE Permission_System SHALL return a response containing: the list of action permissions with their enabled/disabled state, and the list of assigned campaign IDs (empty list means unrestricted).
3. THE Permission_System SHALL respond within 200ms for permission retrieval requests under normal load.
