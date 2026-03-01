# Inventory App

Aplicación de gestión de inventario y productos para tiendas, construida con Flutter usando arquitectura BLoC y diseño atómico.

## 🎨 Sistema de Diseño

Este proyecto utiliza el mismo sistema de diseño del proyecto `loans_receipt_app`:

- **Colores**: Paleta azul índigo y dorado elegante
- **Tipografía**: Estilos consistentes (h1, h2, h3, body, caption)
- **Componentes**: Diseño atómico (átomos, moléculas, organismos)

## 🏗️ Arquitectura

### Diseño Atómico
- **Átomos**: Componentes básicos (AppButton, InfoRow, StockBadge)
- **Moléculas**: Componentes compuestos (ProductCard)
- **Organismos**: Secciones complejas
- **Pantallas**: Vistas completas

### BLoC Pattern
- **Bloc**: Lógica de negocio separada de la UI
- **Events**: Acciones del usuario (LoadProducts, AddProduct, etc.)
- **States**: Estados de la aplicación (Loading, Loaded, Error)

## 📁 Estructura del Proyecto

```
lib/
├── bloc/                    # BLoC (eventos, estados, lógica)
│   ├── product_bloc.dart
│   ├── product_event.dart
│   └── product_state.dart
├── core/                    # Configuración central
│   └── theme/              # Sistema de diseño
│       ├── app_colors.dart
│       ├── app_text_styles.dart
│       └── app_theme.dart
├── data/                    # Capa de datos
│   ├── models/             # Modelos de datos
│   │   └── product.dart
│   └── repositories/       # Repositorios
│       └── product_repository.dart
└── presentation/           # Capa de presentación
    ├── atoms/              # Componentes básicos
    │   ├── app_button.dart
    │   ├── info_row.dart
    │   └── stock_badge.dart
    ├── molecules/          # Componentes compuestos
    │   └── product_card.dart
    └── screens/            # Pantallas
        ├── products_screen.dart
        └── add_product_screen.dart
```

## 🚀 Características

- ✅ Listar productos del inventario
- ✅ Agregar nuevos productos
- ✅ Eliminar productos
- ✅ Indicadores de stock (Sin Stock, Stock Bajo, En Stock)
- ✅ Diseño responsive y elegante
- ✅ Gestión de estado con BLoC
- ✅ **Módulo de Ventas con reconocimiento de imágenes**
- ✅ **Comparación inteligente de productos por imagen**
- ✅ **Detección de productos similares con hash perceptual**

## 📦 Dependencias

```yaml
dependencies:
  flutter_bloc: ^8.1.3      # Gestión de estado
  equatable: ^2.0.5         # Comparación de objetos
  intl: ^0.19.0            # Formateo de números/fechas
  http: ^1.1.0             # Peticiones HTTP
  shared_preferences: ^2.2.2 # Almacenamiento local
  image_picker: ^1.0.7     # Captura de imágenes
  path_provider: ^2.1.2    # Rutas del sistema
  image: ^4.0.17           # Procesamiento de imágenes
  crypto: ^3.0.3           # Hashing y encriptación
```

## 🎯 Próximas Funcionalidades

- [ ] Editar productos existentes
- [ ] Búsqueda y filtros
- [ ] Categorías personalizadas
- [ ] Integración con backend
- [ ] Reportes y estadísticas
- [ ] Escaneo de códigos de barras
- [ ] Historial de movimientos

## 🔧 Instalación

1. Clonar el repositorio
2. Instalar dependencias:
   ```bash
   flutter pub get
   ```
3. Ejecutar la aplicación:
   ```bash
   flutter run
   ```

## 💡 Uso

1. **Ver Inventario**: La pantalla principal muestra todos los productos
2. **Agregar Producto**: Presiona el botón flotante "+" para agregar
3. **Eliminar Producto**: Presiona el ícono de papelera en cada tarjeta
4. **Módulo de Ventas**: 
   - Escanea productos con la cámara
   - El sistema compara automáticamente con el inventario
   - Detecta productos similares y muestra porcentaje de coincidencia
   - Agrega productos al carrito y procesa ventas

## 🔍 Sistema de Comparación de Imágenes

El módulo de ventas incluye un sistema inteligente de reconocimiento de productos:

- **Hash Perceptual**: Algoritmo que compara imágenes por características visuales
- **Detección Automática**: Identifica productos al capturar una foto
- **Productos Similares**: Alerta cuando encuentra múltiples coincidencias
- **Umbral de Similitud**: 85% de coincidencia configurable
- **Procesamiento Local**: No requiere conexión a internet

📖 Ver documentación completa en [IMAGE_COMPARISON.md](IMAGE_COMPARISON.md)

## 🎨 Personalización

El sistema de diseño está centralizado en `lib/core/theme/`:
- Modifica `app_colors.dart` para cambiar la paleta de colores
- Ajusta `app_text_styles.dart` para cambiar tipografías
- Personaliza `app_theme.dart` para modificar el tema general
