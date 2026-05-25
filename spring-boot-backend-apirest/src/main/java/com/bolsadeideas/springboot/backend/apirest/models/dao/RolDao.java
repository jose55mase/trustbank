package com.bolsadeideas.springboot.backend.apirest.models.dao;

import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface RolDao extends CrudRepository<RolEntity, Long> {

    @Query("SELECT COUNT(u) FROM UserEntity u JOIN u.rols r WHERE r.id = :roleId")
    Long countUsersByRoleId(@Param("roleId") Long roleId);

    Optional<RolEntity> findByName(String name);

}
