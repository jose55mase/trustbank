import 'dart:io';
import 'package:image/image.dart' as img;

class ImageComparisonResult {
  final String imagePath;
  final double similarity;
  final String productId;

  ImageComparisonResult({
    required this.imagePath,
    required this.similarity,
    required this.productId,
  });
}

class ImageComparisonService {
  static const int _hashSize = 8;
  static const double _similarityThreshold = 0.70; // Reducido de 0.85 a 0.70 para mejor detección

  String _calculatePerceptualHash(img.Image image) {
    final resized = img.copyResize(image, width: _hashSize, height: _hashSize);
    final grayscale = img.grayscale(resized);
    
    final pixels = <int>[];
    for (int y = 0; y < _hashSize; y++) {
      for (int x = 0; x < _hashSize; x++) {
        final pixel = grayscale.getPixel(x, y);
        pixels.add(pixel.r.toInt());
      }
    }
    
    final avg = pixels.reduce((a, b) => a + b) / pixels.length;
    final hash = pixels.map((p) => p > avg ? '1' : '0').join();
    
    return hash;
  }

  double _compareHashes(String hash1, String hash2) {
    if (hash1.length != hash2.length) return 0.0;
    
    int matches = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] == hash2[i]) matches++;
    }
    
    return matches / hash1.length;
  }

  Future<List<ImageComparisonResult>> compareWithExisting(
    String newImagePath,
    Map<String, String> existingImages,
  ) async {
    final results = <ImageComparisonResult>[];
    
    print('📸 Iniciando comparación de imagen: $newImagePath');
    
    final newFile = File(newImagePath);
    if (!await newFile.exists()) {
      print('❌ ERROR: Archivo de imagen no existe: $newImagePath');
      return results;
    }
    
    final newBytes = await newFile.readAsBytes();
    final newImage = img.decodeImage(newBytes);
    if (newImage == null) {
      print('❌ ERROR: No se pudo decodificar la imagen');
      return results;
    }
    
    final newHash = _calculatePerceptualHash(newImage);
    print('✅ Hash calculado para nueva imagen: ${newHash.substring(0, 16)}...');
    
    int comparedCount = 0;
    for (final entry in existingImages.entries) {
      final existingFile = File(entry.value);
      if (!await existingFile.exists()) {
        print('⚠️ Imagen del producto ${entry.key} no existe: ${entry.value}');
        continue;
      }
      
      final existingBytes = await existingFile.readAsBytes();
      final existingImage = img.decodeImage(existingBytes);
      if (existingImage == null) {
        print('⚠️ No se pudo decodificar imagen del producto ${entry.key}');
        continue;
      }
      
      final existingHash = _calculatePerceptualHash(existingImage);
      final similarity = _compareHashes(newHash, existingHash);
      
      comparedCount++;
      print('   Producto ${entry.key}: ${(similarity * 100).toStringAsFixed(1)}% similar');
      
      if (similarity >= _similarityThreshold) {
        results.add(ImageComparisonResult(
          imagePath: entry.value,
          similarity: similarity,
          productId: entry.key,
        ));
      }
    }
    
    print('📊 Resumen: $comparedCount imágenes comparadas, ${results.length} coincidencias (umbral: ${(_similarityThreshold * 100).toStringAsFixed(0)}%)');
    
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    return results;
  }
}
