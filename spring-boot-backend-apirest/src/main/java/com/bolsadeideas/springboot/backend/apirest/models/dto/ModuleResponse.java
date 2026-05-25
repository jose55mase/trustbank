package com.bolsadeideas.springboot.backend.apirest.models.dto;

/**
 * Response DTO para representar un módulo del catálogo.
 */
public class ModuleResponse {

    private Long id;
    private String code;
    private String name;
    private String description;
    private String icon;
    private Integer displayOrder;

    public ModuleResponse() {
    }

    public ModuleResponse(Long id, String code, String name, String description, String icon, Integer displayOrder) {
        this.id = id;
        this.code = code;
        this.name = name;
        this.description = description;
        this.icon = icon;
        this.displayOrder = displayOrder;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
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

    public Integer getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(Integer displayOrder) {
        this.displayOrder = displayOrder;
    }
}
