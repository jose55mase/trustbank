package com.bolsadeideas.springboot.backend.apirest.models.dto;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * Request DTO para crear o actualizar un tipo de asignación.
 * Valida que el nombre sea obligatorio y no exceda 100 caracteres.
 */
public class AssignmentTypeRequest {

    @NotBlank(message = "El nombre del tipo de asignación es obligatorio")
    @Size(max = 100, message = "El nombre no puede exceder 100 caracteres")
    private String name;

    @Size(max = 255, message = "La descripción no puede exceder 255 caracteres")
    private String description;

    private Boolean active;

    @Size(max = 100, message = "El valor de filtro no puede exceder 100 caracteres")
    private String filterValue;

    public AssignmentTypeRequest() {
    }

    public AssignmentTypeRequest(String name, String description, Boolean active, String filterValue) {
        this.name = name;
        this.description = description;
        this.active = active;
        this.filterValue = filterValue;
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
}
