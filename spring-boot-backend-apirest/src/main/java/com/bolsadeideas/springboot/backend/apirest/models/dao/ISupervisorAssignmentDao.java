package com.bolsadeideas.springboot.backend.apirest.models.dao;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.bolsadeideas.springboot.backend.apirest.models.entity.SupervisorAssignmentEntity;

public interface ISupervisorAssignmentDao extends JpaRepository<SupervisorAssignmentEntity, Long> {

    Optional<SupervisorAssignmentEntity> findByUserId(Long userId);

    List<SupervisorAssignmentEntity> findByAssignmentTypeId(Long assignmentTypeId);

    Long countByAssignmentTypeId(Long assignmentTypeId);

    void deleteByUserId(Long userId);

    boolean existsByUserId(Long userId);
}
