package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.Date;

/**
 * Response DTO para representar una asignación de supervisor con datos del usuario y tipo.
 */
public class SupervisorAssignmentResponse {

    private Long id;
    private Long userId;
    private String userName;
    private String userEmail;
    private Long assignmentTypeId;
    private String assignmentTypeName;
    private Date assignedAt;

    public SupervisorAssignmentResponse() {
    }

    public SupervisorAssignmentResponse(Long id, Long userId, String userName, String userEmail, Long assignmentTypeId, String assignmentTypeName, Date assignedAt) {
        this.id = id;
        this.userId = userId;
        this.userName = userName;
        this.userEmail = userEmail;
        this.assignmentTypeId = assignmentTypeId;
        this.assignmentTypeName = assignmentTypeName;
        this.assignedAt = assignedAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getUserEmail() {
        return userEmail;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public Long getAssignmentTypeId() {
        return assignmentTypeId;
    }

    public void setAssignmentTypeId(Long assignmentTypeId) {
        this.assignmentTypeId = assignmentTypeId;
    }

    public String getAssignmentTypeName() {
        return assignmentTypeName;
    }

    public void setAssignmentTypeName(String assignmentTypeName) {
        this.assignmentTypeName = assignmentTypeName;
    }

    public Date getAssignedAt() {
        return assignedAt;
    }

    public void setAssignedAt(Date assignedAt) {
        this.assignedAt = assignedAt;
    }
}
