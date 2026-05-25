package com.bolsadeideas.springboot.backend.apirest.models.dto;

/**
 * Response DTO para el resumen de un asesor con su conteo de leads asignados.
 * Utilizado en el endpoint de resumen de asesores para el panel administrativo.
 */
public class AdvisorSummaryDTO {

    private Long advisorId;
    private String advisorName;
    private String advisorEmail;
    private Long assignedLeadCount;

    public AdvisorSummaryDTO() {
    }

    public AdvisorSummaryDTO(Long advisorId, String advisorName, String advisorEmail, Long assignedLeadCount) {
        this.advisorId = advisorId;
        this.advisorName = advisorName;
        this.advisorEmail = advisorEmail;
        this.assignedLeadCount = assignedLeadCount;
    }

    public Long getAdvisorId() {
        return advisorId;
    }

    public void setAdvisorId(Long advisorId) {
        this.advisorId = advisorId;
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

    public Long getAssignedLeadCount() {
        return assignedLeadCount;
    }

    public void setAssignedLeadCount(Long assignedLeadCount) {
        this.assignedLeadCount = assignedLeadCount;
    }
}
