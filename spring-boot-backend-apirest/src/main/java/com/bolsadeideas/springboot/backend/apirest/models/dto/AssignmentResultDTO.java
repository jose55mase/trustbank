package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.List;

/**
 * Response DTO para el resultado de una operación de asignación de leads.
 * Incluye el conteo de leads asignados, datos del asesor, y los IDs de leads que fallaron.
 */
public class AssignmentResultDTO {

    private int assignedCount;
    private String advisorName;
    private String advisorEmail;
    private List<Long> failedLeadIds;

    public AssignmentResultDTO() {
    }

    public AssignmentResultDTO(int assignedCount, String advisorName, String advisorEmail, List<Long> failedLeadIds) {
        this.assignedCount = assignedCount;
        this.advisorName = advisorName;
        this.advisorEmail = advisorEmail;
        this.failedLeadIds = failedLeadIds;
    }

    public int getAssignedCount() {
        return assignedCount;
    }

    public void setAssignedCount(int assignedCount) {
        this.assignedCount = assignedCount;
    }

    public String getAdvisorName() {
        return advisorName;
    }

    public void setAdvisorName(String advisorName) {
        this.advisorName = advisorName;
    }

    public String getAdvisorEmail() {
        return advisorEmail;
    }

    public void setAdvisorEmail(String advisorEmail) {
        this.advisorEmail = advisorEmail;
    }

    public List<Long> getFailedLeadIds() {
        return failedLeadIds;
    }

    public void setFailedLeadIds(List<Long> failedLeadIds) {
        this.failedLeadIds = failedLeadIds;
    }
}
