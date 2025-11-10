# Módulo Administrador - TrustBank

## 📋 Descripción
Módulo completo para la gestión administrativa de solicitudes de envío de dinero, recargas y créditos en la aplicación TrustBank.

## 🏗️ Arquitectura
Sigue el patrón BLoC y la arquitectura atómica del sistema de diseño TrustBank:

### Estructura
```
admin/
├── models/
│   └── request_model.dart      # Modelo de solicitudes
├── bloc/
│   ├── admin_bloc.dart         # Lógica de negocio
│   ├── admin_event.dart        # Eventos
│   └── admin_state.dart        # Estados
├── screens/
│   └── admin_dashboard_screen.dart  # Pantalla principal
├── widgets/
│   ├── admin_stats.dart        # Estadísticas
│   ├── filter_chips.dart       # Filtros
│   ├── request_card.dart       # Tarjeta de solicitud
│   └── request_detail_dialog.dart   # Detalles
└── admin.dart                  # Exportaciones
```

## 🎯 Funcionalidades

### Dashboard Principal
- **Estadísticas**: Contadores de solicitudes pendientes, aprobadas y rechazadas
- **Filtros**: Por tipo (envío, recarga, crédito) y estado
- **Lista de solicitudes**: Vista completa con acciones

### Gestión de Solicitudes
- **Ver detalles**: Información completa de cada solicitud
- **Procesar**: Aprobar o rechazar con notas administrativas
- **Filtrar**: Por tipo y estado para mejor organización

### Tipos de Solicitudes
1. **Envío de dinero**: Transferencias entre usuarios
2. **Recargas**: Adición de saldo a cuentas
3. **Créditos**: Solicitudes de préstamos

## 🎨 Sistema de Diseño
Utiliza completamente el sistema de diseño TrustBank:
- **Colores**: Paleta TBColors
- **Tipografía**: TBTypography
- **Espaciado**: TBSpacing
- **Componentes**: TBButton, cards personalizadas

## 🚀 Uso

### Acceso
Desde la pantalla principal → Menú usuario → "Panel Admin"

### Navegación
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AdminDashboardScreen(),
  ),
);
```

## 📊 Estados de Solicitudes
- **Pendiente**: Requiere acción del administrador
- **Aprobado**: Solicitud procesada exitosamente
- **Rechazado**: Solicitud denegada con notas

## 🔧 Personalización
El módulo es completamente extensible:
- Agregar nuevos tipos de solicitudes
- Modificar flujos de aprobación
- Integrar con APIs reales
- Añadir notificaciones push