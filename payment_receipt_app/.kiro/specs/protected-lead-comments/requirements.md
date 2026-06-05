# Requirements Document

## Introduction

This feature introduces a protected comments system for the Leads module in the admin panel. Currently, lead comments are stored as a single plain-text field (`comentarios` VARCHAR(2000)) in the `leads` table. The new system adds a dedicated `lead_comments` table with user authorship, enabling comment ownership enforcement: only the author of a comment can edit or delete it. Existing legacy data in the `comentarios` field remains untouched and read-only.

## Glossary

- **Lead_Comments_Service**: The backend service responsible for creating, reading, updating, and deleting authored comments in the `lead_comments` table.
- **Lead_Comments_Controller**: The REST API controller that exposes endpoints for managing lead comments.
- **Comment_Entity**: A JPA entity representing a single authored comment in the `lead_comments` table, with fields: id, lead_id, user_id, text, created_at, edited_at.
- **Authenticated_User**: The currently logged-in user identified via the JWT token in the request.
- **Legacy_Comment**: The existing plain-text value stored in the `comentarios` field of the `leads` table, which has no associated author.
- **Lead_Detail_Panel**: The Flutter frontend panel that displays a lead's full details, including comments.
- **Comments_Section**: The UI section within the Lead_Detail_Panel that renders both legacy and authored comments in chronological order.

## Requirements

### Requirement 1: Database Schema for Authored Comments

**User Story:** As a system administrator, I want a dedicated table for authored comments, so that each comment is traceable to its author and manageable independently.

#### Acceptance Criteria

1. THE Lead_Comments_Service SHALL persist comments in a `lead_comments` table with columns: `id` (BIGINT, auto-increment, primary key), `lead_id` (BIGINT, foreign key to `leads.id`, NOT NULL), `user_id` (BIGINT, foreign key to `usersbank.id`, NOT NULL), `text` (VARCHAR(2000), NOT NULL), `created_at` (TIMESTAMP, NOT NULL), `edited_at` (TIMESTAMP, nullable).
2. THE Lead_Comments_Service SHALL enforce a foreign key constraint from `lead_comments.lead_id` to `leads.id`.
3. THE Lead_Comments_Service SHALL enforce a foreign key constraint from `lead_comments.user_id` to `usersbank.id`.
4. THE Lead_Comments_Service SHALL NOT modify, delete, or alter the existing `comentarios` column in the `leads` table during migration.

### Requirement 2: Create a Comment

**User Story:** As an admin panel user, I want to add a comment to a lead, so that my observations and notes are recorded with my identity.

#### Acceptance Criteria

1. WHEN the Authenticated_User submits a new comment for a lead, THE Lead_Comments_Controller SHALL create a Comment_Entity with the `user_id` set to the Authenticated_User's ID and `created_at` set to the current server timestamp.
2. WHEN the Authenticated_User submits a comment with empty or blank text, THE Lead_Comments_Controller SHALL reject the request with a 400 status code and a descriptive error message.
3. WHEN the Authenticated_User submits a comment with text exceeding 2000 characters, THE Lead_Comments_Controller SHALL reject the request with a 400 status code and a descriptive error message.
4. WHEN the Authenticated_User submits a comment for a lead that does not exist, THE Lead_Comments_Controller SHALL reject the request with a 404 status code.

### Requirement 3: Edit a Comment

**User Story:** As a comment author, I want to edit my own comment, so that I can correct mistakes or update information.

#### Acceptance Criteria

1. WHEN the Authenticated_User requests to edit a Comment_Entity, THE Lead_Comments_Controller SHALL verify that the Comment_Entity's `user_id` matches the Authenticated_User's ID.
2. IF the Authenticated_User's ID does not match the Comment_Entity's `user_id`, THEN THE Lead_Comments_Controller SHALL reject the request with a 403 status code and a message indicating insufficient permissions.
3. WHEN the Authenticated_User successfully edits a Comment_Entity, THE Lead_Comments_Service SHALL update the `text` field and set `edited_at` to the current server timestamp.
4. WHEN the Authenticated_User submits an edit with empty or blank text, THE Lead_Comments_Controller SHALL reject the request with a 400 status code and a descriptive error message.

### Requirement 4: Delete a Comment

**User Story:** As a comment author, I want to delete my own comment, so that I can remove information that is no longer relevant.

#### Acceptance Criteria

1. WHEN the Authenticated_User requests to delete a Comment_Entity, THE Lead_Comments_Controller SHALL verify that the Comment_Entity's `user_id` matches the Authenticated_User's ID.
2. IF the Authenticated_User's ID does not match the Comment_Entity's `user_id`, THEN THE Lead_Comments_Controller SHALL reject the request with a 403 status code and a message indicating insufficient permissions.
3. WHEN the Authenticated_User successfully deletes a Comment_Entity, THE Lead_Comments_Service SHALL remove the Comment_Entity from the database permanently.
4. WHEN the Authenticated_User requests to delete a Comment_Entity that does not exist, THE Lead_Comments_Controller SHALL return a 404 status code.

### Requirement 5: List Comments for a Lead

**User Story:** As an admin panel user, I want to see all comments for a lead, so that I can review the full comment history.

#### Acceptance Criteria

1. WHEN the Authenticated_User requests comments for a specific lead, THE Lead_Comments_Controller SHALL return the Legacy_Comment (if non-null and non-empty) and all Comment_Entity records associated with that lead.
2. THE Lead_Comments_Controller SHALL return the Legacy_Comment as a separate field marked with no author and no editable/deletable capabilities.
3. THE Lead_Comments_Controller SHALL return Comment_Entity records ordered by `created_at` in ascending order.
4. THE Lead_Comments_Controller SHALL include the author's name (first name and last name) in each Comment_Entity response.

### Requirement 6: Legacy Comment Preservation

**User Story:** As a system administrator, I want existing comments preserved and visible, so that historical data is not lost.

#### Acceptance Criteria

1. THE Lead_Comments_Service SHALL NOT provide any endpoint to modify or delete the `comentarios` field value in the `leads` table.
2. WHEN a lead has a non-empty `comentarios` value, THE Lead_Detail_Panel SHALL display the Legacy_Comment as a read-only entry with a "Legacy" label and no edit or delete controls.
3. WHEN a lead has a null or empty `comentarios` value, THE Lead_Detail_Panel SHALL NOT display a Legacy_Comment entry.

### Requirement 7: Frontend Comments Display

**User Story:** As an admin panel user, I want to see all comments in a unified, chronological view, so that I can follow the conversation history for a lead.

#### Acceptance Criteria

1. THE Comments_Section SHALL display the Legacy_Comment first (if it exists), followed by authored comments in chronological order (oldest first).
2. THE Comments_Section SHALL display the author name and creation timestamp for each authored comment.
3. WHEN a Comment_Entity has a non-null `edited_at` value, THE Comments_Section SHALL display an "edited" indicator alongside the comment.
4. THE Comments_Section SHALL display edit and delete action controls only on comments where the `user_id` matches the currently logged-in user's ID.
5. THE Comments_Section SHALL provide a text input field and submit button to allow the Authenticated_User to create new comments.

### Requirement 8: Authorization Enforcement

**User Story:** As a system administrator, I want comment operations protected by authentication, so that anonymous users cannot create, edit, or delete comments.

#### Acceptance Criteria

1. IF a request to create, edit, or delete a comment does not include a valid authentication token, THEN THE Lead_Comments_Controller SHALL reject the request with a 401 status code.
2. THE Lead_Comments_Controller SHALL extract the Authenticated_User's ID from the JWT token for all write operations.
3. THE Lead_Comments_Controller SHALL NOT allow any user to edit or delete a Comment_Entity authored by a different user, regardless of that user's role.
