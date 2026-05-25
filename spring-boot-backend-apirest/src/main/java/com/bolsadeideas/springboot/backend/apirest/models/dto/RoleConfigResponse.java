package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.List;

/**
 * Response DTO para la configuración completa de un rol.
 * Muestra todos los módulos del catálogo con su estado de asignación (assigned true/false).
 */
public class RoleConfigResponse {

    private Long roleId;
    private String roleName;
    private List<ModuleAssignmentResponse> modules;

    public RoleConfigResponse() {
    }

    public RoleConfigResponse(Long roleId, String roleName, List<ModuleAssignmentResponse> modules) {
        this.roleId = roleId;
        this.roleName = roleName;
        this.modules = modules;
    }

    public Long getRoleId() {
        return roleId;
    }

    public void setRoleId(Long roleId) {
        this.roleId = roleId;
    }

    public String getRoleName() {
        return roleName;
    }

    public void setRoleName(String roleName) {
        this.roleName = roleName;
    }

    public List<ModuleAssignmentResponse> getModules() {
        return modules;
    }

    public void setModules(List<ModuleAssignmentResponse> modules) {
        this.modules = modules;
    }
}
