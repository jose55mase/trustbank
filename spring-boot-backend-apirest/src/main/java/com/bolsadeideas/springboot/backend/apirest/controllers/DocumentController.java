package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.DocumentEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IDocumentService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IUploadFileService;
import com.bolsadeideas.springboot.backend.apirest.utils.RestResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:4200", "http://localhost:8080"})
@RestController
@RequestMapping("/api/documents")
public class DocumentController {

    @Autowired
    private IDocumentService documentService;

    @Autowired
    private IUploadFileService uploadService;

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
}