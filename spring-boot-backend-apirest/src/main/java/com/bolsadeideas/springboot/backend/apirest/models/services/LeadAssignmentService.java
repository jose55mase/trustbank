package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.models.dao.ILeadDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.ISupervisorAssignmentDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IUserDao;
import com.bolsadeideas.springboot.backend.apirest.models.dto.AdvisorSummaryDTO;
import com.bolsadeideas.springboot.backend.apirest.models.dto.AssignmentResultDTO;
import com.bolsadeideas.springboot.backend.apirest.models.entity.SupervisorAssignmentEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Servicio para gestionar la asignación directa de leads a asesores.
 * Proporciona operaciones de asignación masiva, desasignación, reasignación
 * y consulta de resumen de asesores con conteo de leads.
 */
@Service
public class LeadAssignmentService {

    private static final Logger logger = LoggerFactory.getLogger(LeadAssignmentService.class);

    @Autowired
    private ILeadDao leadDao;

    @Autowired
    private IUserDao userDao;

    @Autowired
    private ISupervisorAssignmentDao supervisorAssignmentDao;

    /**
     * Asigna múltiples leads a un asesor.
     * Valida que el advisorId corresponda a un usuario con ROLE_ASESOR.
     * Si algunos lead IDs no existen, retorna éxito parcial con los IDs fallidos.
     *
     * @param leadIds lista de IDs de leads a asignar
     * @param advisorId ID del asesor destino
     * @return resultado con conteo de asignados, datos del asesor y IDs fallidos
     */
    @Transactional
    public AssignmentResultDTO assignLeads(List<Long> leadIds, Long advisorId) {
        // Validar que el asesor tiene rol ROLE_ASESOR
        UserEntity advisor = validateAdvisorRole(advisorId);

        // Identificar leads que existen vs los que no
        List<Long> existingLeadIds = leadIds.stream()
                .filter(id -> leadDao.existsById(id))
                .collect(Collectors.toList());

        List<Long> failedLeadIds = leadIds.stream()
                .filter(id -> !existingLeadIds.contains(id))
                .collect(Collectors.toList());

        // Realizar asignación masiva solo para leads existentes
        int assignedCount = 0;
        if (!existingLeadIds.isEmpty()) {
            assignedCount = leadDao.bulkAssign(existingLeadIds, advisorId);

            // Actualizar el campo campana con la campaña del asesor
            String campaignName = getAdvisorCampaignName(advisorId);
            if (campaignName != null && !campaignName.isEmpty()) {
                leadDao.bulkUpdateCampana(existingLeadIds, campaignName);
            }
        }

        logger.info("Bulk assign: advisorId={}, requestedCount={}, successCount={}, failedCount={}",
                advisorId, leadIds.size(), assignedCount, failedLeadIds.size());

        return new AssignmentResultDTO(
                assignedCount,
                advisor.getFullName(),
                advisor.getEmail(),
                failedLeadIds.isEmpty() ? null : failedLeadIds
        );
    }

    /**
     * Desasigna leads (establece advisor_id = null).
     *
     * @param leadIds lista de IDs de leads a desasignar
     * @return cantidad de leads desasignados
     */
    @Transactional
    public int unassignLeads(List<Long> leadIds) {
        int unassignedCount = leadDao.bulkUnassign(leadIds);

        logger.info("Unassign: leadCount={}, successCount={}", leadIds.size(), unassignedCount);

        return unassignedCount;
    }

    /**
     * Reasigna leads de un asesor a otro.
     * Valida que ambos advisorIds correspondan a usuarios con ROLE_ASESOR.
     *
     * @param fromAdvisorId ID del asesor origen
     * @param toAdvisorId ID del asesor destino
     * @param leadIds lista de IDs de leads a reasignar
     * @return resultado con conteo de reasignados y datos del nuevo asesor
     */
    @Transactional
    public AssignmentResultDTO reassignLeads(Long fromAdvisorId, Long toAdvisorId, List<Long> leadIds) {
        // Validar ambos asesores
        validateAdvisorRole(fromAdvisorId);
        UserEntity toAdvisor = validateAdvisorRole(toAdvisorId);

        // Identificar leads que existen vs los que no
        List<Long> existingLeadIds = leadIds.stream()
                .filter(id -> leadDao.existsById(id))
                .collect(Collectors.toList());

        List<Long> failedLeadIds = leadIds.stream()
                .filter(id -> !existingLeadIds.contains(id))
                .collect(Collectors.toList());

        // Realizar reasignación masiva
        int reassignedCount = 0;
        if (!existingLeadIds.isEmpty()) {
            reassignedCount = leadDao.bulkAssign(existingLeadIds, toAdvisorId);
        }

        logger.info("Reassign: fromAdvisorId={}, toAdvisorId={}, requestedCount={}, successCount={}, failedCount={}",
                fromAdvisorId, toAdvisorId, leadIds.size(), reassignedCount, failedLeadIds.size());

        return new AssignmentResultDTO(
                reassignedCount,
                toAdvisor.getFullName(),
                toAdvisor.getEmail(),
                failedLeadIds.isEmpty() ? null : failedLeadIds
        );
    }

    /**
     * Retorna resumen de asesores con conteo de leads asignados.
     * Incluye asesores con 0 leads.
     *
     * @return lista de resúmenes de asesores
     */
    @Transactional(readOnly = true)
    public List<AdvisorSummaryDTO> getAdvisorSummary() {
        // Obtener todos los usuarios y filtrar los que tienen ROLE_ASESOR
        List<UserEntity> allUsers = new ArrayList<>();
        userDao.findAll().forEach(allUsers::add);

        List<AdvisorSummaryDTO> summaries = allUsers.stream()
                .filter(this::hasSupervisorRole)
                .map(user -> {
                    Long leadCount = leadDao.countByAdvisorId(user.getId());
                    return new AdvisorSummaryDTO(
                            user.getId(),
                            user.getFullName(),
                            user.getEmail(),
                            leadCount != null ? leadCount : 0L
                    );
                })
                .collect(Collectors.toList());

        return summaries;
    }

    /**
     * Valida que el usuario existe y tiene rol ROLE_ASESOR.
     *
     * @param userId ID del usuario a validar
     * @return la entidad del usuario si es válido
     * @throws IllegalArgumentException si el usuario no existe o no tiene el rol requerido
     */
    private UserEntity validateAdvisorRole(Long userId) {
        UserEntity user = userDao.findByid(userId);

        if (user == null) {
            logger.warn("Invalid advisor: userId={}, reason=user_not_found", userId);
            throw new IllegalArgumentException(
                    "El usuario especificado no existe o no tiene rol de asesor");
        }

        if (!hasSupervisorRole(user)) {
            logger.warn("Invalid advisor: userId={}, reason=missing_role_asesor", userId);
            throw new IllegalArgumentException(
                    "El usuario especificado no existe o no tiene rol de asesor");
        }

        return user;
    }

    /**
     * Verifica si un usuario tiene el rol ROLE_ASESOR.
     */
    private boolean hasSupervisorRole(UserEntity user) {
        if (user.getRols() == null || user.getRols().isEmpty()) {
            return false;
        }
        return user.getRols().stream()
                .anyMatch(rol -> "ROLE_ASESOR".equals(rol.getName()));
    }

    /**
     * Obtiene el nombre de la campaña asignada a un asesor.
     * Retorna null si el asesor no tiene campaña asignada.
     */
    private String getAdvisorCampaignName(Long advisorId) {
        return supervisorAssignmentDao.findByUserId(advisorId)
                .map(assignment -> assignment.getAssignmentType().getName())
                .orElse(null);
    }
}
