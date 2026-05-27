package com.bolsadeideas.springboot.backend.apirest.models.dao;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.bolsadeideas.springboot.backend.apirest.models.entity.RoleModulePermissionEntity;

public interface IRoleModulePermissionDao extends JpaRepository<RoleModulePermissionEntity, Long> {

    List<RoleModulePermissionEntity> findByRoleIdAndModuleId(Long roleId, Long moduleId);

    Optional<RoleModulePermissionEntity> findByRoleIdAndModuleIdAndActionCode(Long roleId, Long moduleId, String actionCode);

    void deleteByRoleIdAndModuleId(Long roleId, Long moduleId);
}
