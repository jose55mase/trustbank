package com.bolsadeideas.springboot.backend.apirest.models.dto;

import javax.validation.constraints.NotNull;
import java.util.List;

/**
 * Request DTO para asignar módulos a un rol.
 * Contiene la lista de IDs de módulos a asignar.
 */
public class RoleModulesRequest {

    @NotNull(message = "La lista de módulos es obligatoria")
    private List<Long> moduleIds;

    public RoleModulesRequest() {
    }

    public RoleModulesRequest(List<Long> moduleIds) {
        this.moduleIds = moduleIds;
    }

    public List<Long> getModuleIds() {
        return moduleIds;
    }

    public void setModuleIds(List<Long> moduleIds) {
        this.moduleIds = moduleIds;
    }
}
