# Fix: Backend - Saldo de Créditos no se Suma

## 🔍 Problema Identificado

En el backend, el método `updateUserBalance` en `AdminRequestController.java` no tenía el caso para manejar solicitudes de tipo `CREDIT`, por lo que cuando se aprobaba un crédito, el saldo del usuario no se actualizaba.

## ✅ Cambios Realizados

### Archivo: `AdminRequestController.java`

#### 1. **Agregado caso CREDIT**
```java
case "CREDIT":
    // Agregar dinero del crédito al saldo
    user.setMoneyclean(currentBalance + request.getAmount().intValue());
    System.out.println("Crédito aprobado: Usuario " + user.getId() + 
                      " - Saldo anterior: " + currentBalance + 
                      " - Monto crédito: " + request.getAmount() + 
                      " - Nuevo saldo: " + (currentBalance + request.getAmount().intValue()));
    break;
```

#### 2. **Mejorado logging para debug**
```java
// Al inicio del método
System.out.println("Iniciando actualización de saldo para usuario: " + request.getUserId() + 
                  ", tipo: " + request.getRequestType() + ", monto: " + request.getAmount());

// Después de encontrar usuario
System.out.println("Usuario encontrado - ID: " + user.getId() + ", Saldo actual: " + currentBalance);

// Después de guardar
System.out.println("Saldo actualizado exitosamente para usuario " + user.getId() + ": " + user.getMoneyclean());
```

#### 3. **Mejorado manejo de errores**
```java
} else {
    System.err.println("Usuario no encontrado con ID: " + request.getUserId());
}
} catch (Exception e) {
    System.err.println("Error actualizando saldo del usuario: " + e.getMessage());
    e.printStackTrace(); // Stack trace completo para debug
}
```

## 🔄 Flujo Corregido

### Cuando Admin Aprueba Crédito:

1. **Solicitud llega al endpoint** `/api/admin-requests/process/{id}`
2. **Se actualiza estado** a "APPROVED"
3. **Se llama `updateUserBalance()`** con la solicitud
4. **Se identifica tipo "CREDIT"** en el switch
5. **Se suma monto al saldo** del usuario
6. **Se guarda usuario** con nuevo saldo
7. **Logs confirman** la operación

## 🧪 Logs Esperados

Cuando se apruebe un crédito, deberías ver en la consola del backend:

```
Iniciando actualización de saldo para usuario: 2, tipo: CREDIT, monto: 1000.0
Usuario encontrado - ID: 2, Saldo actual: 500
Crédito aprobado: Usuario 2 - Saldo anterior: 500 - Monto crédito: 1000.0 - Nuevo saldo: 1500
Saldo actualizado exitosamente para usuario 2: 1500
```

## 🎯 Casos Manejados

El switch ahora maneja todos los tipos de solicitud:

- **RECHARGE / BALANCE_RECHARGE**: ➕ Suma al saldo
- **CREDIT**: ➕ Suma al saldo (NUEVO)
- **SEND_MONEY**: ➖ Resta del saldo
- **Otros tipos**: No modifica saldo

## 🚨 Importante

- El cambio es **retrocompatible** - no afecta funcionalidad existente
- Los **logs detallados** permiten debuggear cualquier problema
- El **manejo de errores** evita que falle toda la transacción
- La **lógica es consistente** con otros tipos de solicitud

## 🔧 Para Probar

1. **Reiniciar el backend** para aplicar cambios
2. **Crear solicitud de crédito** desde la app
3. **Aprobar desde panel admin**
4. **Verificar logs** en consola del backend
5. **Confirmar saldo actualizado** en la app

El problema estaba en que el backend no reconocía las solicitudes de tipo "CREDIT" para actualizar el saldo. Ahora debería funcionar correctamente.