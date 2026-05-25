package com.bolsadeideas.springboot.backend.apirest.exceptions;

/**
 * Excepción lanzada cuando un supervisor no tiene un tipo de asignación configurado.
 */
public class NoAssignmentConfiguredException extends RuntimeException {

    public NoAssignmentConfiguredException() {
        super("El supervisor no tiene un tipo de asignación configurado");
    }

    public NoAssignmentConfiguredException(Long userId) {
        super("El supervisor con ID " + userId + " no tiene un tipo de asignación configurado");
    }
}
