package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.List;

import javax.validation.constraints.NotNull;

/**
 * Request DTO para actualizar la visibilidad de campañas de un rol.
 * Contiene la lista de IDs de campañas visibles para el rol.
 * Una lista vacía significa acceso sin restricciones a todos los leads.
 */
public class UpdateCampaignVisibilityRequest {

    @NotNull(message = "La lista de campañas es obligatoria")
    private List<Long> campaignIds;

    public UpdateCampaignVisibilityRequest() {
    }

    public UpdateCampaignVisibilityRequest(List<Long> campaignIds) {
        this.campaignIds = campaignIds;
    }

    public List<Long> getCampaignIds() {
        return campaignIds;
    }

    public void setCampaignIds(List<Long> campaignIds) {
        this.campaignIds = campaignIds;
    }
}
