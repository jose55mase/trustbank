package com.bolsadeideas.springboot.backend.apirest.models.dto;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

/**
 * Request DTO para crear o actualizar un rol.
 * Valida que el nombre tenga entre 3 y 50 caracteres alfanuméricos, guiones bajos o espacios.
 */
public class RolRequest {

    @NotBlank(message = "El nombre del rol es obligatorio")
    @Size(min = 3, max = 50, message = "El nombre debe tener entre 3 y 50 caracteres")
    @Pattern(regexp = "^[a-zA-Z0-9_\\s]+$", message = "El nombre solo puede contener letras, números, guiones bajos y espacios")
    private String name;

    public RolRequest() {
    }

    public RolRequest(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
