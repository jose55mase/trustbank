# Material Dashboard Flutter

Un dashboard Material Design desarrollado en Flutter usando arquitectura atómica y patrón BLoC, basado en el proyecto Material Dashboard Angular.

## Arquitectura

### Arquitectura Atómica
- **Atoms**: Componentes básicos reutilizables (botones, campos de texto)
- **Molecules**: Combinaciones de átomos (tarjetas, elementos de sidebar)
- **Organisms**: Componentes complejos (sidebar, navbar)
- **Templates**: Layouts de página (admin layout)
- **Pages**: Páginas completas de la aplicación

### Patrón BLoC
- Separación clara entre lógica de negocio y UI
- Estados inmutables usando Equatable
- Eventos para manejar acciones del usuario

## Estructura del Proyecto

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── router/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── atoms/
│   ├── molecules/
│   ├── organisms/
│   ├── templates/
│   ├── pages/
│   └── bloc/
└── shared/
    ├── widgets/
    └── extensions/
```

## Características

- ✅ Dashboard con tarjetas estadísticas
- ✅ Sistema de navegación con sidebar
- ✅ Página de login
- ✅ Perfil de usuario
- ✅ Lista de tablas
- ✅ Notificaciones
- ✅ Tema Material Design personalizado
- ✅ Navegación con GoRouter
- ✅ Gestión de estado con BLoC

## Instalación

1. Instalar dependencias:
```bash
flutter pub get
```

2. Ejecutar la aplicación:
```bash
flutter run
```

## Dependencias Principales

- `flutter_bloc`: Gestión de estado
- `go_router`: Navegación
- `equatable`: Comparación de objetos
- `flutter_svg`: Soporte para SVG
- `shared_preferences`: Almacenamiento local
- `http`: Cliente HTTP

## Páginas Disponibles

- `/login` - Página de inicio de sesión
- `/dashboard` - Dashboard principal con estadísticas
- `/user-profile` - Perfil del usuario
- `/table-list` - Lista de datos en tabla
- `/notifications` - Página de notificaciones