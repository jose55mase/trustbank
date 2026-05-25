package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.List;

/**
 * Response DTO para representar un rol con sus módulos asignados y conteo de usuarios.
 */
public class RolResponse {

    private Long id;
    private String name;
    private List<ModuleResponse> modules;
    private Integer userCount;

    public RolResponse() {
    }

    public RolResponse(Long id, String name, List<ModuleResponse> modules, Integer userCount) {
        this.id = id;
        this.name = name;
        this.modules = modules;
        this.userCount = userCount;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<ModuleResponse> getModules() {
        return modules;
    }

    public void setModules(List<ModuleResponse> modules) {
        this.modules = modules;
    }

    public Integer getUserCount() {
        return userCount;
    }

    public void setUserCount(Integer userCount) {
        this.userCount = userCount;
    }
}
