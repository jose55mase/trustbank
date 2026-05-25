package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.List;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * Request DTO para reasignación de leads entre asesores.
 * Permite mover leads de un asesor a otro en una sola petición.
 */
public class LeadReassignRequest {

    @NotNull(message = "El ID del asesor origen es obligatorio")
    private Long fromAdvisorId;

    @NotNull(message = "El ID del asesor destino es obligatorio")
    private Long toAdvisorId;

    @NotNull(message = "La lista de leads es obligatoria")
    @Size(min = 1, message = "Debe especificar al menos un lead para reasignar")
    private List<Long> leadIds;

    public LeadReassignRequest() {
    }

    public LeadReassignRequest(Long fromAdvisorId, Long toAdvisorId, List<Long> leadIds) {
        this.fromAdvisorId = fromAdvisorId;
        this.toAdvisorId = toAdvisorId;
        this.leadIds = leadIds;
    }

    public Long getFromAdvisorId() {
        return fromAdvisorId;
    }

    public void setFromAdvisorId(Long fromAdvisorId) {
        this.fromAdvisorId = fromAdvisorId;
    }

    public Long getToAdvisorId() {
        return toAdvisorId;
    }

    public void setToAdvisorId(Long toAdvisorId) {
        this.toAdvisorId = toAdvisorId;
    }

    public List<Long> getLeadIds() {
        return leadIds;
    }

    public void setLeadIds(List<Long> leadIds) {
        this.leadIds = leadIds;
    }
}
