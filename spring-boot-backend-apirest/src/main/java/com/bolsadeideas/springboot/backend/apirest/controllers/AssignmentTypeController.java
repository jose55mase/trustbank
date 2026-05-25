package com.bolsadeideas.springboot.backend.apirest.controllers;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.annotation.Secured;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.bolsadeideas.springboot.backend.apirest.exceptions.AssignmentTypeHasSupervisorsException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.AssignmentTypeNotFoundException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.DuplicateAssignmentTypeException;
import com.bolsadeideas.springboot.backend.apirest.models.dto.AssignmentTypeRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.AssignmentTypeResponse;
import com.bolsadeideas.springboot.backend.apirest.models.services.IAssignmentTypeService;

/**
 * Controlador REST para la gestión de Tipos de Asignación.
 * Todos los endpoints requieren rol de administrador.
 */
@RestController
@RequestMapping("/api/assignment-types")
public class AssignmentTypeController {

    @Autowired
    private IAssignmentTypeService assignmentTypeService;

    /**
     * GET /api/assignment-types
     * Lista todos los tipos de asignación con conteo de supervisores.
     */
    @Secured("ROLE_ADMIN")
    @GetMapping
    public ResponseEntity<?> findAll() {
        try {
            List<AssignmentTypeResponse> types = assignmentTypeService.findAll();
            return new ResponseEntity<>(types, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/assignment-types/active
     * Lista solo los tipos de asignación activos.
     */
    @Secured("ROLE_ADMIN")
    @GetMapping("/active")
    public ResponseEntity<?> findActive() {
        try {
            List<AssignmentTypeResponse> types = assignmentTypeService.findActive();
            return new ResponseEntity<>(types, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/assignment-types/{id}
     * Obtiene un tipo de asignación por su ID.
     */
    @Secured("ROLE_ADMIN")
    @GetMapping("/{id}")
    public ResponseEntity<?> findById(@PathVariable Long id) {
        Map<String, Object> response = new HashMap<>();

        try {
            AssignmentTypeResponse type = assignmentTypeService.findById(id);
            return new ResponseEntity<>(type, HttpStatus.OK);
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
     * POST /api/assignment-types
     * Crea un nuevo tipo de asignación con validación.
     */
    @Secured("ROLE_ADMIN")
    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody AssignmentTypeRequest request) {
        Map<String, Object> response = new HashMap<>();

        try {
            AssignmentTypeResponse created = assignmentTypeService.create(request);
            return new ResponseEntity<>(created, HttpStatus.CREATED);
        } catch (DuplicateAssignmentTypeException e) {
            response.put("error", "DUPLICATE_ASSIGNMENT_TYPE");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * PUT /api/assignment-types/{id}
     * Actualiza un tipo de asignación existente.
     */
    @Secured("ROLE_ADMIN")
    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @Valid @RequestBody AssignmentTypeRequest request) {
        Map<String, Object> response = new HashMap<>();

        try {
            AssignmentTypeResponse updated = assignmentTypeService.update(id, request);
            return new ResponseEntity<>(updated, HttpStatus.OK);
        } catch (AssignmentTypeNotFoundException e) {
            response.put("error", "ASSIGNMENT_TYPE_NOT_FOUND");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (DuplicateAssignmentTypeException e) {
            response.put("error", "DUPLICATE_ASSIGNMENT_TYPE");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * DELETE /api/assignment-types/{id}
     * Elimina un tipo de asignación. Rechaza si tiene supervisores asociados.
     */
    @Secured("ROLE_ADMIN")
    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        Map<String, Object> response = new HashMap<>();

        try {
            assignmentTypeService.delete(id);
            response.put("mensaje", "Tipo de asignación eliminado exitosamente");
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (AssignmentTypeNotFoundException e) {
            response.put("error", "ASSIGNMENT_TYPE_NOT_FOUND");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (AssignmentTypeHasSupervisorsException e) {
            response.put("error", "ASSIGNMENT_TYPE_HAS_SUPERVISORS");
            response.put("message", e.getMessage());
            response.put("supervisorCount", e.getSupervisorCount());
            return new ResponseEntity<>(response, HttpStatus.CONFLICT);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
