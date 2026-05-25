package com.bolsadeideas.springboot.backend.apirest.exceptions;

/**
 * Excepción lanzada cuando se intenta eliminar un rol que tiene usuarios asignados.
 */
public class RoleHasUsersException extends RuntimeException {

    private final Long userCount;

    public RoleHasUsersException(Long userCount) {
        super("No se puede eliminar un rol con usuarios asignados");
        this.userCount = userCount;
    }

    public Long getUserCount() {
        return userCount;
    }
}
