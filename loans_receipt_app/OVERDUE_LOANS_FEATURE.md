# Feature: Campaña de Préstamos Vencidos en Home

## 📋 Resumen
Se ha implementado una campaña visual en el home para alertar sobre préstamos vencidos, con navegación a una pantalla detallada.

## ✨ Cambios Realizados

### 1. **Backend - Nuevos Endpoints**
- `GET /api/loans/overdue` - Obtiene lista de préstamos vencidos
- `GET /api/loans/overdue/count` - Cuenta préstamos vencidos

### 2. **Flutter - Nuevos Archivos**

#### `overdue_loans_banner.dart`
Widget de campaña que se muestra en el home:
- Diseño con gradiente rojo
- Icono de advertencia
- Contador de préstamos vencidos
- Navegación al hacer tap

#### `overdue_loans_screen.dart`
Pantalla completa con lista de préstamos vencidos:
- Lista de préstamos con estado OVERDUE
- Información detallada de cada préstamo
- Navegación a detalles del préstamo
- Diseño con tema rojo para urgencia

### 3. **Servicios Actualizados**

#### `api_service.dart`
Nuevos métodos agregados:
```dart
static Future<List<Loan>> getOverdueLoans()
static Future<int> getOverdueLoansCount()
```

### 4. **Home Screen Actualizado**

#### `home_screen.dart`
- Importa `OverdueLoansBanner` y `OverdueLoansScreen`
- Banner se muestra después de `StatsOverview`
- Solo aparece si hay préstamos vencidos
- Navegación automática a pantalla de detalles

## 🎨 Diseño Visual

### Banner en Home:
```
┌─────────────────────────────────────────┐
│ ⚠️  Préstamos Vencidos           [6] → │
│     6 préstamos requieren atención      │
└─────────────────────────────────────────┘
```

### Características del Banner:
- Gradiente rojo suave
- Borde rojo
- Icono de advertencia en círculo rojo
- Badge con número de préstamos
- Flecha indicando navegación
- Solo visible si hay préstamos vencidos

### Pantalla de Préstamos Vencidos:
- AppBar rojo con título "Préstamos Vencidos"
- Lista de cards con borde rojo
- Badge "VENCIDO" en cada préstamo
- Información: ID, monto, fecha inicio, cuotas
- Tap para ver detalles completos

## 🚀 Cómo Usar

### 1. Cargar Datos de Prueba
Ejecutar el script SQL en H2 Console:
```bash
# Ubicación del script
spring-boot-backend-loans/src/main/resources/overdue_loans_data.sql
```

### 2. Iniciar Backend
```bash
cd spring-boot-backend-loans
./mvnw spring-boot:run
```

### 3. Iniciar Flutter
```bash
cd loans_receipt_app
flutter run
```

### 4. Verificar
- Abrir la app
- En el home, debajo de las estadísticas, verás el banner rojo
- Tap en el banner para ver la lista completa
- Tap en cualquier préstamo para ver detalles

## 📊 Datos de Prueba

El script incluye:
- **6 préstamos vencidos** con diferentes niveles de atraso
- **4 usuarios nuevos** con información completa
- **Transacciones** asociadas a cada préstamo
- **Notificaciones** de préstamos vencidos

## 🔧 Estructura de Archivos

```
loans_receipt_app/
├── lib/
│   ├── data/
│   │   └── services/
│   │       └── api_service.dart (✏️ modificado)
│   └── presentation/
│       ├── screens/
│       │   ├── home_screen.dart (✏️ modificado)
│       │   └── overdue_loans_screen.dart (✨ nuevo)
│       └── widgets/
│           └── overdue_loans_banner.dart (✨ nuevo)
```

## 💡 Funcionalidades

### Banner Inteligente:
- ✅ Se oculta automáticamente si no hay préstamos vencidos
- ✅ Actualiza el contador en tiempo real
- ✅ Diseño responsive
- ✅ Animación de tap

### Pantalla de Detalles:
- ✅ Lista completa de préstamos vencidos
- ✅ Información resumida de cada préstamo
- ✅ Navegación a detalles completos
- ✅ Pull to refresh (heredado)
- ✅ Estado vacío con mensaje positivo

## 🎯 Próximas Mejoras Sugeridas

1. **Filtros por nivel de urgencia**
   - Crítico (>90 días)
   - Alto (30-90 días)
   - Medio (15-30 días)
   - Bajo (<15 días)

2. **Acciones rápidas**
   - Botón de llamada directa
   - Botón de WhatsApp
   - Marcar como contactado

3. **Notificaciones push**
   - Alertas automáticas
   - Recordatorios programados

4. **Dashboard de cobranza**
   - Métricas de recuperación
   - Historial de contactos
   - Notas del cobrador

5. **Cálculo de mora**
   - Días de atraso
   - Penalidades automáticas
   - Intereses moratorios

## 📝 Notas Técnicas

- El banner usa `FutureBuilder` implícito con `setState`
- La pantalla se actualiza al regresar de detalles
- Los colores usan `AppColors.error` para consistencia
- El diseño sigue el sistema de diseño existente
- Compatible con el flujo actual de navegación

## ✅ Testing

Para probar la funcionalidad:

1. **Sin préstamos vencidos:**
   - El banner no aparece
   - La pantalla muestra mensaje positivo

2. **Con préstamos vencidos:**
   - Banner visible con contador
   - Lista completa en pantalla de detalles
   - Navegación funcional

3. **Integración:**
   - Tap en banner → Pantalla de vencidos
   - Tap en préstamo → Detalles completos
   - Back → Actualiza datos
