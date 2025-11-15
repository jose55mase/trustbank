# Integración con Backend Spring Boot

## 📊 Cambios en Base de Datos

### 1. Ejecutar Migración SQL
```sql
-- En tu base de datos MySQL del backend spring-boot-backend-apirest
ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'USER';
CREATE INDEX idx_users_role ON users(role);
```

### 2. Usuario Administrador por Defecto
```sql
INSERT INTO users (name, email, password, role, moneyclean, balance, phone, address, documentType, documentNumber, accountStatus, createdAt, updatedAt) 
VALUES ('Administrador TrustBank', 'admin@trustbank.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'SUPER_ADMIN', 1000000.00, 1000000.00, '+1234567890', 'Oficina Central', 'CC', '12345678', 'ACTIVE', NOW(), NOW());
```

## 🔧 Cambios en Backend Spring Boot

### 1. Actualizar Entity User.java
```java
@Entity
@Table(name = "users")
public class User {
    // ... otros campos existentes
    
    @Column(name = "role", nullable = false, length = 20)
    private String role = "USER";
    
    // Getter y Setter
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
}
```

### 2. Agregar Endpoint para Gestión de Roles
```java
@RestController
@RequestMapping("/api/user")
public class UserController {
    
    @PutMapping("/updateRole/{userId}")
    public ResponseEntity<?> updateUserRole(@PathVariable Long userId, @RequestBody Map<String, String> request) {
        try {
            User user = userService.findById(userId);
            user.setRole(request.get("role"));
            userService.save(user);
            return ResponseEntity.ok(new RestResponse(200, "Rol actualizado", user));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new RestResponse(400, e.getMessage(), null));
        }
    }
    
    @GetMapping("/byRole/{role}")
    public ResponseEntity<?> getUsersByRole(@PathVariable String role) {
        try {
            List<User> users = userService.findByRole(role);
            return ResponseEntity.ok(new RestResponse(200, "Usuarios encontrados", users));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new RestResponse(400, e.getMessage(), null));
        }
    }
}
```

### 3. Actualizar UserService.java
```java
@Service
public class UserService {
    
    public List<User> findByRole(String role) {
        return userRepository.findByRole(role);
    }
    
    public User updateRole(Long userId, String role) {
        User user = findById(userId);
        user.setRole(role);
        return userRepository.save(user);
    }
}
```

### 4. Actualizar UserRepository.java
```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // ... métodos existentes
    
    List<User> findByRole(String role);
    
    @Query("SELECT u FROM User u WHERE u.role IN :roles")
    List<User> findByRoleIn(@Param("roles") List<String> roles);
}
```

## 🎯 Credenciales de Administrador

```
Email: admin@trustbank.com
Contraseña: admin123
Rol: SUPER_ADMIN
```

## 🔐 Roles Disponibles

- `USER` - Usuario básico
- `MODERATOR` - Moderador con acceso limitado
- `ADMIN` - Administrador con gestión completa
- `SUPER_ADMIN` - Super administrador con todos los permisos

## 📱 Uso en Flutter

El sistema Flutter ya está configurado para usar estos roles. Solo necesitas:

1. Ejecutar la migración SQL
2. Actualizar el backend Spring Boot
3. Usar las credenciales de admin para acceder

Los endpoints ya están configurados en `ApiService.dart` para funcionar con tu backend.