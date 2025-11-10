package com.bolsadeideas.springboot.backend.apirest.models.services.intefaces;

import com.bolsadeideas.springboot.backend.apirest.models.entity.AdminRequestEntity;

import java.util.List;

public interface IAdminRequestService {
    
    AdminRequestEntity save(AdminRequestEntity request);
    
    AdminRequestEntity findById(Long id);
    
    List<AdminRequestEntity> findAll();
    
    List<AdminRequestEntity> findByUserId(Long userId);
    
    List<AdminRequestEntity> findPendingRequests();
    
    List<AdminRequestEntity> findByStatus(String status);
    
    List<AdminRequestEntity> findByRequestType(String requestType);
    
    void delete(Long id);
}