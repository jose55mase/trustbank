package com.bolsadeideas.springboot.backend.apirest.exceptions;

/**
 * Excepción lanzada cuando no se encuentra un tipo de asignación con el ID especificado.
 */
public class AssignmentTypeNotFoundException extends RuntimeException {

    public AssignmentTypeNotFoundException() {
        super("El tipo de asignación no existe");
    }

    public AssignmentTypeNotFoundException(Long id) {
        super("El tipo de asignación con ID " + id + " no existe");
    }
}
