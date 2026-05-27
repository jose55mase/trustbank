package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.models.dao.IModuleDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IRoleCampaignVisibilityDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IRoleModulePermissionDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IUserDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.RolDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IAssignmentTypeDao;
import com.bolsadeideas.springboot.backend.apirest.models.dto.ActionPermissionDto;
import com.bolsadeideas.springboot.backend.apirest.models.dto.UserPermissionsDto;
import com.bolsadeideas.springboot.backend.apirest.models.entity.AssignmentTypeEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.ModuleEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.RoleCampaignVisibilityEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.RoleModulePermissionEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IPermissionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class PermissionServiceImpl implements IPermissionService {

    private static final List<String> DEFAULT_ACTION_CODES = Arrays.asList(
            "ASSIGN_ADVISOR",
            "UNASSIGN_ADVISOR",
            "IMPORT_EXCEL",
            "EXPORT_EXCEL",
            "EDIT_LEADS",
            "DELETE_LEADS"
    );

    @Autowired
    private IRoleModulePermissionDao roleModulePermissionDao;

    @Autowired
    private IRoleCampaignVisibilityDao roleCampaignVisibilityDao;

    @Autowired
    private IModuleDao moduleDao;

    @Autowired
    private RolDao rolDao;

    @Autowired
    private IUserDao userDao;

    @Autowired
    private IAssignmentTypeDao assignmentTypeDao;

    @Override
    @Transactional(readOnly = true)
    public List<ActionPermissionDto> getActionPermissions(Long roleId, String moduleCode) {
        ModuleEntity module = moduleDao.findByCode(moduleCode);
        if (module == null) {
            return new ArrayList<>();
        }

        List<RoleModulePermissionEntity> permissions = roleModulePermissionDao
                .findByRoleIdAndModuleId(roleId, module.getId());

        return permissions.stream()
                .map(p -> new ActionPermissionDto(p.getActionCode(), p.getEnabled()))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void updateActionPermission(Long roleId, String moduleCode, String actionCode, boolean enabled) {
        ModuleEntity module = moduleDao.findByCode(moduleCode);
        if (module == null) {
            throw new RuntimeException("INVALID_MODULE_CODE");
        }

        Optional<RoleModulePermissionEntity> permissionOpt = roleModulePermissionDao
                .findByRoleIdAndModuleIdAndActionCode(roleId, module.getId(), actionCode);

        if (permissionOpt.isPresent()) {
            RoleModulePermissionEntity permission = permissionOpt.get();
            permission.setEnabled(enabled);
            roleModulePermissionDao.save(permission);
        } else {
            throw new RuntimeException("PERMISSION_NOT_FOUND");
        }
    }

    @Override
    @Transactional
    public void initializeDefaultPermissions(Long roleId, Long moduleId) {
        RolEntity role = rolDao.findById(roleId)
                .orElseThrow(() -> new RuntimeException("ROLE_NOT_FOUND"));

        ModuleEntity module = moduleDao.findById(moduleId)
                .orElseThrow(() -> new RuntimeException("MODULE_NOT_FOUND"));

        for (String actionCode : DEFAULT_ACTION_CODES) {
            RoleModulePermissionEntity permission = new RoleModulePermissionEntity();
            permission.setRole(role);
            permission.setModule(module);
            permission.setActionCode(actionCode);
            permission.setEnabled(true);
            roleModulePermissionDao.save(permission);
        }
    }

    @Override
    @Transactional
    public void deletePermissionsForRoleModule(Long roleId, Long moduleId) {
        roleModulePermissionDao.deleteByRoleIdAndModuleId(roleId, moduleId);
        roleCampaignVisibilityDao.deleteByRoleId(roleId);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean hasActionPermission(Long userId, String moduleCode, String actionCode) {
        UserEntity user = userDao.findByid(userId);
        if (user == null || user.getRols() == null || user.getRols().isEmpty()) {
            return false;
        }

        ModuleEntity module = moduleDao.findByCode(moduleCode);
        if (module == null) {
            return false;
        }

        // Check permission for the user's first role (users have a single role in this system)
        RolEntity role = user.getRols().get(0);

        Optional<RoleModulePermissionEntity> permissionOpt = roleModulePermissionDao
                .findByRoleIdAndModuleIdAndActionCode(role.getId(), module.getId(), actionCode);

        return permissionOpt.map(RoleModulePermissionEntity::getEnabled).orElse(false);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Long> getVisibleCampaignIds(Long roleId) {
        List<RoleCampaignVisibilityEntity> visibilityRecords = roleCampaignVisibilityDao.findByRoleId(roleId);

        return visibilityRecords.stream()
                .map(v -> v.getCampaign().getId())
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void updateCampaignVisibility(Long roleId, List<Long> campaignIds) {
        RolEntity role = rolDao.findById(roleId)
                .orElseThrow(() -> new RuntimeException("ROLE_NOT_FOUND"));

        // Delete existing visibility records for this role and flush to DB
        roleCampaignVisibilityDao.deleteByRoleId(roleId);
        roleCampaignVisibilityDao.flush();

        // Create new visibility records
        for (Long campaignId : campaignIds) {
            AssignmentTypeEntity campaign = assignmentTypeDao.findById(campaignId)
                    .orElseThrow(() -> new RuntimeException("CAMPAIGN_NOT_FOUND"));

            RoleCampaignVisibilityEntity visibility = new RoleCampaignVisibilityEntity();
            visibility.setRole(role);
            visibility.setCampaign(campaign);
            roleCampaignVisibilityDao.save(visibility);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<Long> getUserVisibleCampaignIds(Long userId) {
        UserEntity user = userDao.findByid(userId);
        if (user == null || user.getRols() == null || user.getRols().isEmpty()) {
            return new ArrayList<>();
        }

        RolEntity role = user.getRols().get(0);
        return getVisibleCampaignIds(role.getId());
    }

    @Override
    @Transactional(readOnly = true)
    public UserPermissionsDto getUserPermissions(Long userId, String moduleCode) {
        UserEntity user = userDao.findByid(userId);
        if (user == null || user.getRols() == null || user.getRols().isEmpty()) {
            return new UserPermissionsDto(moduleCode, new HashMap<>(), new ArrayList<>());
        }

        RolEntity role = user.getRols().get(0);

        // Get action permissions
        List<ActionPermissionDto> actionPermissions = getActionPermissions(role.getId(), moduleCode);
        Map<String, Boolean> actionsMap = actionPermissions.stream()
                .collect(Collectors.toMap(
                        ActionPermissionDto::getActionCode,
                        ActionPermissionDto::getEnabled
                ));

        // Get visible campaign IDs
        List<Long> visibleCampaignIds = getVisibleCampaignIds(role.getId());

        return new UserPermissionsDto(moduleCode, actionsMap, visibleCampaignIds);
    }
}
