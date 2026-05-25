package com.bolsadeideas.springboot.backend.apirest.models.dto;

import javax.validation.constraints.NotNull;

/**
 * DTO para la solicitud de cambio de rol de un usuario.
 * Contiene el ID del rol a asignar.
 */
public class UserRoleRequest {

    @NotNull(message = "El ID del rol es obligatorio")
    private Long roleId;

    public UserRoleRequest() {
    }

    public UserRoleRequest(Long roleId) {
        this.roleId = roleId;
    }

    public Long getRoleId() {
        return roleId;
    }

    public void setRoleId(Long roleId) {
        this.roleId = roleId;
    }
}
