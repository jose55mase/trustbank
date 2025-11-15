# Guía del Sistema de Roles y Permisos

## 🔐 Roles Disponibles

### 1. Usuario (USER)
- **Permisos básicos**: Ver saldo, enviar dinero, recibir pagos
- **Acceso**: Solo funciones básicas de la app

### 2. Moderador (MODERATOR)
- **Permisos**: Todo lo de Usuario + Ver panel admin y reportes
- **Acceso**: Panel administrativo solo lectura

### 3. Administrador (ADMIN)
- **Permisos**: Todo lo de Moderador + Gestionar usuarios y aprobar transacciones
- **Acceso**: Panel administrativo completo

### 4. Super Administrador (SUPER_ADMIN)
- **Permisos**: Acceso completo al sistema
- **Acceso**: Gestión de roles, configuración del sistema, logs de auditoría

## 🛠️ Implementación

### Proteger Widgets con RoleGuard
```dart
RoleGuard(
  requiredPermission: Permission.viewAdminPanel,
  child: AdminButton(),
  fallback: Text('Sin permisos'),
)
```

### Verificar Permisos en Código
```dart
final hasPermission = await AuthService.hasPermission(Permission.manageUsers);
if (hasPermission) {
  // Mostrar funcionalidad
}
```

### Menú Dinámico según Rol
```dart
Future<List<PopupMenuEntry<String>>> _buildMenuItems() async {
  final hasAdminAccess = await AuthService.hasPermission(Permission.viewAdminPanel);
  // Construir menú según permisos
}
```

## 📊 Tabla de Permisos por Rol

| Permiso | Usuario | Moderador | Admin | Super Admin |
|---------|---------|-----------|-------|-------------|
| Ver saldo | ✅ | ✅ | ✅ | ✅ |
| Enviar dinero | ✅ | ✅ | ✅ | ✅ |
| Panel admin | ❌ | ✅ | ✅ | ✅ |
| Gestionar usuarios | ❌ | ❌ | ✅ | ✅ |
| Aprobar transacciones | ❌ | ❌ | ✅ | ✅ |
| Gestionar roles | ❌ | ❌ | ❌ | ✅ |
| Configuración sistema | ❌ | ❌ | ❌ | ✅ |

## 🔧 Configuración Backend

### Endpoint para actualizar rol
```
PUT /api/user/updateRole/{userId}
Body: { "role": "ADMIN" }
```

### Estructura de usuario con rol
```json
{
  "id": 1,
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "role": "ADMIN",
  "accountStatus": "ACTIVE"
}
```

## 🎯 Ejemplos de Uso

### Login con diferentes roles
- `admin@test.com` → Rol ADMIN
- `superadmin@test.com` → Rol SUPER_ADMIN  
- `moderator@test.com` → Rol MODERATOR
- `user@test.com` → Rol USER

### Pantallas protegidas
- **Panel Admin**: Requiere `Permission.viewAdminPanel`
- **Gestión de Roles**: Requiere `Permission.manageRoles`
- **Gestión de Usuarios**: Requiere `Permission.manageUsers`

## 🚀 Próximos Pasos

1. Implementar en backend la tabla de roles
2. Agregar middleware de autorización
3. Crear logs de auditoría para cambios de roles
4. Implementar notificaciones de cambios de permisos