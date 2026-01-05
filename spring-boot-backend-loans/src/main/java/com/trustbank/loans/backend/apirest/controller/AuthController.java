package com.trustbank.loans.backend.apirest.controller;

import com.trustbank.loans.backend.apirest.entity.AuthUser;
import com.trustbank.loans.backend.apirest.entity.UserPermission;
import com.trustbank.loans.backend.apirest.repository.AuthUserRepository;
import com.trustbank.loans.backend.apirest.repository.UserPermissionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {
    
    @Autowired
    private AuthUserRepository authUserRepository;
    
    @Autowired
    private UserPermissionRepository userPermissionRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String username = credentials.get("username");
        String password = credentials.get("password");
        
        AuthUser user = authUserRepository.findByUsername(username).orElse(null);
        
        if (user != null && passwordEncoder.matches(password, user.getPassword())) {
            // Obtener permisos del usuario
            List<UserPermission> userPermissions = userPermissionRepository.findByAuthUserAndGranted(user, true);
            List<String> permissions = userPermissions.stream()
                .map(up -> up.getPermission().getModuleKey())
                .collect(Collectors.toList());
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Login exitoso");
            response.put("user", Map.of(
                "id", user.getId(),
                "username", user.getUsername(),
                "email", user.getEmail(),
                "role", user.getRole(),
                "permissions", permissions
            ));
            return ResponseEntity.ok(response);
        }
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", "Credenciales inválidas");
        return ResponseEntity.badRequest().body(response);
    }
    
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody Map<String, String> userData) {
        String username = userData.get("username");
        String password = userData.get("password");
        String email = userData.get("email");
        String role = userData.getOrDefault("role", "USER");
        
        if (authUserRepository.existsByUsername(username)) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "El usuario ya existe");
            return ResponseEntity.badRequest().body(response);
        }
        
        AuthUser newUser = new AuthUser();
        newUser.setUsername(username);
        newUser.setPassword(passwordEncoder.encode(password));
        newUser.setEmail(email);
        newUser.setRole(role);
        
        authUserRepository.save(newUser);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Usuario registrado exitosamente");
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/users")
    public List<AuthUser> getAllAuthUsers() {
        return authUserRepository.findAll();
    }
    
    @DeleteMapping("/users/{userId}")
    @Transactional
    public ResponseEntity<Map<String, Object>> deleteAuthUser(@PathVariable Long userId) {
        AuthUser user = authUserRepository.findById(userId).orElse(null);
        if (user == null) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Usuario no encontrado");
            return ResponseEntity.status(404).body(response);
        }
        
        try {
            // Los permisos se eliminan automáticamente por CASCADE
            authUserRepository.delete(user);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Usuario eliminado exitosamente");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Error al eliminar usuario: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }
}