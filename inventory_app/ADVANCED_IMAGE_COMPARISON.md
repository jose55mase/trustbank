# Sistema Avanzado de Comparación de Imágenes

## 🎯 Problema Resuelto

Cuando dos productos tienen características similares (color, altura, fondo), el hash perceptual básico puede confundirlos. El nuevo sistema usa **4 algoritmos combinados** para mayor precisión.

## 🔬 Algoritmos Implementados

### 1. Hash Perceptual Mejorado (35% peso)
- **Qué hace**: Compara la estructura general de la imagen
- **Tamaño**: 16x16 (antes 8x8) para más detalle
- **Ventaja**: Detecta formas y patrones generales
- **Limitación**: Sensible a rotación y escala

### 2. Histograma de Colores (30% peso)
- **Qué hace**: Analiza la distribución de colores RGB
- **Bins**: 4x4x4 = 64 bins para precisión
- **Ventaja**: Distingue productos por paleta de colores
- **Limitación**: No considera posición espacial

### 3. Detección de Bordes (25% peso)
- **Qué hace**: Identifica contornos y formas usando Sobel
- **Ventaja**: Detecta la forma del producto independiente del color
- **Limitación**: Sensible a iluminación

### 4. Similitud Estructural (10% peso)
- **Qué hace**: Compara relación de aspecto (ancho/alto)
- **Ventaja**: Diferencia productos altos vs anchos
- **Limitación**: Solo considera proporciones

## 📊 Puntuación Final

```
Score = 0.35×Perceptual + 0.30×Color + 0.25×Bordes + 0.10×Estructura
```

**Umbral de similitud**: 75% (ajustable)

## 🔍 Ejemplo de Salida

```
Producto 1: 87.3% (P:92% C:85% E:88% S:95%)
Producto 2: 68.5% (P:70% C:75% E:60% S:90%)
```

- **P**: Perceptual (forma general)
- **C**: Color (paleta)
- **E**: Edge (bordes/contornos)
- **S**: Structure (proporciones)

## ⚙️ Configuración

Puedes ajustar los pesos en `advanced_image_comparison_service.dart`:

```dart
static const double _weightPerceptual = 0.35;  // Forma general
static const double _weightColor = 0.30;       // Colores
static const double _weightEdge = 0.25;        // Bordes
static const double _weightStructure = 0.10;   // Proporciones
```

### Casos de Uso

**Productos con colores muy diferentes**:
- Aumentar `_weightColor` a 0.40
- Reducir `_weightPerceptual` a 0.30

**Productos con formas únicas**:
- Aumentar `_weightEdge` a 0.35
- Reducir `_weightColor` a 0.25

**Productos de diferentes tamaños**:
- Aumentar `_weightStructure` a 0.20
- Ajustar otros proporcionalmente

## 🚀 Ventajas del Sistema

✅ **Mayor precisión**: 4 algoritmos vs 1  
✅ **Menos falsos positivos**: Distingue productos similares  
✅ **Desglose detallado**: Muestra qué tan similar es cada aspecto  
✅ **Configurable**: Ajusta pesos según tu inventario  
✅ **Sin internet**: Todo procesado localmente  

## 📈 Mejoras Futuras

- [ ] Machine Learning con TensorFlow Lite
- [ ] Detección de objetos (YOLO)
- [ ] Reconocimiento de texto (OCR) en etiquetas
- [ ] Comparación de texturas
- [ ] Cache de hashes para velocidad

## 🔧 Troubleshooting

**Problema**: Muchos falsos positivos  
**Solución**: Aumentar `_similarityThreshold` a 0.80

**Problema**: No encuentra productos similares  
**Solución**: Reducir `_similarityThreshold` a 0.70

**Problema**: Confunde productos por color  
**Solución**: Reducir `_weightColor` y aumentar `_weightEdge`

**Problema**: Lento en dispositivos antiguos  
**Solución**: Reducir `_hashSize` a 12 o usar el servicio básico
