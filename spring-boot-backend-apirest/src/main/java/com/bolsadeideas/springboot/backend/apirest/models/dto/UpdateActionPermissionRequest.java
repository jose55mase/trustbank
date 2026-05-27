package com.bolsadeideas.springboot.backend.apirest.models.dto;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

/**
 * Request DTO para actualizar un permiso de acción individual de un rol.
 * Especifica el módulo, la acción y el nuevo estado habilitado/deshabilitado.
 */
public class UpdateActionPermissionRequest {

    @NotBlank(message = "El código del módulo es obligatorio")
    private String moduleCode;

    @NotBlank(message = "El código de la acción es obligatorio")
    private String actionCode;

    @NotNull(message = "El estado habilitado es obligatorio")
    private Boolean enabled;

    public UpdateActionPermissionRequest() {
    }

    public UpdateActionPermissionRequest(String moduleCode, String actionCode, Boolean enabled) {
        this.moduleCode = moduleCode;
        this.actionCode = actionCode;
        this.enabled = enabled;
    }

    public String getModuleCode() {
        return moduleCode;
    }

    public void setModuleCode(String moduleCode) {
        this.moduleCode = moduleCode;
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
