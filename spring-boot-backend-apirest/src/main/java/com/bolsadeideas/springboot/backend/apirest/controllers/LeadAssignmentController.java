package com.bolsadeideas.springboot.backend.apirest.controllers;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.annotation.Secured;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.bolsadeideas.springboot.backend.apirest.models.dao.ILeadDao;
import com.bolsadeideas.springboot.backend.apirest.models.dto.AdvisorSummaryDTO;
import com.bolsadeideas.springboot.backend.apirest.models.dto.AssignmentResultDTO;
import com.bolsadeideas.springboot.backend.apirest.models.dto.LeadAssignmentRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.LeadReassignRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.LeadUnassignRequest;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.LeadAssignmentService;

/**
 * Controlador REST para la gestión administrativa de asignación de leads a asesores.
 * Todos los endpoints requieren rol ROLE_ADMIN.
 */
@RestController
@RequestMapping("/api/admin")
public class LeadAssignmentController {

    @Autowired
    private LeadAssignmentService leadAssignmentService;

    @Autowired
    private ILeadDao leadDao;

    /**
     * POST /api/admin/leads/assign
     * Asigna múltiples leads a un asesor.
     * Retorna 200 si todos se asignaron, 207 si hubo éxito parcial (algunos IDs no existen).
     */
    // Access controlled by ModuleAccessFilter
    @PostMapping("/leads/assign")
    public ResponseEntity<?> assignLeads(@Valid @RequestBody LeadAssignmentRequest request) {
        Map<String, Object> response = new HashMap<>();

        try {
            AssignmentResultDTO result = leadAssignmentService.assignLeads(
                    request.getLeadIds(), request.getAdvisorId());

            // Si hay IDs fallidos, retornar 207 Multi-Status (éxito parcial)
            if (result.getFailedLeadIds() != null && !result.getFailedLeadIds().isEmpty()) {
                return new ResponseEntity<>(result, HttpStatus.MULTI_STATUS);
            }

            return new ResponseEntity<>(result, HttpStatus.OK);
        } catch (IllegalArgumentException e) {
            response.put("error", "INVALID_ADVISOR");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            response.put("error", "ASSIGNMENT_FAILED");
            response.put("message", "Error al procesar la asignación");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * POST /api/admin/leads/unassign
     * Desasigna leads (establece advisor_id = null).
     */
    // Access controlled by ModuleAccessFilter
    @PostMapping("/leads/unassign")
    public ResponseEntity<?> unassignLeads(@Valid @RequestBody LeadUnassignRequest request) {
        Map<String, Object> response = new HashMap<>();

        try {
            int unassignedCount = leadAssignmentService.unassignLeads(request.getLeadIds());

            response.put("unassignedCount", unassignedCount);
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (Exception e) {
            response.put("error", "ASSIGNMENT_FAILED");
            response.put("message", "Error al procesar la desasignación");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * POST /api/admin/leads/reassign
     * Reasigna leads de un asesor a otro.
     * Retorna 200 si todos se reasignaron, 207 si hubo éxito parcial.
     */
    // Access controlled by ModuleAccessFilter
    @PostMapping("/leads/reassign")
    public ResponseEntity<?> reassignLeads(@Valid @RequestBody LeadReassignRequest request) {
        Map<String, Object> response = new HashMap<>();

        try {
            AssignmentResultDTO result = leadAssignmentService.reassignLeads(
                    request.getFromAdvisorId(),
                    request.getToAdvisorId(),
                    request.getLeadIds());

            // Si hay IDs fallidos, retornar 207 Multi-Status (éxito parcial)
            if (result.getFailedLeadIds() != null && !result.getFailedLeadIds().isEmpty()) {
                return new ResponseEntity<>(result, HttpStatus.MULTI_STATUS);
            }

            return new ResponseEntity<>(result, HttpStatus.OK);
        } catch (IllegalArgumentException e) {
            response.put("error", "INVALID_ADVISOR");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            response.put("error", "ASSIGNMENT_FAILED");
            response.put("message", "Error al procesar la reasignación");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/admin/advisors/summary
     * Retorna resumen de asesores con conteo de leads asignados.
     * Incluye asesores con 0 leads.
     */
    // Access controlled by ModuleAccessFilter
    @GetMapping("/advisors/summary")
    public ResponseEntity<?> getAdvisorSummary() {
        Map<String, Object> response = new HashMap<>();

        try {
            List<AdvisorSummaryDTO> summaries = leadAssignmentService.getAdvisorSummary();
            return new ResponseEntity<>(summaries, HttpStatus.OK);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/admin/advisors/{advisorId}/leads
     * Retorna los leads asignados a un asesor específico con paginación.
     */
    // Access controlled by ModuleAccessFilter
    @GetMapping("/advisors/{advisorId}/leads")
    public ResponseEntity<?> getAdvisorLeads(
            @PathVariable Long advisorId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Map<String, Object> response = new HashMap<>();

        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<LeadEntity> leads = leadDao.findByAdvisorId(advisorId, pageable);
            return new ResponseEntity<>(leads, HttpStatus.OK);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
