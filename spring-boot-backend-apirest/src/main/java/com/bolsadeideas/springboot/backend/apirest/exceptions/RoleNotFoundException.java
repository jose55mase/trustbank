package com.bolsadeideas.springboot.backend.apirest.exceptions;

/**
 * Excepción lanzada cuando no se encuentra un rol con el ID especificado.
 */
public class RoleNotFoundException extends RuntimeException {

    public RoleNotFoundException() {
        super("El rol no existe");
    }

    public RoleNotFoundException(Long id) {
        super("El rol con ID " + id + " no existe");
    }
}
