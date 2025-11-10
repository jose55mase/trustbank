package com.bolsadeideas.springboot.backend.apirest.models.dao;

import com.bolsadeideas.springboot.backend.apirest.models.entity.CreditEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ICreditDao extends JpaRepository<CreditEntity, Long> {
    List<CreditEntity> findByUserId(Long userId);
    List<CreditEntity> findByStatus(String status);
}