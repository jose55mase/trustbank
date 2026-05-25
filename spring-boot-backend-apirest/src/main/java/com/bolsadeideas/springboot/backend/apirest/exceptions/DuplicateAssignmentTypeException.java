package com.bolsadeideas.springboot.backend.apirest.exceptions;

/**
 * Excepción lanzada cuando se intenta crear o actualizar un tipo de asignación con un nombre que ya existe.
 */
public class DuplicateAssignmentTypeException extends RuntimeException {

    public DuplicateAssignmentTypeException() {
        super("Ya existe un tipo de asignación con ese nombre");
    }

    public DuplicateAssignmentTypeException(String message) {
        super(message);
    }
}
