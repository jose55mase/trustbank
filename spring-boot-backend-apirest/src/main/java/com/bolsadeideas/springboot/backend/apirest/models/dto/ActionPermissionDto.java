package com.bolsadeideas.springboot.backend.apirest.models.dto;

/**
 * DTO que representa el estado de un permiso de acción individual.
 * Contiene el código de la acción y si está habilitada o no.
 */
public class ActionPermissionDto {

    private String actionCode;
    private Boolean enabled;

    public ActionPermissionDto() {
    }

    public ActionPermissionDto(String actionCode, Boolean enabled) {
        this.actionCode = actionCode;
        this.enabled = enabled;
    }

    public String getActionCode() {
        return actionCode;
    }

    public void setActionCode(String actionCode) {
        this.actionCode = actionCode;
    }

    public Boolean getEnabled() {
        return enabled;
    }

    public void setEnabled(Boolean enabled) {
        this.enabled = enabled;
    }
}
