package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.dto.ActionPermissionDto;
import com.bolsadeideas.springboot.backend.apirest.models.dto.UpdateActionPermissionRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.UpdateCampaignVisibilityRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.UserPermissionsDto;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IPermissionService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IUserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.annotation.Secured;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Controlador REST para la gestión de permisos granulares por módulo.
 * Provee endpoints para consultar permisos del usuario actual,
 * gestionar permisos de acción por rol y configurar visibilidad de campañas.
 */
@RestController
@RequestMapping("/api")
public class PermissionController {

    @Autowired
    private IPermissionService permissionService;

    @Autowired
    private IUserService userService;

    // ==================== CURRENT USER PERMISSIONS ====================

    /**
     * GET /api/users/me/permissions?module=LEADS
     * Obtiene los permisos del usuario autenticado para un módulo específico.
     * Retorna permisos de acción y visibilidad de campañas.
     */
    @GetMapping("/users/me/permissions")
    public ResponseEntity<?> getCurrentUserPermissions(@RequestParam String module) {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String email = authentication.getName();

            UserEntity user = userService.findByemail(email);
            if (user == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("error", "USER_NOT_FOUND");
                response.put("message", "Usuario no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }

            UserPermissionsDto permissions = permissionService.getUserPermissions(user.getId(), module);
            return new ResponseEntity<>(permissions, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ==================== ROLE ACTION PERMISSIONS (ADMIN) ====================

    /**
     * GET /api/roles/{roleId}/permissions?module=LEADS
     * Obtiene los permisos de acción de un rol para un módulo específico.
     * Requiere ROLE_ADMIN.
     */
    @Secured("ROLE_ADMIN")
    @GetMapping("/roles/{roleId}/permissions")
    public ResponseEntity<?> getRolePermissions(@PathVariable Long roleId,
                                                @RequestParam String module) {
        try {
            List<ActionPermissionDto> permissions = permissionService.getActionPermissions(roleId, module);
            return new ResponseEntity<>(permissions, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * PUT /api/roles/{roleId}/permissions
     * Actualiza un permiso de acción individual para un rol.
     * Requiere ROLE_ADMIN.
     */
    @Secured("ROLE_ADMIN")
    @PutMapping("/roles/{roleId}/permissions")
    public ResponseEntity<?> updateRolePermission(@PathVariable Long roleId,
                                                  @Valid @RequestBody UpdateActionPermissionRequest request,
                                                  BindingResult result) {
        if (result.hasErrors()) {
            Map<String, Object> response = new HashMap<>();
            List<String> errors = result.getFieldErrors().stream()
                    .map(err -> err.getDefaultMessage())
                    .collect(Collectors.toList());
            response.put("error", "VALIDATION_ERROR");
            response.put("message", errors.get(0));
            response.put("errors", errors);
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        try {
            permissionService.updateActionPermission(roleId, request.getModuleCode(),
                    request.getActionCode(), request.getEnabled());

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Permiso actualizado exitosamente");
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (RuntimeException e) {
            Map<String, Object> response = new HashMap<>();
            if ("INVALID_MODULE_CODE".equals(e.getMessage())) {
                response.put("error", "INVALID_MODULE_CODE");
                response.put("message", "Código de módulo inválido");
                return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
            } else if ("PERMISSION_NOT_FOUND".equals(e.getMessage())) {
                response.put("error", "INVALID_ACTION_CODE");
                response.put("message", "Código de acción inválido");
                return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
            } else if ("ROLE_NOT_FOUND".equals(e.getMessage())) {
                response.put("error", "ROLE_NOT_FOUND");
                response.put("message", "Rol no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ==================== CAMPAIGN VISIBILITY (ADMIN) ====================

    /**
     * GET /api/roles/{roleId}/campaign-visibility
     * Obtiene la configuración de visibilidad de campañas para un rol.
     * Requiere ROLE_ADMIN.
     */
    @Secured("ROLE_ADMIN")
    @GetMapping("/roles/{roleId}/campaign-visibility")
    public ResponseEntity<?> getRoleCampaignVisibility(@PathVariable Long roleId) {
        try {
            List<Long> campaignIds = permissionService.getVisibleCampaignIds(roleId);

            Map<String, Object> response = new HashMap<>();
            response.put("roleId", roleId);
            response.put("campaignIds", campaignIds);
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * PUT /api/roles/{roleId}/campaign-visibility
     * Actualiza la configuración de visibilidad de campañas para un rol.
     * Requiere ROLE_ADMIN.
     */
    @Secured("ROLE_ADMIN")
    @PutMapping("/roles/{roleId}/campaign-visibility")
    public ResponseEntity<?> updateRoleCampaignVisibility(@PathVariable Long roleId,
                                                          @Valid @RequestBody UpdateCampaignVisibilityRequest request,
                                                          BindingResult result) {
        if (result.hasErrors()) {
            Map<String, Object> response = new HashMap<>();
            List<String> errors = result.getFieldErrors().stream()
                    .map(err -> err.getDefaultMessage())
                    .collect(Collectors.toList());
            response.put("error", "VALIDATION_ERROR");
            response.put("message", errors.get(0));
            response.put("errors", errors);
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        try {
            permissionService.updateCampaignVisibility(roleId, request.getCampaignIds());

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Visibilidad de campañas actualizada exitosamente");
            response.put("campaignIds", request.getCampaignIds());
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (RuntimeException e) {
            Map<String, Object> response = new HashMap<>();
            if ("ROLE_NOT_FOUND".equals(e.getMessage())) {
                response.put("error", "ROLE_NOT_FOUND");
                response.put("message", "Rol no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            } else if ("CAMPAIGN_NOT_FOUND".equals(e.getMessage())) {
                response.put("error", "CAMPAIGN_NOT_FOUND");
                response.put("message", "Campaña no encontrada");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
