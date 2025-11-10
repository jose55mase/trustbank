package com.bolsadeideas.springboot.backend.apirest.models.services.intefaces;

import com.bolsadeideas.springboot.backend.apirest.models.entity.DocumentEntity;

import java.util.List;

public interface IDocumentService {
    
    DocumentEntity save(DocumentEntity document);
    
    DocumentEntity findById(Long id);
    
    List<DocumentEntity> findByUserId(Long userId);
    
    List<DocumentEntity> findPendingDocuments();
    
    List<DocumentEntity> findByStatus(String status);
    
    void delete(Long id);
}