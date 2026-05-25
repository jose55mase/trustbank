package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.exceptions.DuplicateRoleNameException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.RoleHasUsersException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.RoleNotFoundException;
import com.bolsadeideas.springboot.backend.apirest.models.dto.ModuleResponse;
import com.bolsadeideas.springboot.backend.apirest.models.dto.RolRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.RolResponse;
import com.bolsadeideas.springboot.backend.apirest.models.dto.RoleModulesRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.UserRoleRequest;
import com.bolsadeideas.springboot.backend.apirest.models.entity.ModuleEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IModuleService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IRolService;
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
 * Controlador REST para la gestión de Roles y Módulos.
 * Provee endpoints CRUD para roles, asignación de módulos a roles,
 * catálogo de módulos y consulta de módulos del usuario autenticado.
 */
@RestController
@RequestMapping("/api")
public class RolController {

    @Autowired
    private IRolService rolService;

    @Autowired
    private IModuleService moduleService;

    @Autowired
    private IUserService userService;

    // ==================== ROLES CRUD ====================

    /**
     * GET /api/roles
     * Lista todos los roles con conteo de usuarios.
     */
    @Secured("ROLE_ADMIN")
    @GetMapping("/roles")
    public ResponseEntity<?> getAllRoles() {
        try {
            List<RolResponse> roles = rolService.findAll();
            return new ResponseEntity<>(roles, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/roles/{id}
     * Obtiene un rol con sus módulos asignados.
     */
    @Secured("ROLE_ADMIN")
    @GetMapping("/roles/{id}")
    public ResponseEntity<?> getRoleById(@PathVariable Long id) {
        try {
            RolResponse role = rolService.findById(id);
            return new ResponseEntity<>(role, HttpStatus.OK);
        } catch (RoleNotFoundException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "ROLE_NOT_FOUND");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * POST /api/roles
     * Crea un nuevo rol con validación de nombre.
     */
    @Secured("ROLE_ADMIN")
    @PostMapping("/roles")
    public ResponseEntity<?> createRole(@Valid @RequestBody RolRequest request, BindingResult result) {
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
            RolResponse role = rolService.create(request);
            return new ResponseEntity<>(role, HttpStatus.CREATED);
        } catch (DuplicateRoleNameException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "DUPLICATE_ROLE_NAME");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * PUT /api/roles/{id}
     * Actualiza el nombre de un rol existente.
     */
    @Secured("ROLE_ADMIN")
    @PutMapping("/roles/{id}")
    public ResponseEntity<?> updateRole(@PathVariable Long id, @Valid @RequestBody RolRequest request, BindingResult result) {
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
            RolResponse role = rolService.update(id, request);
            return new ResponseEntity<>(role, HttpStatus.OK);
        } catch (RoleNotFoundException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "ROLE_NOT_FOUND");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (DuplicateRoleNameException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "DUPLICATE_ROLE_NAME");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * DELETE /api/roles/{id}
     * Elimina un rol. Rechaza si tiene usuarios asignados.
     */
    @Secured("ROLE_ADMIN")
    @DeleteMapping("/roles/{id}")
    public ResponseEntity<?> deleteRole(@PathVariable Long id) {
        try {
            rolService.delete(id);
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Rol eliminado exitosamente");
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (RoleNotFoundException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "ROLE_NOT_FOUND");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (RoleHasUsersException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "ROLE_HAS_USERS");
            response.put("message", e.getMessage());
            response.put("userCount", e.getUserCount());
            return new ResponseEntity<>(response, HttpStatus.CONFLICT);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ==================== MODULE ASSIGNMENT ====================

    /**
     * PUT /api/roles/{id}/modules
     * Asigna módulos a un rol (batch). Reemplaza la asignación actual.
     */
    @Secured("ROLE_ADMIN")
    @PutMapping("/roles/{id}/modules")
    public ResponseEntity<?> updateRoleModules(@PathVariable Long id,
                                               @Valid @RequestBody RoleModulesRequest request,
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
            RolResponse role = rolService.updateRoleModules(id, request.getModuleIds());
            return new ResponseEntity<>(role, HttpStatus.OK);
        } catch (RoleNotFoundException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "ROLE_NOT_FOUND");
            response.put("message", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ==================== MODULE CATALOG ====================

    /**
     * GET /api/modules
     * Lista el catálogo completo de módulos disponibles.
     */
    @Secured("ROLE_ADMIN")
    @GetMapping("/modules")
    public ResponseEntity<?> getAllModules() {
        try {
            List<ModuleEntity> modules = moduleService.findAll();
            List<ModuleResponse> response = modules.stream()
                    .map(m -> new ModuleResponse(
                            m.getId(),
                            m.getCode(),
                            m.getName(),
                            m.getDescription(),
                            m.getIcon(),
                            m.getDisplayOrder()
                    ))
                    .collect(Collectors.toList());
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ==================== USER ROLE ASSIGNMENT ====================

    /**
     * PUT /api/users/{userId}/role
     * Cambia el rol de un usuario existente.
     * Valida que el rol exista antes de asignarlo.
     * Requiere ROLE_ADMIN.
     */
    @Secured("ROLE_ADMIN")
    @PutMapping("/users/{userId}/role")
    public ResponseEntity<?> updateUserRole(@PathVariable Long userId,
                                            @Valid @RequestBody UserRoleRequest request,
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
            Map<String, Object> responseData = rolService.assignRoleToUser(userId, request.getRoleId());
            return new ResponseEntity<>(responseData, HttpStatus.OK);
        } catch (RoleNotFoundException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "ROLE_NOT_FOUND");
            response.put("message", "El rol no existe");
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (RuntimeException e) {
            if ("USER_NOT_FOUND".equals(e.getMessage())) {
                Map<String, Object> response = new HashMap<>();
                response.put("error", "USER_NOT_FOUND");
                response.put("message", "El usuario no existe");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ==================== USER MODULES ====================

    /**
     * GET /api/users/me/modules
     * Obtiene los módulos permitidos para el usuario autenticado actual.
     * No requiere ROLE_ADMIN, solo autenticación.
     */
    @GetMapping("/users/me/modules")
    public ResponseEntity<?> getCurrentUserModules() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String email = authentication.getName();

            UserEntity user = userService.findByemail(email);
            if (user == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("error", "Usuario no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }

            List<ModuleResponse> modules = rolService.getUserModules(user.getId());
            return new ResponseEntity<>(modules, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
