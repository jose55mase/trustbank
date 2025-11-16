# Sincronización Backend - Sistema de Notificaciones con Datos de Usuario

## 📋 Especificaciones para Spring Boot Backend

### 🗄️ Estructura de Base de Datos

#### Tabla: `notifications`
```sql
CREATE TABLE notifications (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    user_name VARCHAR(255),
    user_email VARCHAR(255),
    user_phone VARCHAR(50),
    additional_info TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 🏗️ Entidad JPA

```java
@Entity
@Table(name = "notifications")
public class Notification {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "user_id", nullable = false)
    private Long userId;
    
    @Column(nullable = false)
    private String title;
    
    @Column(columnDefinition = "TEXT", nullable = false)
    private String message;
    
    @Column(nullable = false)
    private String type;
    
    @Column(name = "is_read")
    private Boolean isRead = false;
    
    @Column(name = "user_name")
    private String userName;
    
    @Column(name = "user_email")
    private String userEmail;
    
    @Column(name = "user_phone")
    private String userPhone;
    
    @Column(name = "additional_info", columnDefinition = "TEXT")
    private String additionalInfo;
    
    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    // Constructors, getters, setters...
}
```

### 🎯 Endpoints Requeridos

#### 1. Crear Notificación
```
POST /api/notifications/create
Content-Type: application/json

{
    "userId": 1,
    "title": "Recarga Exitosa 💳",
    "message": "Hola Juan Pérez, has recargado $500.00 usando Tarjeta de crédito.",
    "type": "recharge",
    "userName": "Juan Pérez",
    "userEmail": "juan.perez@email.com",
    "userPhone": "+1 234 567 8900",
    "additionalInfo": "Método de pago: Tarjeta de crédito - Monto: $500.00"
}
```

#### 2. Obtener Notificaciones de Usuario
```
GET /api/notifications/user/{userId}?sort=createdAt,desc

Response:
{
    "data": [
        {
            "id": 1,
            "title": "Recarga Exitosa 💳",
            "message": "Hola Juan Pérez, has recargado $500.00...",
            "type": "recharge",
            "isRead": false,
            "userName": "Juan Pérez",
            "userEmail": "juan.perez@email.com",
            "userPhone": "+1 234 567 8900",
            "additionalInfo": "Método de pago: Tarjeta de crédito",
            "createdAt": "2024-01-15T10:30:00"
        }
    ]
}
```

#### 3. Marcar como Leída
```
PUT /api/notifications/mark-read/{notificationId}

Response:
{
    "success": true,
    "message": "Notificación marcada como leída"
}
```

#### 4. Obtener No Leídas
```
GET /api/notifications/user/{userId}/unread

Response:
{
    "data": [...],
    "count": 3
}
```

### 🔧 Controller Ejemplo

```java
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {
    
    @Autowired
    private NotificationService notificationService;
    
    @PostMapping("/create")
    public ResponseEntity<?> createNotification(@RequestBody NotificationRequest request) {
        try {
            Notification notification = notificationService.createNotification(request);
            return ResponseEntity.status(201).body(Map.of(
                "status", 201,
                "message", "Notificación creada exitosamente",
                "id", notification.getId()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Error al crear notificación",
                "message", e.getMessage()
            ));
        }
    }
    
    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getUserNotifications(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "createdAt,desc") String sort) {
        try {
            List<Notification> notifications = notificationService.getUserNotifications(userId, sort);
            return ResponseEntity.ok(Map.of("data", notifications));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Error al obtener notificaciones"
            ));
        }
    }
    
    @PutMapping("/mark-read/{notificationId}")
    public ResponseEntity<?> markAsRead(@PathVariable Long notificationId) {
        try {
            notificationService.markAsRead(notificationId);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Notificación marcada como leída"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Error al marcar notificación"
            ));
        }
    }
}
```

### 📱 Tipos de Notificación Soportados

- `general`: Notificaciones generales del sistema
- `recharge`: Notificaciones de recarga de saldo
- `sendMoney`: Notificaciones de envío de dinero
- `creditPending`: Solicitudes de crédito pendientes
- `creditApproved`: Créditos aprobados
- `creditRejected`: Créditos rechazados

### 🔄 Flujo de Sincronización

1. **Flutter App** → Crea notificación con datos completos del usuario
2. **Backend** → Persiste en base de datos con toda la información
3. **Flutter App** → Recarga notificaciones desde backend
4. **Backend** → Retorna notificaciones con datos de usuario incluidos

### ✅ Beneficios de la Sincronización

- **Persistencia**: Las notificaciones se mantienen entre sesiones
- **Datos Completos**: Información de usuario siempre disponible
- **Sincronización**: Notificaciones consistentes en múltiples dispositivos
- **Auditoría**: Registro completo de todas las notificaciones enviadas
- **Escalabilidad**: Sistema preparado para múltiples usuarios

### 🚀 Implementación Recomendada

1. Crear la tabla `notifications` en la base de datos
2. Implementar la entidad JPA `Notification`
3. Crear el servicio `NotificationService`
4. Implementar el controlador `NotificationController`
5. Probar endpoints con los datos de ejemplo
6. Verificar sincronización con la app Flutter

El sistema Flutter ya está preparado para trabajar con este backend y tiene fallbacks locales en caso de que el backend no esté disponible.