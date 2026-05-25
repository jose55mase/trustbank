package com.bolsadeideas.springboot.backend.apirest.models.dao;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.bolsadeideas.springboot.backend.apirest.models.entity.AssignmentTypeEntity;

public interface IAssignmentTypeDao extends JpaRepository<AssignmentTypeEntity, Long> {

    List<AssignmentTypeEntity> findByActiveTrue();

    Optional<AssignmentTypeEntity> findByName(String name);

    boolean existsByName(String name);
}
