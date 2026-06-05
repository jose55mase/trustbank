package com.bolsadeideas.springboot.backend.apirest.models.dao;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadCommentEntity;

public interface ILeadCommentDao extends JpaRepository<LeadCommentEntity, Long> {

    List<LeadCommentEntity> findByLeadIdOrderByCreatedAtDesc(Long leadId);

    LeadCommentEntity findFirstByLeadIdOrderByCreatedAtDesc(Long leadId);
}
