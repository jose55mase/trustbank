package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.List;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * Request DTO para desasignación de leads.
 * Permite desasignar uno o más leads (establecer advisor_id en nulo).
 */
public class LeadUnassignRequest {

    @NotNull(message = "La lista de leads es obligatoria")
    @Size(min = 1, message = "Debe especificar al menos un lead para desasignar")
    private List<Long> leadIds;

    public LeadUnassignRequest() {
    }

    public LeadUnassignRequest(List<Long> leadIds) {
        this.leadIds = leadIds;
    }

    public List<Long> getLeadIds() {
        return leadIds;
    }

    public void setLeadIds(List<Long> leadIds) {
        this.leadIds = leadIds;
    }
}
