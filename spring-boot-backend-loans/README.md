# Backend de Préstamos - Configuración Completa

## ✅ **Base de Datos H2 en Memoria**
- **URL**: `jdbc:h2:mem:loansdb`
- **Usuario**: `sa`
- **Contraseña**: (vacía)
- **Consola H2**: `http://localhost:8082/h2-console`

## 🔐 **Sistema de Autenticación y Roles**

### Crear Usuarios del Sistema:

**Usuario Administrador (acceso completo):**
```bash
curl -X POST http://localhost:8082/api/auth/register \
-H "Content-Type: application/json" \
-d '{"username":"admin2","password":"password123","email":"admin@inversiones.com","role":"ADMIN"}'
```

**Usuario Visualizador (solo lectura):**
```bash
curl -X POST http://localhost:8082/api/auth/register \
-H "Content-Type: application/json" \
-d '{"username":"viewer","password":"password123","email":"viewer@inversiones.com","role":"VIEWER"}'
```

### Credenciales de Login:
- **Admin**: `admin` / `password123` (acceso completo)
- **Viewer**: `viewer` / `password123` (solo lectura)

### Permisos por Rol:
- **ADMIN**: Acceso completo a todos los módulos
- **VIEWER**: Solo puede ver préstamos, usuarios y gastos diarios (sin crear/editar)

## ✅ **Datos de Prueba** (Crear manualmente después del primer inicio)
### Usuarios:
- Juan Pérez (+1234567890)
- María García (+1234567891) 
- Carlos Rodríguez (+1234567892)

### Préstamos:
- Juan: $5,000,000 (15% - 12 cuotas - 5 pagadas)
- María: $10,000,000 (12% - 24 cuotas - 10 pagadas)
- Juan: $7,500,000 (14% - 18 cuotas - 8 pagadas)

## 🚀 **API Endpoints**

### Usuarios (`/api/users`)
- `GET /api/users` - Listar todos
- `GET /api/users/{id}` - Por ID
- `POST /api/users` - Crear
- `PUT /api/users/{id}` - Actualizar
- `DELETE /api/users/{id}` - Eliminar

### Préstamos (`/api/loans`)
- `GET /api/loans` - Listar todos
- `GET /api/loans/{id}` - Por ID
- `GET /api/loans/user/{userId}` - Por usuario
- `GET /api/loans/total-active` - Total activos
- `POST /api/loans` - Crear
- `PUT /api/loans/{id}` - Actualizar
- `DELETE /api/loans/{id}` - Eliminar

### Transacciones (`/api/transactions`)
- `GET /api/transactions` - Listar todas
- `GET /api/transactions/{id}` - Por ID
- `GET /api/transactions/loan/{loanId}` - Por préstamo
- `GET /api/transactions/total-payments` - Total pagos
- `POST /api/transactions` - Crear
- `PUT /api/transactions/{id}` - Actualizar
- `DELETE /api/transactions/{id}` - Eliminar

### Gastos (`/api/expenses`)
- `GET /api/expenses` - Listar todos
- `GET /api/expenses/{id}` - Por ID
- `GET /api/expenses/by-date-range` - Por rango de fechas
- `GET /api/expenses/category/{categoryId}` - Por categoría
- `POST /api/expenses` - Crear (solo ADMIN)
- `PUT /api/expenses/{id}` - Actualizar (solo ADMIN)
- `DELETE /api/expenses/{id}` - Eliminar (solo ADMIN)

### Categorías de Gastos (`/api/expense-categories`)
- `GET /api/expense-categories` - Listar todas
- `GET /api/expense-categories/{id}` - Por ID
- `POST /api/expense-categories` - Crear (solo ADMIN)
- `PUT /api/expense-categories/{id}` - Actualizar (solo ADMIN)
- `DELETE /api/expense-categories/{id}` - Eliminar (solo ADMIN)

## 🔧 **Para Ejecutar**
1. Instalar Maven o usar IDE
2. Ejecutar `LoansBackendApplication.java`
3. Acceder a `http://localhost:8082`
4. **IMPORTANTE**: Crear usuarios del sistema usando los comandos curl mostrados arriba
5. Probar endpoints con Postman o desde Flutter

## 📱 **Integración con Flutter**
- CORS habilitado para `*`
- Puerto: `8082`
- Base URL: `http://localhost:8082/api`
- **Login**: Usar credenciales `admin`/`password123` o `viewer`/`password123`