package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.Date;

/**
 * Response DTO para representar un tipo de asignación con su conteo de supervisores.
 */
public class AssignmentTypeResponse {

    private Long id;
    private String name;
    private String description;
    private Boolean active;
    private String filterValue;
    private Integer supervisorCount;
    private Date createdAt;

    public AssignmentTypeResponse() {
    }

    public AssignmentTypeResponse(Long id, String name, String description, Boolean active, String filterValue, Integer supervisorCount, Date createdAt) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.active = active;
        this.filterValue = filterValue;
        this.supervisorCount = supervisorCount;
        this.createdAt = createdAt;
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

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Boolean getActive() {
        return active;
    }

    public void setActive(Boolean active) {
        this.active = active;
    }

    public String getFilterValue() {
        return filterValue;
    }

    public void setFilterValue(String filterValue) {
        this.filterValue = filterValue;
    }

    public Integer getSupervisorCount() {
        return supervisorCount;
    }

    public void setSupervisorCount(Integer supervisorCount) {
        this.supervisorCount = supervisorCount;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }
}
