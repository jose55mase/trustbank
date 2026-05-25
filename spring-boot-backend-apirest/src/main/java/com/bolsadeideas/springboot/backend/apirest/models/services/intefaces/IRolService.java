package com.bolsadeideas.springboot.backend.apirest.models.services.intefaces;

import com.bolsadeideas.springboot.backend.apirest.models.dto.ModuleResponse;
import com.bolsadeideas.springboot.backend.apirest.models.dto.RolRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.RolResponse;
import com.bolsadeideas.springboot.backend.apirest.models.dto.RoleConfigResponse;
import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;

import java.util.List;
import java.util.Map;

public interface IRolService {

    List<RolResponse> findAll();

    RolResponse findById(Long id);

    RolResponse create(RolRequest request);

    RolResponse update(Long id, RolRequest request);

    void delete(Long id);

    void sava(RolEntity rolEntity);

    RolResponse updateRoleModules(Long roleId, List<Long> moduleIds);

    RoleConfigResponse getRoleConfig(Long roleId);

    List<ModuleResponse> getUserModules(Long userId);

    /**
     * Assigns a role to a user by role ID.
     * Validates that both the user and role exist.
     * @param userId the user ID
     * @param roleId the role ID to assign
     * @return a map with the updated user info and role details
     */
    Map<String, Object> assignRoleToUser(Long userId, Long roleId);
}
