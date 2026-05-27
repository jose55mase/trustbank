package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.exceptions.DuplicateRoleNameException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.RoleHasUsersException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.RoleNotFoundException;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IModuleDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IUserDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.RolDao;
import com.bolsadeideas.springboot.backend.apirest.models.dto.ModuleAssignmentResponse;
import com.bolsadeideas.springboot.backend.apirest.models.dto.ModuleResponse;
import com.bolsadeideas.springboot.backend.apirest.models.dto.RolRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.RolResponse;
import com.bolsadeideas.springboot.backend.apirest.models.dto.RoleConfigResponse;
import com.bolsadeideas.springboot.backend.apirest.models.entity.ModuleEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IPermissionService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IRolService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
public class RolServiceImpl implements IRolService {

    private static final String LEADS_MODULE_CODE = "LEADS";

    @Autowired
    private RolDao rolDao;

    @Autowired
    private IModuleDao moduleDao;

    @Autowired
    private IUserDao userDao;

    @Autowired
    private IPermissionService permissionService;

    @Override
    @Transactional(readOnly = true)
    public List<RolResponse> findAll() {
        List<RolEntity> roles = StreamSupport
                .stream(rolDao.findAll().spliterator(), false)
                .collect(Collectors.toList());

        return roles.stream()
                .map(this::toRolResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public RolResponse findById(Long id) {
        RolEntity role = rolDao.findById(id)
                .orElseThrow(RoleNotFoundException::new);
        return toRolResponse(role);
    }

    @Override
    @Transactional
    public RolResponse create(RolRequest request) {
        // Validate duplicate name
        Optional<RolEntity> existing = rolDao.findByName(request.getName());
        if (existing.isPresent()) {
            throw new DuplicateRoleNameException();
        }

        RolEntity role = new RolEntity();
        role.setName(request.getName());
        RolEntity saved = rolDao.save(role);
        return toRolResponse(saved);
    }

    @Override
    @Transactional
    public RolResponse update(Long id, RolRequest request) {
        RolEntity role = rolDao.findById(id)
                .orElseThrow(RoleNotFoundException::new);

        // Validate duplicate name (exclude current role)
        Optional<RolEntity> existing = rolDao.findByName(request.getName());
        if (existing.isPresent() && !existing.get().getId().equals(id)) {
            throw new DuplicateRoleNameException();
        }

        role.setName(request.getName());
        RolEntity saved = rolDao.save(role);
        return toRolResponse(saved);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        RolEntity role = rolDao.findById(id)
                .orElseThrow(RoleNotFoundException::new);

        Long userCount = rolDao.countUsersByRoleId(id);
        if (userCount > 0) {
            throw new RoleHasUsersException(userCount);
        }

        rolDao.delete(role);
    }

    @Override
    @Transactional
    public void sava(RolEntity rolEntity) {
        rolDao.save(rolEntity);
    }

    @Override
    @Transactional
    public RolResponse updateRoleModules(Long roleId, List<Long> moduleIds) {
        RolEntity role = rolDao.findById(roleId)
                .orElseThrow(RoleNotFoundException::new);

        // Capture previously assigned modules to detect additions/removals
        Set<Long> previousModuleIds = role.getModules() != null
                ? role.getModules().stream().map(ModuleEntity::getId).collect(Collectors.toSet())
                : new HashSet<>();

        List<ModuleEntity> newModules = moduleDao.findAllById(moduleIds);
        Set<Long> newModuleIds = newModules.stream()
                .map(ModuleEntity::getId)
                .collect(Collectors.toSet());

        role.setModules(new HashSet<>(newModules));
        RolEntity saved = rolDao.save(role);

        // Handle LEADS module permission lifecycle
        handleLeadsModulePermissions(roleId, previousModuleIds, newModuleIds, newModules);

        return toRolResponse(saved);
    }

    /**
     * Handles initialization/cleanup of granular permissions when the LEADS module
     * is assigned to or removed from a role.
     */
    private void handleLeadsModulePermissions(Long roleId, Set<Long> previousModuleIds,
                                               Set<Long> newModuleIds, List<ModuleEntity> newModules) {
        // Find the LEADS module among the new modules or look it up
        ModuleEntity leadsModule = newModules.stream()
                .filter(m -> LEADS_MODULE_CODE.equals(m.getCode()))
                .findFirst()
                .orElse(null);

        // Determine if LEADS was previously assigned
        boolean hadLeads = false;
        if (leadsModule != null) {
            hadLeads = previousModuleIds.contains(leadsModule.getId());
        } else {
            // LEADS is not in the new set; check if it was in the previous set
            // We need to find the LEADS module to get its ID
            ModuleEntity leadsModuleLookup = moduleDao.findByCode(LEADS_MODULE_CODE);
            if (leadsModuleLookup != null) {
                hadLeads = previousModuleIds.contains(leadsModuleLookup.getId());
                if (hadLeads) {
                    leadsModule = leadsModuleLookup;
                }
            }
        }

        boolean hasLeadsNow = leadsModule != null && newModuleIds.contains(leadsModule.getId());

        if (!hadLeads && hasLeadsNow) {
            // LEADS module was just assigned — initialize default permissions
            permissionService.initializeDefaultPermissions(roleId, leadsModule.getId());
        } else if (hadLeads && !hasLeadsNow) {
            // LEADS module was just removed — delete all permissions
            permissionService.deletePermissionsForRoleModule(roleId, leadsModule.getId());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public RoleConfigResponse getRoleConfig(Long roleId) {
        RolEntity role = rolDao.findById(roleId)
                .orElseThrow(RoleNotFoundException::new);

        List<ModuleEntity> allModules = moduleDao.findAllByOrderByDisplayOrderAsc();
        Set<Long> assignedModuleIds = role.getModules().stream()
                .map(ModuleEntity::getId)
                .collect(Collectors.toSet());

        List<ModuleAssignmentResponse> moduleAssignments = allModules.stream()
                .map(module -> new ModuleAssignmentResponse(
                        module.getId(),
                        module.getCode(),
                        module.getName(),
                        module.getDescription(),
                        module.getIcon(),
                        assignedModuleIds.contains(module.getId())
                ))
                .collect(Collectors.toList());

        return new RoleConfigResponse(role.getId(), role.getName(), moduleAssignments);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ModuleResponse> getUserModules(Long userId) {
        UserEntity user = userDao.findByid(userId);
        if (user == null) {
            return new ArrayList<>();
        }

        Set<ModuleEntity> userModules = new LinkedHashSet<>();
        if (user.getRols() != null) {
            for (RolEntity role : user.getRols()) {
                if (role.getModules() != null) {
                    userModules.addAll(role.getModules());
                }
            }
        }

        return userModules.stream()
                .sorted(Comparator.comparingInt(m -> m.getDisplayOrder() != null ? m.getDisplayOrder() : 0))
                .map(this::toModuleResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public Map<String, Object> assignRoleToUser(Long userId, Long roleId) {
        // Validate user exists
        UserEntity user = userDao.findByid(userId);
        if (user == null) {
            throw new RuntimeException("USER_NOT_FOUND");
        }

        // Validate role exists
        RolEntity role = rolDao.findById(roleId)
                .orElseThrow(RoleNotFoundException::new);

        // Clear existing roles and assign the new one
        user.getRols().clear();
        user.getRols().add(role);
        UserEntity savedUser = userDao.save(user);

        // Build response
        Map<String, Object> result = new HashMap<>();
        result.put("userId", savedUser.getId());
        result.put("email", savedUser.getEmail());
        result.put("role", toRolResponse(role));
        result.put("message", "Rol asignado exitosamente");
        return result;
    }

    /**
     * Convierte un RolEntity a RolResponse DTO, incluyendo módulos y conteo de usuarios.
     */
    private RolResponse toRolResponse(RolEntity entity) {
        List<ModuleResponse> modules = new ArrayList<>();
        if (entity.getModules() != null) {
            modules = entity.getModules().stream()
                    .map(this::toModuleResponse)
                    .collect(Collectors.toList());
        }

        Long userCount = rolDao.countUsersByRoleId(entity.getId());

        return new RolResponse(
                entity.getId(),
                entity.getName(),
                modules,
                userCount != null ? userCount.intValue() : 0
        );
    }

    /**
     * Convierte un ModuleEntity a ModuleResponse DTO.
     */
    private ModuleResponse toModuleResponse(ModuleEntity entity) {
        return new ModuleResponse(
                entity.getId(),
                entity.getCode(),
                entity.getName(),
                entity.getDescription(),
                entity.getIcon(),
                entity.getDisplayOrder()
        );
    }
}
