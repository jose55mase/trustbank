package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.DocumentEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IDocumentService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IUploadFileService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IUserService;
import com.bolsadeideas.springboot.backend.apirest.utils.RestResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Base64;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/documents")
public class DocumentController {

    @Autowired
    private IDocumentService documentService;

    @Autowired
    private IUploadFileService uploadService;
    
    @Autowired
    private IUserService userService;

    @PostMapping("/upload")
    public ResponseEntity<?> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @RequestParam("userId") Long userId,
            @RequestParam("documentType") String documentType) {
        
        Map<String, Object> response = new HashMap<>();
        
        if (file.isEmpty()) {
            response.put("error", "Archivo vacío");
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        try {
            String fileName = uploadService.copiar(file);
            
            DocumentEntity document = new DocumentEntity();
            document.setUserId(userId);
            document.setDocumentType(documentType);
            document.setFileName(fileName);
            document.setFilePath("/uploads/" + fileName);
            
            DocumentEntity savedDocument = documentService.save(document);
            
            response.put("document", savedDocument);
            response.put("message", "Documento subido exitosamente");
            
            return new ResponseEntity<>(response, HttpStatus.CREATED);
            
        } catch (IOException e) {
            response.put("error", "Error al subir el archivo: " + e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/user/{userId}")
    public RestResponse getDocumentsByUser(@PathVariable Long userId) {
        List<DocumentEntity> documents = documentService.findByUserId(userId);
        return new RestResponse(HttpStatus.OK.value(), "Documentos obtenidos", documents);
    }

    @GetMapping("/pending")
    public RestResponse getPendingDocuments() {
        List<DocumentEntity> documents = documentService.findPendingDocuments();
        return new RestResponse(HttpStatus.OK.value(), "Documentos pendientes", documents);
    }

    @PutMapping("/process/{id}")
    public RestResponse processDocument(
            @PathVariable Long id,
            @RequestParam String status,
            @RequestParam(required = false) String adminNotes) {
        
        DocumentEntity document = documentService.findById(id);
        if (document == null) {
            return new RestResponse(HttpStatus.NOT_FOUND.value(), "Documento no encontrado", null);
        }

        document.setStatus(status);
        document.setProcessedAt(new Date());
        if (adminNotes != null) {
            document.setAdminNotes(adminNotes);
        }

        DocumentEntity updatedDocument = documentService.save(document);
        return new RestResponse(HttpStatus.OK.value(), "Documento procesado", updatedDocument);
    }

    @GetMapping("/status/{status}")
    public RestResponse getDocumentsByStatus(@PathVariable String status) {
        List<DocumentEntity> documents = documentService.findByStatus(status);
        return new RestResponse(HttpStatus.OK.value(), "Documentos por estado", documents);
    }
    
    @PostMapping("/users/{userId}/images")
    public ResponseEntity<?> uploadUserDocuments(
            @PathVariable Long userId,
            @RequestParam(required = false) MultipartFile documentFrom,
            @RequestParam(required = false) MultipartFile documentBack,
            @RequestParam(required = false) MultipartFile foto) {
        
        try {
            UserEntity user = userService.findById(userId);
            if (user == null) {
                return ResponseEntity.notFound().build();
            }

            if (documentFrom != null) {
                String base64Front = Base64.getEncoder().encodeToString(documentFrom.getBytes());
                user.setDocumentFrom(base64Front);
                user.setDocumentFromStatus("PENDING");
            }

            if (documentBack != null) {
                String base64Back = Base64.getEncoder().encodeToString(documentBack.getBytes());
                user.setDocumentBack(base64Back);
                user.setDocumentBackStatus("PENDING");
            }

            if (foto != null) {
                String base64Photo = Base64.getEncoder().encodeToString(foto.getBytes());
                user.setFoto(base64Photo);
                user.setFotoStatus("PENDING");
            }

            userService.save(user);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Documentos subidos exitosamente");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Error al subir documentos: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PutMapping("/users/{userId}/status")
    public ResponseEntity<?> updateDocumentStatus(
            @PathVariable Long userId,
            @RequestBody Map<String, String> request) {
        
        try {
            UserEntity user = userService.findById(userId);
            if (user == null) {
                return ResponseEntity.notFound().build();
            }

            String documentType = request.get("documentType");
            String status = request.get("status");

            switch (documentType) {
                case "documentFront":
                    user.setDocumentFromStatus(status);
                    break;
                case "documentBack":
                    user.setDocumentBackStatus(status);
                    break;
                case "clientPhoto":
                    user.setFotoStatus(status);
                    break;
                default:
                    return ResponseEntity.badRequest().body("Tipo de documento inválido");
            }

            userService.save(user);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Estado actualizado exitosamente");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Error al actualizar estado: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @GetMapping("/users/{userId}/images")
    public ResponseEntity<?> getUserDocuments(@PathVariable Long userId) {
        try {
            UserEntity user = userService.findById(userId);
            if (user == null) {
                return ResponseEntity.notFound().build();
            }

            Map<String, Object> response = new HashMap<>();
            response.put("documentFrom", user.getDocumentFrom());
            response.put("documentBack", user.getDocumentBack());
            response.put("foto", user.getFoto());
            response.put("documentFromStatus", user.getDocumentFromStatus());
            response.put("documentBackStatus", user.getDocumentBackStatus());
            response.put("fotoStatus", user.getFotoStatus());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error al obtener documentos: " + e.getMessage());
        }
    }

    @GetMapping("/admin/users")
    public ResponseEntity<?> getAllUsersWithDocuments() {
        try {
            List<UserEntity> users = userService.findUsersWithDocuments();
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error al obtener usuarios: " + e.getMessage());
        }
    }
}