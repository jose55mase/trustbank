package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.util.List;

import com.bolsadeideas.springboot.backend.apirest.models.dto.AssignmentTypeRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.AssignmentTypeResponse;

/**
 * Interfaz del servicio de gestión de Tipos de Asignación.
 * Define las operaciones CRUD con validaciones de negocio.
 */
public interface IAssignmentTypeService {

    /**
     * Retorna todos los tipos de asignación con conteo de supervisores.
     */
    List<AssignmentTypeResponse> findAll();

    /**
     * Retorna solo los tipos de asignación activos.
     */
    List<AssignmentTypeResponse> findActive();

    /**
     * Busca un tipo de asignación por su ID.
     * Lanza excepción si no existe.
     */
    AssignmentTypeResponse findById(Long id);

    /**
     * Crea un nuevo tipo de asignación.
     * Valida que el nombre sea único.
     */
    AssignmentTypeResponse create(AssignmentTypeRequest request);

    /**
     * Actualiza un tipo de asignación existente.
     * Valida que el nombre sea único (excluyendo el actual).
     */
    AssignmentTypeResponse update(Long id, AssignmentTypeRequest request);

    /**
     * Elimina un tipo de asignación.
     * Rechaza si tiene supervisores asociados.
     */
    void delete(Long id);
}
