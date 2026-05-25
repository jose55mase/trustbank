package com.bolsadeideas.springboot.backend.apirest.exceptions;

/**
 * Excepción lanzada cuando se intenta crear o actualizar un rol con un nombre que ya existe.
 */
public class DuplicateRoleNameException extends RuntimeException {

    public DuplicateRoleNameException() {
        super("El nombre del rol ya está en uso");
    }

    public DuplicateRoleNameException(String message) {
        super(message);
    }
}
