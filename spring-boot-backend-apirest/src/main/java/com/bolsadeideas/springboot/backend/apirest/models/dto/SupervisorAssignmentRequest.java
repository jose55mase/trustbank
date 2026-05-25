package com.bolsadeideas.springboot.backend.apirest.models.dto;

import javax.validation.constraints.NotNull;

/**
 * Request DTO para crear una asignación de supervisor a un tipo de asignación.
 */
public class SupervisorAssignmentRequest {

    @NotNull(message = "El ID del usuario es obligatorio")
    private Long userId;

    @NotNull(message = "El ID del tipo de asignación es obligatorio")
    private Long assignmentTypeId;

    public SupervisorAssignmentRequest() {
    }

    public SupervisorAssignmentRequest(Long userId, Long assignmentTypeId) {
        this.userId = userId;
        this.assignmentTypeId = assignmentTypeId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Long getAssignmentTypeId() {
        return assignmentTypeId;
    }

    public void setAssignmentTypeId(Long assignmentTypeId) {
        this.assignmentTypeId = assignmentTypeId;
    }
}
