package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.exceptions.LeadNotInAssignmentException;
import com.bolsadeideas.springboot.backend.apirest.models.dao.ILeadDao;
import com.bolsadeideas.springboot.backend.apirest.models.dto.LeadPartialUpdateRequest;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.ISupervisorLeadService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Implementación del servicio de leads para supervisores.
 * Filtra leads por asignación directa (advisor_id) en lugar del sistema de campana/filterValue.
 */
@Service
public class SupervisorLeadServiceImpl implements ISupervisorLeadService {

    private static final Logger logger = LoggerFactory.getLogger(SupervisorLeadServiceImpl.class);

    @Autowired
    private ILeadDao leadDao;

    @Override
    @Transactional(readOnly = true)
    public Page<LeadEntity> findLeadsBySupervisor(Long userId, Pageable pageable) {
        return leadDao.findByAdvisorId(userId, pageable);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<LeadEntity> searchLeadsBySupervisor(Long userId, String term, Pageable pageable) {
        return leadDao.searchByAdvisorIdAndTerm(userId, term, pageable);
    }

    @Override
    @Transactional
    public LeadEntity updateLeadPartial(Long leadId, Long userId, LeadPartialUpdateRequest request) {
        // Verificar que el lead pertenece al asesor (asignación directa)
        if (!isLeadInSupervisorAssignment(leadId, userId)) {
            logger.warn("Unauthorized partial update attempt: userId={}, leadId={}", userId, leadId);
            throw new LeadNotInAssignmentException(leadId, userId);
        }

        // Obtener el lead existente
        LeadEntity lead = leadDao.findById(leadId)
                .orElseThrow(() -> new RuntimeException("Lead no encontrado con ID: " + leadId));

        // Aplicar actualización parcial: solo actualizar campos con valor no nulo
        if (request.getNombre() != null) {
            lead.setNombre(request.getNombre());
        }
        if (request.getApellido() != null) {
            lead.setApellido(request.getApellido());
        }
        if (request.getTelefono() != null) {
            lead.setTelefono(request.getTelefono());
        }
        if (request.getEmail() != null) {
            lead.setEmail(request.getEmail());
        }
        if (request.getPais() != null) {
            lead.setPais(request.getPais());
        }
        if (request.getCampana() != null) {
            lead.setCampana(request.getCampana());
        }
        if (request.getLastCallStatus() != null) {
            lead.setLastCallStatus(request.getLastCallStatus());
        }
        if (request.getComentarios() != null) {
            lead.setComentarios(request.getComentarios());
        }
        if (request.getLastCallDate() != null) {
            lead.setLastCallDate(request.getLastCallDate());
        }

        return leadDao.save(lead);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean isLeadInSupervisorAssignment(Long leadId, Long userId) {
        LeadEntity lead = leadDao.findById(leadId).orElse(null);
        if (lead == null) {
            return false;
        }
        return lead.getAdvisor() != null && lead.getAdvisor().getId().equals(userId);
    }
}
