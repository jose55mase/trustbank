# Backend de Préstamos - Configuración Completa

## ✅ **Base de Datos H2 en Memoria**
- **URL**: `jdbc:h2:mem:loansdb`
- **Usuario**: `sa`
- **Contraseña**: (vacía)
- **Consola H2**: `http://localhost:8082/h2-console`

## ✅ **Datos de Prueba Incluidos**
### Usuarios:
- Juan Pérez (+1234567890)
- María García (+1234567891) 
- Carlos Rodríguez (+1234567892)

### Préstamos:
- Juan: $5,000,000 (15% - 12 cuotas - 5 pagadas)
- María: $10,000,000 (12% - 24 cuotas - 10 pagadas)
- Juan: $7,500,000 (14% - 18 cuotas - 8 pagadas)

### Transacciones:
- 3 pagos de ejemplo con interés y capital calculados

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

## 🔧 **Para Ejecutar**
1. Instalar Maven o usar IDE
2. Ejecutar `LoansBackendApplication.java`
3. Acceder a `http://localhost:8082`
4. Probar endpoints con Postman o desde Flutter

## 📱 **Integración con Flutter**
- CORS habilitado para `*`
- Puerto: `8082`
- Base URL: `http://localhost:8082/api`