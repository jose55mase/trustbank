package com.bolsadeideas.springboot.backend.apirest.controllers;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.annotation.Secured;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.bolsadeideas.springboot.backend.apirest.exceptions.AssignmentAlreadyExistsException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.AssignmentTypeNotFoundException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.NoAssignmentConfiguredException;
import com.bolsadeideas.springboot.backend.apirest.models.dto.SupervisorAssignmentRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.SupervisorAssignmentResponse;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.UsuarioService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.ISupervisorAssignmentService;

/**
 * Controlador REST para la gestión de asignaciones de supervisores.
 * Permite al administrador crear, listar, actualizar y eliminar asignaciones,
 * y al supervisor consultar su propia asignación.
 */
@RestController
@RequestMapping("/api/supervisor-assignments")
public class SupervisorAssignmentController {

    @Autowired
    private ISupervisorAssignmentService supervisorAssignmentService;

    @Autowired
    private UsuarioService usuarioService;

    /**
     * GET /api/supervisor-assignments
     * Lista todas las asignaciones de supervisores.
     */
    @Secured("ROLE_ADMIN")
    @GetMapping
    public ResponseEntity<?> findAll() {
        try {
            List<SupervisorAssignmentResponse> assignments = supervisorAssignmentService.findAll();
            return new ResponseEntity<>(assignments, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * POST /api/supervisor-assignments
     * Crea una nueva asignación de supervisor a un tipo de asignación.
     */
    @Secured("ROLE_ADMIN")
    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody SupervisorAssignmentRequest request) {
        Map<String, Object> response = new HashMap<>();

        try {
            SupervisorAssignmentResponse assignment = supervisorAssignmentService.create(request);
            return new ResponseEntity<>(assignment, HttpStatus.CREATED);
        } catch (AssignmentAlreadyExistsException e) {
            response.put("error", "ASSIGNMENT_ALREADY_EXISTS");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.CONFLICT);
        } catch (AssignmentTypeNotFoundException e) {
            response.put("error", "ASSIGNMENT_TYPE_NOT_FOUND");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * PUT /api/supervisor-assignments/{userId}
     * Cambia el tipo de asignación de un supervisor.
     */
    @Secured("ROLE_ADMIN")
    @PutMapping("/{userId}")
    public ResponseEntity<?> updateAssignment(@PathVariable Long userId, @RequestBody Map<String, Long> request) {
        Map<String, Object> response = new HashMap<>();

        Long assignmentTypeId = request.get("assignmentTypeId");
        if (assignmentTypeId == null) {
            response.put("error", "El campo assignmentTypeId es obligatorio");
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        try {
            SupervisorAssignmentResponse assignment = supervisorAssignmentService.updateAssignment(userId, assignmentTypeId);
            return new ResponseEntity<>(assignment, HttpStatus.OK);
        } catch (NoAssignmentConfiguredException e) {
            response.put("error", "NO_ASSIGNMENT_CONFIGURED");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (AssignmentTypeNotFoundException e) {
            response.put("error", "ASSIGNMENT_TYPE_NOT_FOUND");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * DELETE /api/supervisor-assignments/{userId}
     * Elimina la asignación de un supervisor.
     */
    @Secured("ROLE_ADMIN")
    @DeleteMapping("/{userId}")
    public ResponseEntity<?> deleteByUserId(@PathVariable Long userId) {
        Map<String, Object> response = new HashMap<>();

        try {
            supervisorAssignmentService.deleteByUserId(userId);
            response.put("mensaje", "Asignación eliminada exitosamente");
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/supervisor-assignments/me
     * Obtiene la asignación del asesor autenticado.
     */
    @Secured("ROLE_ASESOR")
    @GetMapping("/me")
    public ResponseEntity<?> getMyAssignment() {
        Map<String, Object> response = new HashMap<>();

        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String email = authentication.getName();

            UserEntity user = usuarioService.findByemail(email);
            if (user == null) {
                response.put("error", "Usuario no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }

            SupervisorAssignmentResponse assignment = supervisorAssignmentService.findByUserId(user.getId());
            return new ResponseEntity<>(assignment, HttpStatus.OK);
        } catch (NoAssignmentConfiguredException e) {
            // El asesor no tiene campaña asignada — retornar 200 con null
            return new ResponseEntity<>(null, HttpStatus.OK);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
