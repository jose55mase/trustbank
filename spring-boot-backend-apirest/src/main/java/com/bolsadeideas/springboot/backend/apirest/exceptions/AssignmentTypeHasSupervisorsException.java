package com.bolsadeideas.springboot.backend.apirest.exceptions;

/**
 * Excepción lanzada cuando se intenta eliminar un tipo de asignación que tiene supervisores asociados.
 */
public class AssignmentTypeHasSupervisorsException extends RuntimeException {

    private final Long supervisorCount;

    public AssignmentTypeHasSupervisorsException(Long supervisorCount) {
        super("No se puede eliminar un tipo con supervisores asociados");
        this.supervisorCount = supervisorCount;
    }

    public Long getSupervisorCount() {
        return supervisorCount;
    }
}
