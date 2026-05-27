package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.List;
import java.util.Map;

/**
 * DTO de respuesta que contiene todos los permisos del usuario para un módulo.
 * Incluye el mapa de acciones (código de acción → habilitado) y la lista de
 * IDs de campañas visibles (lista vacía significa acceso sin restricciones).
 */
public class UserPermissionsDto {

    private String moduleCode;
    private Map<String, Boolean> actions;
    private List<Long> visibleCampaignIds;

    public UserPermissionsDto() {
    }

    public UserPermissionsDto(String moduleCode, Map<String, Boolean> actions, List<Long> visibleCampaignIds) {
        this.moduleCode = moduleCode;
        this.actions = actions;
        this.visibleCampaignIds = visibleCampaignIds;
    }

    public String getModuleCode() {
        return moduleCode;
    }

    public void setModuleCode(String moduleCode) {
        this.moduleCode = moduleCode;
    }

    public Map<String, Boolean> getActions() {
        return actions;
    }

    public void setActions(Map<String, Boolean> actions) {
        this.actions = actions;
    }

    public List<Long> getVisibleCampaignIds() {
        return visibleCampaignIds;
    }

    public void setVisibleCampaignIds(List<Long> visibleCampaignIds) {
        this.visibleCampaignIds = visibleCampaignIds;
    }
}
