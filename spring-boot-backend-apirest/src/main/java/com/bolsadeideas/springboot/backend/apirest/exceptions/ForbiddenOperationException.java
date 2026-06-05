package com.bolsadeideas.springboot.backend.apirest.exceptions;

/**
 * Excepción lanzada cuando un usuario intenta realizar una operación para la cual no tiene permiso.
 * Por ejemplo, editar o eliminar un comentario que pertenece a otro usuario.
 * Corresponde a un HTTP 403 Forbidden.
 */
public class ForbiddenOperationException extends RuntimeException {

    public ForbiddenOperationException() {
        super("No tienes permiso para realizar esta acción");
    }

    public ForbiddenOperationException(String message) {
        super(message);
    }
}
