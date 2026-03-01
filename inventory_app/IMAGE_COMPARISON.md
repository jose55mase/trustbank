# Sistema de Comparación de Imágenes

## 🎯 Funcionalidad

El módulo de ventas ahora incluye un sistema inteligente de comparación de imágenes que permite:

- ✅ Capturar imagen de un producto con la cámara
- ✅ Comparar automáticamente con todas las imágenes del inventario
- ✅ Detectar productos similares usando hash perceptual
- ✅ Mostrar porcentaje de coincidencia
- ✅ Alertar cuando hay múltiples productos similares

## 🔧 Tecnología Utilizada

### Hash Perceptual (Perceptual Hashing)
Algoritmo que genera una "huella digital" de cada imagen basándose en características visuales:

1. **Redimensionar**: Imagen a 8x8 píxeles
2. **Escala de grises**: Convertir a blanco y negro
3. **Calcular promedio**: Obtener brillo promedio
4. **Generar hash**: Bits 1/0 según si cada píxel está sobre/bajo el promedio
5. **Comparar**: Contar bits coincidentes entre hashes

### Ventajas
- ⚡ Rápido: Comparación en milisegundos
- 🎯 Preciso: Detecta imágenes similares aunque tengan diferencias menores
- 📱 Offline: No requiere conexión a internet
- 💾 Ligero: No consume mucho almacenamiento

## 📊 Umbral de Similitud

**Configuración actual: 85%**

```dart
static const double _similarityThreshold = 0.85;
```

Puedes ajustar este valor en `image_comparison_service.dart`:
- **90-100%**: Muy estricto (solo imágenes casi idénticas)
- **80-90%**: Balanceado (recomendado)
- **70-80%**: Permisivo (detecta más variaciones)

## 🚀 Flujo de Uso

### 1. Capturar Imagen
```
Usuario presiona "Escanear Producto" → Abre cámara → Captura foto
```

### 2. Vista Previa
```
Muestra imagen capturada → Usuario confirma o repite
```

### 3. Comparación Automática
```
Sistema compara con todas las imágenes del inventario
↓
Calcula hash perceptual de la nueva imagen
↓
Compara con hashes de productos existentes
↓
Ordena resultados por similitud
```

### 4. Resultados

**Caso A: Producto único encontrado (sin similares)**
```
✅ Agrega directamente al carrito
```

**Caso B: Múltiples productos similares**
```
⚠️ Muestra diálogo con:
  - Producto principal (mayor coincidencia)
  - Porcentaje de similitud
  - Lista de productos similares
  - Opción de confirmar o cancelar
```

**Caso C: Sin coincidencias**
```
❌ Muestra mensaje "Producto no reconocido"
```

## 📁 Archivos Modificados/Creados

### Nuevos Archivos
- `lib/data/services/image_comparison_service.dart` - Servicio de comparación
- `lib/presentation/widgets/image_preview_dialog.dart` - Vista previa de imagen

### Archivos Modificados
- `lib/data/services/product_recognition_service.dart` - Integración con comparación
- `lib/presentation/screens/sales_screen.dart` - Diálogo de productos similares
- `lib/presentation/widgets/product_scanner.dart` - Vista previa antes de procesar
- `pubspec.yaml` - Dependencias `image` y `crypto`

## 🔄 Próximas Mejoras

- [ ] Caché de hashes para mejorar rendimiento
- [ ] Ajuste dinámico del umbral de similitud
- [ ] Historial de comparaciones
- [ ] Estadísticas de precisión
- [ ] Integración con ML Kit para detección avanzada
- [ ] Soporte para múltiples ángulos del mismo producto

## 💡 Ejemplo de Uso

```dart
// En sales_screen.dart
final result = await _recognitionService.recognizeProduct(
  imagePath,
  state.products,
);

if (result.product != null) {
  if (result.similarProducts.isNotEmpty) {
    // Mostrar diálogo con productos similares
    _showSimilarProductsDialog(
      result.product!,
      result.similarProducts,
      result.similarity!,
    );
  } else {
    // Agregar directamente al carrito
    _cart.add(result.product!);
  }
}
```

## ⚙️ Configuración

Para ajustar el tamaño del hash (afecta precisión vs velocidad):

```dart
// En image_comparison_service.dart
static const int _hashSize = 8; // Valores típicos: 8, 16, 32
```

- **8x8**: Rápido, menos preciso
- **16x16**: Balanceado
- **32x32**: Lento, muy preciso

## 🧪 Testing

Para probar la funcionalidad:

1. Agrega productos con imágenes al inventario
2. Ve al módulo de Ventas
3. Presiona "Escanear Producto"
4. Captura foto de un producto similar
5. Observa el diálogo con productos detectados

## 📝 Notas Técnicas

- Las imágenes se procesan localmente en el dispositivo
- El algoritmo es resistente a cambios de iluminación, rotación leve y escala
- No detecta el contenido semántico (ej: no sabe que es una "botella")
- Para reconocimiento semántico, considera integrar ML Kit o TensorFlow Lite
