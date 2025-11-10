package com.bolsadeideas.springboot.backend.apirest.models.dao;

import com.bolsadeideas.springboot.backend.apirest.models.entity.AdminRequestEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface IAdminRequestDao extends JpaRepository<AdminRequestEntity, Long> {
    
    List<AdminRequestEntity> findByUserId(Long userId);
    
    @Query("SELECT r FROM AdminRequestEntity r WHERE r.status = 'PENDING'")
    List<AdminRequestEntity> findPendingRequests();
    
    List<AdminRequestEntity> findByStatus(String status);
    
    List<AdminRequestEntity> findByRequestType(String requestType);
}