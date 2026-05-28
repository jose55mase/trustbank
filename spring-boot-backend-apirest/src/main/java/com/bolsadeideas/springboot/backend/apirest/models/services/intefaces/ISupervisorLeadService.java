package com.bolsadeideas.springboot.backend.apirest.models.services.intefaces;

import com.bolsadeideas.springboot.backend.apirest.models.dto.LeadPartialUpdateRequest;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

/**
 * Servicio para la gestión de leads por parte de supervisores.
 * Filtra leads según el tipo de asignación del supervisor y permite actualizaciones parciales.
 */
public interface ISupervisorLeadService {

    /**
     * Retorna los leads filtrados por el tipo de asignación del supervisor.
     * Obtiene el filterValue del tipo de asignación y filtra por el campo campana.
     */
    Page<LeadEntity> findLeadsBySupervisor(Long userId, Pageable pageable);

    /**
     * Retorna los leads filtrados por asignación del supervisor y por status (lastCallStatus).
     */
    Page<LeadEntity> findLeadsBySupervisorAndStatus(Long userId, String status, Pageable pageable);

    /**
     * Busca leads dentro de los asignados al supervisor por un término de búsqueda.
     * Filtra por campana (asignación) y por término en nombre, apellido, teléfono o email.
     */
    Page<LeadEntity> searchLeadsBySupervisor(Long userId, String term, Pageable pageable);

    /**
     * Aplica una actualización parcial a un lead, verificando que pertenece a la asignación del supervisor.
     * Solo actualiza los campos con valor no nulo en el request.
     *
     * @throws com.bolsadeideas.springboot.backend.apirest.exceptions.LeadNotInAssignmentException si el lead no pertenece a la asignación
     */
    LeadEntity updateLeadPartial(Long leadId, Long userId, LeadPartialUpdateRequest request);

    /**
     * Verifica si un lead pertenece a la asignación del supervisor.
     */
    boolean isLeadInSupervisorAssignment(Long leadId, Long userId);
}
