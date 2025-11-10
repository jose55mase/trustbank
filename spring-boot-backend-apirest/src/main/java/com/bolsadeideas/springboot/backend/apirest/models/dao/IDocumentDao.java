package com.bolsadeideas.springboot.backend.apirest.models.dao;

import com.bolsadeideas.springboot.backend.apirest.models.entity.DocumentEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface IDocumentDao extends JpaRepository<DocumentEntity, Long> {
    
    List<DocumentEntity> findByUserId(Long userId);
    
    @Query("SELECT d FROM DocumentEntity d WHERE d.status = 'PENDING'")
    List<DocumentEntity> findPendingDocuments();
    
    List<DocumentEntity> findByStatus(String status);
}