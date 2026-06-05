package com.bolsadeideas.springboot.backend.apirest.controllers;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import javax.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.bolsadeideas.springboot.backend.apirest.exceptions.ForbiddenOperationException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.ResourceNotFoundException;
import com.bolsadeideas.springboot.backend.apirest.models.dao.ILeadDao;
import com.bolsadeideas.springboot.backend.apirest.models.dto.LeadCommentRequest;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadCommentEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.ILeadCommentService;
import com.bolsadeideas.springboot.backend.apirest.models.services.UsuarioService;

/**
 * Controlador REST para la gestión de comentarios de Leads.
 * Permite crear, listar, editar y eliminar comentarios con autoría protegida.
 * Solo el autor de un comentario puede editarlo o eliminarlo.
 */
@RestController
@RequestMapping("/api/leads/{leadId}/comments")
public class LeadCommentController {

    @Autowired
    private ILeadCommentService leadCommentService;

    @Autowired
    private ILeadDao leadDao;

    @Autowired
    private UsuarioService usuarioService;

    /**
     * GET /api/leads/{leadId}/comments
     * Retorna el comentario legacy (del campo comentarios del lead) junto con los comentarios con autoría.
     */
    @GetMapping
    public ResponseEntity<?> getComments(@PathVariable Long leadId) {
        Map<String, Object> response = new HashMap<>();

        try {
            // Validate lead exists
            LeadEntity lead = leadDao.findById(leadId).orElseThrow(
                    () -> new ResourceNotFoundException("lead", leadId));

            // Build legacy comment object (if non-null and non-empty)
            Map<String, Object> legacyComment = null;
            String comentarios = lead.getComentarios();
            if (comentarios != null && !comentarios.trim().isEmpty()) {
                legacyComment = new HashMap<>();
                legacyComment.put("text", comentarios);
                legacyComment.put("isLegacy", true);
            }

            // Get authored comments ordered by createdAt ASC
            List<LeadCommentEntity> authoredComments = leadCommentService.findByLeadId(leadId);

            // Build response DTOs with authorName
            List<Map<String, Object>> commentDtos = authoredComments.stream().map(comment -> {
                Map<String, Object> dto = new HashMap<>();
                dto.put("id", comment.getId());
                dto.put("leadId", comment.getLeadId());
                dto.put("userId", comment.getUser().getId());
                dto.put("authorName", buildAuthorName(comment.getUser()));
                dto.put("text", comment.getText());
                dto.put("createdAt", comment.getCreatedAt());
                dto.put("editedAt", comment.getEditedAt());
                dto.put("isLegacy", false);
                return dto;
            }).collect(Collectors.toList());

            response.put("legacyComment", legacyComment);
            response.put("comments", commentDtos);

            return new ResponseEntity<>(response, HttpStatus.OK);

        } catch (ResourceNotFoundException e) {
            response.put("error", e.getMessage());
            response.put("status", 404);
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        }
    }

    /**
     * POST /api/leads/{leadId}/comments
     * Crea un nuevo comentario para el lead. El userId se extrae del SecurityContext.
     */
    @PostMapping
    public ResponseEntity<?> createComment(@PathVariable Long leadId,
                                           @Valid @RequestBody LeadCommentRequest request,
                                           BindingResult result) {
        Map<String, Object> response = new HashMap<>();

        // Handle validation errors
        if (result.hasErrors()) {
            String errorMessage = result.getFieldErrors().stream()
                    .map(err -> err.getDefaultMessage())
                    .findFirst()
                    .orElse("Error de validación");
            response.put("error", errorMessage);
            response.put("status", 400);
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        try {
            Long userId = getAuthenticatedUserId();

            LeadCommentEntity created = leadCommentService.create(leadId, userId, request.getText());

            // Build response DTO
            Map<String, Object> dto = buildCommentDto(created);
            return new ResponseEntity<>(dto, HttpStatus.CREATED);

        } catch (ResourceNotFoundException e) {
            response.put("error", e.getMessage());
            response.put("status", 404);
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        }
    }

    /**
     * PUT /api/leads/{leadId}/comments/{commentId}
     * Edita un comentario existente. Solo el autor puede editarlo.
     */
    @PutMapping("/{commentId}")
    public ResponseEntity<?> updateComment(@PathVariable Long leadId,
                                           @PathVariable Long commentId,
                                           @Valid @RequestBody LeadCommentRequest request,
                                           BindingResult result) {
        Map<String, Object> response = new HashMap<>();

        // Handle validation errors
        if (result.hasErrors()) {
            String errorMessage = result.getFieldErrors().stream()
                    .map(err -> err.getDefaultMessage())
                    .findFirst()
                    .orElse("Error de validación");
            response.put("error", errorMessage);
            response.put("status", 400);
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        try {
            Long userId = getAuthenticatedUserId();

            LeadCommentEntity updated = leadCommentService.update(commentId, userId, request.getText());

            // Build response DTO
            Map<String, Object> dto = buildCommentDto(updated);
            return new ResponseEntity<>(dto, HttpStatus.OK);

        } catch (ResourceNotFoundException e) {
            response.put("error", e.getMessage());
            response.put("status", 404);
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (ForbiddenOperationException e) {
            response.put("error", e.getMessage());
            response.put("status", 403);
            return new ResponseEntity<>(response, HttpStatus.FORBIDDEN);
        }
    }

    /**
     * DELETE /api/leads/{leadId}/comments/{commentId}
     * Elimina un comentario existente. Solo el autor puede eliminarlo.
     */
    @DeleteMapping("/{commentId}")
    public ResponseEntity<?> deleteComment(@PathVariable Long leadId,
                                           @PathVariable Long commentId) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getAuthenticatedUserId();

            leadCommentService.delete(commentId, userId);

            return new ResponseEntity<>(HttpStatus.NO_CONTENT);

        } catch (ResourceNotFoundException e) {
            response.put("error", e.getMessage());
            response.put("status", 404);
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (ForbiddenOperationException e) {
            response.put("error", e.getMessage());
            response.put("status", 403);
            return new ResponseEntity<>(response, HttpStatus.FORBIDDEN);
        }
    }

    /**
     * Extrae el ID del usuario autenticado desde el SecurityContextHolder.
     * El Authentication.getName() retorna el email del usuario.
     */
    private Long getAuthenticatedUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        UserEntity user = usuarioService.findByemail(email);
        return user.getId();
    }

    /**
     * Construye el nombre completo del autor a partir del UserEntity.
     */
    private String buildAuthorName(UserEntity user) {
        if (user == null) {
            return "Usuario";
        }
        String firstName = user.getFistName();
        String lastName = user.getLastName();
        StringBuilder name = new StringBuilder();
        if (firstName != null && !firstName.trim().isEmpty()) {
            name.append(firstName.trim());
        }
        if (lastName != null && !lastName.trim().isEmpty()) {
            if (name.length() > 0) {
                name.append(" ");
            }
            name.append(lastName.trim());
        }
        return name.length() > 0 ? name.toString() : "Usuario";
    }

    /**
     * Construye un DTO de respuesta para un comentario con autoría.
     */
    private Map<String, Object> buildCommentDto(LeadCommentEntity comment) {
        Map<String, Object> dto = new HashMap<>();
        dto.put("id", comment.getId());
        dto.put("leadId", comment.getLeadId());
        dto.put("userId", comment.getUser().getId());
        dto.put("authorName", buildAuthorName(comment.getUser()));
        dto.put("text", comment.getText());
        dto.put("createdAt", comment.getCreatedAt());
        dto.put("editedAt", comment.getEditedAt());
        dto.put("isLegacy", false);
        return dto;
    }
}
