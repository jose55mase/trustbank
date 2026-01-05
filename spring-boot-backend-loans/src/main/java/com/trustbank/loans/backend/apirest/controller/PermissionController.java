package com.trustbank.loans.backend.apirest.controller;

import com.trustbank.loans.backend.apirest.entity.Permission;
import com.trustbank.loans.backend.apirest.entity.UserPermission;
import com.trustbank.loans.backend.apirest.entity.AuthUser;
import com.trustbank.loans.backend.apirest.repository.PermissionRepository;
import com.trustbank.loans.backend.apirest.repository.UserPermissionRepository;
import com.trustbank.loans.backend.apirest.repository.AuthUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/permissions")
@CrossOrigin(origins = "*")
public class PermissionController {
    
    @Autowired
    private PermissionRepository permissionRepository;
    
    @Autowired
    private UserPermissionRepository userPermissionRepository;
    
    @Autowired
    private AuthUserRepository authUserRepository;
    
    @GetMapping
    public List<Permission> getAllPermissions() {
        return permissionRepository.findAll();
    }
    
    @GetMapping("/user/{userId}")
    public List<UserPermission> getUserPermissions(@PathVariable Long userId) {
        AuthUser user = authUserRepository.findById(userId).orElse(null);
        if (user != null) {
            return userPermissionRepository.findByAuthUser(user);
        }
        return List.of();
    }
    
    @PostMapping("/user/{userId}")
    @Transactional
    public ResponseEntity<Map<String, Object>> updateUserPermissions(
            @PathVariable Long userId, 
            @RequestBody List<Map<String, Object>> permissions) {
        
        AuthUser user = authUserRepository.findById(userId).orElse(null);
        if (user == null) {
            return ResponseEntity.notFound().build();
        }
        
        try {
            // Eliminar permisos existentes
            userPermissionRepository.deleteByAuthUser(user);
            
            // Forzar flush para asegurar que se eliminen antes de insertar
            userPermissionRepository.flush();
            
            // Agregar nuevos permisos
            for (Map<String, Object> permData : permissions) {
                Long permissionId = Long.valueOf(permData.get("permissionId").toString());
                Boolean granted = (Boolean) permData.get("granted");
                
                Permission permission = permissionRepository.findById(permissionId).orElse(null);
                if (permission != null && granted) {
                    // Solo crear si granted es true
                    UserPermission userPermission = new UserPermission(user, permission, granted);
                    userPermissionRepository.save(userPermission);
                }
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Permisos actualizados correctamente");
            response.put("userId", userId);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Error al actualizar permisos: " + e.getMessage());
            return ResponseEntity.status(500).body(errorResponse);
        }
    }
    
    @PostMapping("/init")
    public ResponseEntity<Map<String, Object>> initializePermissions() {
        // Crear permisos por defecto
        String[][] defaultPermissions = {
            {"users", "Gestión de Usuarios", "Crear, editar y eliminar usuarios"},
            {"loans", "Gestión de Préstamos", "Crear, editar y eliminar préstamos"},
            {"transactions", "Transacciones", "Ver y gestionar transacciones"},
            {"expenses", "Gastos Diarios", "Gestionar gastos y categorías"},
            {"reports", "Reportes", "Generar y exportar reportes"},
            {"settings", "Configuración", "Acceso a configuración del sistema"}
        };
        
        int created = 0;
        for (String[] perm : defaultPermissions) {
            try {
                if (!permissionRepository.findByModuleKey(perm[0]).isPresent()) {
                    Permission permission = new Permission(perm[1], perm[2], perm[0]);
                    permissionRepository.save(permission);
                    created++;
                }
            } catch (Exception e) {
                // Ignorar errores de duplicados
            }
        }
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Permisos inicializados");
        response.put("created", created);
        response.put("total", permissionRepository.count());
        
        return ResponseEntity.ok(response);
    }
}