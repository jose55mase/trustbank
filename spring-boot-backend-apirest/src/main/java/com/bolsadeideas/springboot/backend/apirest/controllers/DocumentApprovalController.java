package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.UsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/documents")
@CrossOrigin(origins = "*")
public class DocumentApprovalController {

    @Autowired
    private UsuarioService usuarioService;

    @GetMapping("/pending")
    public ResponseEntity<List<UserEntity>> getUsersWithPendingDocuments() {
        try {
            List<UserEntity> allUsers = usuarioService.findAll();
            List<UserEntity> usersWithPendingDocs = allUsers.stream()
                .filter(user -> hasPendingDocuments(user))
                .collect(Collectors.toList());
            return new ResponseEntity<>(usersWithPendingDocs, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<UserEntity> getUserDocuments(@PathVariable Long userId) {
        try {
            UserEntity user = usuarioService.findByid(userId);
            if (user != null) {
                return new ResponseEntity<>(user, HttpStatus.OK);
            } else {
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PutMapping("/approve/{userId}")
    public ResponseEntity<Map<String, Object>> approveDocument(
            @PathVariable Long userId,
            @RequestBody Map<String, String> request) {
        Map<String, Object> response = new HashMap<>();
        try {
            String documentType = request.get("documentType");
            String status = request.get("status"); // APPROVED, REJECTED
            String comments = request.get("comments");

            UserEntity user = usuarioService.findByid(userId);
            if (user == null) {
                response.put("success", false);
                response.put("message", "Usuario no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }

            // Actualizar el estado del documento específico
            switch (documentType) {
                case "foto":
                    user.setFotoStatus(status);
                    break;
                case "documentFrom":
                    user.setDocumentFromStatus(status);
                    break;
                case "documentBack":
                    user.setDocumentBackStatus(status);
                    break;
                default:
                    response.put("success", false);
                    response.put("message", "Tipo de documento inválido");
                    return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
            }

            usuarioService.save(user);

            response.put("success", true);
            response.put("message", "Documento " + (status.equals("APPROVED") ? "aprobado" : "rechazado") + " exitosamente");
            response.put("user", user);
            return new ResponseEntity<>(response, HttpStatus.OK);

        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getDocumentStats() {
        try {
            List<UserEntity> allUsers = usuarioService.findAll();
            
            Map<String, Object> stats = new HashMap<>();
            stats.put("totalUsers", allUsers.size());
            stats.put("pendingApproval", allUsers.stream().mapToLong(user -> countPendingDocuments(user)).sum());
            stats.put("approvedDocuments", allUsers.stream().mapToLong(user -> countApprovedDocuments(user)).sum());
            stats.put("rejectedDocuments", allUsers.stream().mapToLong(user -> countRejectedDocuments(user)).sum());
            
            return new ResponseEntity<>(stats, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private boolean hasPendingDocuments(UserEntity user) {
        return "PENDING".equals(user.getFotoStatus()) ||
               "PENDING".equals(user.getDocumentFromStatus()) ||
               "PENDING".equals(user.getDocumentBackStatus());
    }

    private long countPendingDocuments(UserEntity user) {
        long count = 0;
        if ("PENDING".equals(user.getFotoStatus())) count++;
        if ("PENDING".equals(user.getDocumentFromStatus())) count++;
        if ("PENDING".equals(user.getDocumentBackStatus())) count++;
        return count;
    }

    private long countApprovedDocuments(UserEntity user) {
        long count = 0;
        if ("APPROVED".equals(user.getFotoStatus())) count++;
        if ("APPROVED".equals(user.getDocumentFromStatus())) count++;
        if ("APPROVED".equals(user.getDocumentBackStatus())) count++;
        return count;
    }

    private long countRejectedDocuments(UserEntity user) {
        long count = 0;
        if ("REJECTED".equals(user.getFotoStatus())) count++;
        if ("REJECTED".equals(user.getDocumentFromStatus())) count++;
        if ("REJECTED".equals(user.getDocumentBackStatus())) count++;
        return count;
    }
}