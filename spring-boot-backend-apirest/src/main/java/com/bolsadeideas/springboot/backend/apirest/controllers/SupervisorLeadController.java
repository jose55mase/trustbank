package com.bolsadeideas.springboot.backend.apirest.controllers;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.annotation.Secured;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.bolsadeideas.springboot.backend.apirest.exceptions.LeadNotInAssignmentException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.NoAssignmentConfiguredException;
import com.bolsadeideas.springboot.backend.apirest.models.dto.LeadPartialUpdateRequest;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.ILeadService;
import com.bolsadeideas.springboot.backend.apirest.models.services.UsuarioService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.ISupervisorLeadService;

/**
 * Controlador REST para la gestión de leads por parte de supervisores.
 * Permite al supervisor listar, buscar, ver detalle y actualizar parcialmente
 * los leads que pertenecen a su tipo de asignación.
 */
@RestController
@RequestMapping("/api/supervisor/leads")
public class SupervisorLeadController {

    @Autowired
    private ISupervisorLeadService supervisorLeadService;

    @Autowired
    private ILeadService leadService;

    @Autowired
    private UsuarioService usuarioService;

    /**
     * GET /api/supervisor/leads?page=X&size=Y
     * Lista leads filtrados por la asignación del supervisor autenticado.
     */
    @Secured("ROLE_SUPERVISOR")
    @GetMapping
    public ResponseEntity<?> findAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getCurrentUserId();
            if (userId == null) {
                response.put("error", "Usuario no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }

            Pageable pageable = PageRequest.of(page, size);
            Page<LeadEntity> leads = supervisorLeadService.findLeadsBySupervisor(userId, pageable);
            return new ResponseEntity<>(leads, HttpStatus.OK);
        } catch (NoAssignmentConfiguredException e) {
            response.put("error", "NO_ASSIGNMENT_CONFIGURED");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/supervisor/leads/search?term=X&page=Y&size=Z
     * Busca leads dentro de los asignados al supervisor por un término de búsqueda.
     */
    @Secured("ROLE_SUPERVISOR")
    @GetMapping("/search")
    public ResponseEntity<?> search(
            @RequestParam String term,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getCurrentUserId();
            if (userId == null) {
                response.put("error", "Usuario no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }

            Pageable pageable = PageRequest.of(page, size);
            Page<LeadEntity> leads = supervisorLeadService.searchLeadsBySupervisor(userId, term, pageable);
            return new ResponseEntity<>(leads, HttpStatus.OK);
        } catch (NoAssignmentConfiguredException e) {
            response.put("error", "NO_ASSIGNMENT_CONFIGURED");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/supervisor/leads/{id}
     * Obtiene el detalle de un lead asignado al supervisor.
     * Verifica que el lead pertenece a la asignación del supervisor antes de retornarlo.
     */
    @Secured("ROLE_SUPERVISOR")
    @GetMapping("/{id}")
    public ResponseEntity<?> findById(@PathVariable Long id) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getCurrentUserId();
            if (userId == null) {
                response.put("error", "Usuario no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }

            // Verificar que el lead pertenece a la asignación del supervisor
            if (!supervisorLeadService.isLeadInSupervisorAssignment(id, userId)) {
                response.put("error", "LEAD_NOT_IN_ASSIGNMENT");
                response.put("message", "No tienes acceso a este lead");
                return new ResponseEntity<>(response, HttpStatus.FORBIDDEN);
            }

            LeadEntity lead = leadService.findById(id);
            return new ResponseEntity<>(lead, HttpStatus.OK);
        } catch (NoAssignmentConfiguredException e) {
            response.put("error", "NO_ASSIGNMENT_CONFIGURED");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (RuntimeException e) {
            response.put("error", "Lead no encontrado");
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * PUT /api/supervisor/leads/{id}
     * Actualización parcial de un lead asignado al supervisor.
     * Solo actualiza los campos con valor no nulo en el request.
     * Verifica que el lead pertenece a la asignación del supervisor.
     */
    @Secured("ROLE_SUPERVISOR")
    @PutMapping("/{id}")
    public ResponseEntity<?> updatePartial(@PathVariable Long id, @RequestBody LeadPartialUpdateRequest request) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getCurrentUserId();
            if (userId == null) {
                response.put("error", "Usuario no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }

            LeadEntity updatedLead = supervisorLeadService.updateLeadPartial(id, userId, request);
            return new ResponseEntity<>(updatedLead, HttpStatus.OK);
        } catch (LeadNotInAssignmentException e) {
            response.put("error", "LEAD_NOT_IN_ASSIGNMENT");
            response.put("message", "No tienes acceso a este lead");
            return new ResponseEntity<>(response, HttpStatus.FORBIDDEN);
        } catch (NoAssignmentConfiguredException e) {
            response.put("error", "NO_ASSIGNMENT_CONFIGURED");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (RuntimeException e) {
            response.put("error", "Lead no encontrado");
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Obtiene el ID del usuario autenticado a partir del SecurityContext.
     * Usa el email del token para buscar el usuario en la base de datos.
     *
     * @return el ID del usuario, o null si no se encuentra
     */
    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();

        UserEntity user = usuarioService.findByemail(email);
        if (user == null) {
            return null;
        }

        return user.getId();
    }
}
