package com.bolsadeideas.springboot.backend.apirest.exceptions;

/**
 * Excepción lanzada cuando un supervisor intenta acceder a un lead que no pertenece a su asignación.
 */
public class LeadNotInAssignmentException extends RuntimeException {

    public LeadNotInAssignmentException() {
        super("No tienes acceso a este lead");
    }

    public LeadNotInAssignmentException(Long leadId, Long userId) {
        super("El supervisor con ID " + userId + " no tiene acceso al lead con ID " + leadId);
    }
}
