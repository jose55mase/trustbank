package com.bolsadeideas.springboot.backend.apirest.models.dto;

/**
 * Response DTO para representar un módulo con su estado de asignación a un rol.
 * Usado dentro de RoleConfigResponse para mostrar todos los módulos del catálogo
 * indicando cuáles están asignados al rol.
 */
public class ModuleAssignmentResponse {

    private Long moduleId;
    private String code;
    private String name;
    private String description;
    private String icon;
    private boolean assigned;

    public ModuleAssignmentResponse() {
    }

    public ModuleAssignmentResponse(Long moduleId, String code, String name, String description, String icon, boolean assigned) {
        this.moduleId = moduleId;
        this.code = code;
        this.name = name;
        this.description = description;
        this.icon = icon;
        this.assigned = assigned;
    }

    public Long getModuleId() {
        return moduleId;
    }

    public void setModuleId(Long moduleId) {
        this.moduleId = moduleId;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public boolean isAssigned() {
        return assigned;
    }

    public void setAssigned(boolean assigned) {
        this.assigned = assigned;
    }
}
