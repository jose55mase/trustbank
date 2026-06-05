package com.bolsadeideas.springboot.backend.apirest.exceptions;

/**
 * Excepción lanzada cuando no se encuentra un recurso solicitado (lead, comentario, etc.).
 * Corresponde a un HTTP 404 Not Found.
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException() {
        super("El recurso no fue encontrado");
    }

    public ResourceNotFoundException(String message) {
        super(message);
    }

    public ResourceNotFoundException(String resourceName, Long id) {
        super("El " + resourceName + " con id " + id + " no fue encontrado");
    }
}
