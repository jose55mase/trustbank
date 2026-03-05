import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

class ImageComparisonResult {
  final String imagePath;
  final double similarity;
  final String productId;
  final Map<String, double> scores; // Desglose de puntuaciones

  ImageComparisonResult({
    required this.imagePath,
    required this.similarity,
    required this.productId,
    required this.scores,
  });
}

class AdvancedImageComparisonService {
  static const int _hashSize = 12;
  static const double _similarityThreshold = 0.65;
  
  static const double _weightPerceptual = 0.45;
  static const double _weightColor = 0.20;
  static const double _weightEdge = 0.25;
  static const double _weightStructure = 0.10;

  // Hash perceptual mejorado
  String _calculatePerceptualHash(img.Image image) {
    final resized = img.copyResize(image, width: _hashSize, height: _hashSize);
    final grayscale = img.grayscale(resized);
    
    final pixels = <int>[];
    for (int y = 0; y < _hashSize; y++) {
      for (int x = 0; x < _hashSize; x++) {
        pixels.add(grayscale.getPixel(x, y).r.toInt());
      }
    }
    
    final avg = pixels.reduce((a, b) => a + b) / pixels.length;
    return pixels.map((p) => p > avg ? '1' : '0').join();
  }

  List<double> _calculateColorHistogram(img.Image image) {
    final histogram = List<int>.filled(27, 0);
    final resized = img.copyResize(image, width: 64, height: 64);
    
    int totalPixels = 0;
    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        final r = (pixel.r / 85).floor().clamp(0, 2);
        final g = (pixel.g / 85).floor().clamp(0, 2);
        final b = (pixel.b / 85).floor().clamp(0, 2);
        final bin = r * 9 + g * 3 + b;
        histogram[bin]++;
        totalPixels++;
      }
    }
    
    return histogram.map((count) => count / totalPixels).toList();
  }

  // Detección de bordes (Sobel simplificado)
  String _calculateEdgeHash(img.Image image) {
    final resized = img.copyResize(image, width: _hashSize, height: _hashSize);
    final grayscale = img.grayscale(resized);
    
    final edges = <double>[];
    for (int y = 1; y < _hashSize - 1; y++) {
      for (int x = 1; x < _hashSize - 1; x++) {
        final gx = grayscale.getPixel(x + 1, y).r - grayscale.getPixel(x - 1, y).r;
        final gy = grayscale.getPixel(x, y + 1).r - grayscale.getPixel(x, y - 1).r;
        edges.add(sqrt(gx * gx + gy * gy));
      }
    }
    
    final avg = edges.reduce((a, b) => a + b) / edges.length;
    return edges.map((e) => e > avg ? '1' : '0').join();
  }

  // Comparación de hashes
  double _compareHashes(String hash1, String hash2) {
    if (hash1.length != hash2.length) return 0.0;
    int matches = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] == hash2[i]) matches++;
    }
    return matches / hash1.length;
  }

  double _compareHistograms(List<double> hist1, List<double> hist2) {
    double sum = 0.0;
    for (int i = 0; i < hist1.length; i++) {
      sum += sqrt(hist1[i] * hist2[i]);
    }
    return sum.clamp(0.0, 1.0);
  }

  // Similitud estructural (relación de aspecto y tamaño)
  double _compareStructure(img.Image img1, img.Image img2) {
    final ratio1 = img1.width / img1.height;
    final ratio2 = img2.width / img2.height;
    final ratioDiff = (ratio1 - ratio2).abs() / max(ratio1, ratio2);
    return 1.0 - ratioDiff.clamp(0.0, 1.0);
  }

  Future<List<ImageComparisonResult>> compareWithExisting(
    String newImagePath,
    Map<String, String> existingImages,
  ) async {
    final results = <ImageComparisonResult>[];
    
    final newFile = File(newImagePath);
    if (!await newFile.exists()) return results;
    
    final newBytes = await newFile.readAsBytes();
    final newImage = img.decodeImage(newBytes);
    if (newImage == null) return results;
    
    final newNormalized = img.copyResize(newImage, width: 256, height: 256);
    final newPerceptualHash = _calculatePerceptualHash(newNormalized);
    final newColorHist = _calculateColorHistogram(newNormalized);
    final newEdgeHash = _calculateEdgeHash(newNormalized);
    
    print('🔍 Comparación avanzada iniciada');
    
    for (final entry in existingImages.entries) {
      final existingFile = File(entry.value);
      if (!await existingFile.exists()) continue;
      
      final existingBytes = await existingFile.readAsBytes();
      final existingImage = img.decodeImage(existingBytes);
      if (existingImage == null) continue;
      
      final existingNormalized = img.copyResize(existingImage, width: 256, height: 256);
      final existingPerceptualHash = _calculatePerceptualHash(existingNormalized);
      final existingColorHist = _calculateColorHistogram(existingNormalized);
      final existingEdgeHash = _calculateEdgeHash(existingNormalized);
      
      // Calcular similitudes individuales
      final perceptualScore = _compareHashes(newPerceptualHash, existingPerceptualHash);
      final colorScore = _compareHistograms(newColorHist, existingColorHist);
      final edgeScore = _compareHashes(newEdgeHash, existingEdgeHash);
      final structureScore = _compareStructure(newImage, existingImage);
      
      // Puntuación ponderada final
      final finalScore = 
        perceptualScore * _weightPerceptual +
        colorScore * _weightColor +
        edgeScore * _weightEdge +
        structureScore * _weightStructure;
      
      print('   Producto ${entry.key}: ${(finalScore * 100).toStringAsFixed(1)}% '
            '(P:${(perceptualScore * 100).toStringAsFixed(0)}% '
            'C:${(colorScore * 100).toStringAsFixed(0)}% '
            'E:${(edgeScore * 100).toStringAsFixed(0)}% '
            'S:${(structureScore * 100).toStringAsFixed(0)}%)');
      
      if (finalScore >= _similarityThreshold) {
        results.add(ImageComparisonResult(
          imagePath: entry.value,
          similarity: finalScore,
          productId: entry.key,
          scores: {
            'perceptual': perceptualScore,
            'color': colorScore,
            'edge': edgeScore,
            'structure': structureScore,
          },
        ));
      }
    }
    
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    print('✅ ${results.length} coincidencias encontradas');
    return results;
  }
}
