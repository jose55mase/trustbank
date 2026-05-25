package com.bolsadeideas.springboot.backend.apirest.exceptions;

/**
 * Excepción lanzada cuando un usuario ya tiene una asignación de supervisor.
 */
public class AssignmentAlreadyExistsException extends RuntimeException {

    public AssignmentAlreadyExistsException() {
        super("El usuario ya tiene una asignación de supervisor");
    }

    public AssignmentAlreadyExistsException(Long userId) {
        super("El usuario con ID " + userId + " ya tiene una asignación de supervisor");
    }
}
