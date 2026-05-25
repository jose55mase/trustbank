package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.List;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * Request DTO para asignación masiva de leads a un asesor.
 * Permite asignar uno o más leads a un asesor específico en una sola petición.
 */
public class LeadAssignmentRequest {

    @NotNull(message = "La lista de leads es obligatoria")
    @Size(min = 1, message = "Debe especificar al menos un lead para asignar")
    private List<Long> leadIds;

    @NotNull(message = "El ID del asesor es obligatorio")
    private Long advisorId;

    public LeadAssignmentRequest() {
    }

    public LeadAssignmentRequest(List<Long> leadIds, Long advisorId) {
        this.leadIds = leadIds;
        this.advisorId = advisorId;
    }

    public List<Long> getLeadIds() {
        return leadIds;
    }

    public void setLeadIds(List<Long> leadIds) {
        this.leadIds = leadIds;
    }

    public Long getAdvisorId() {
        return advisorId;
    }

    public void setAdvisorId(Long advisorId) {
        this.advisorId = advisorId;
    }
}
