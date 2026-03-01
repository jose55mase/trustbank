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
  static const double _similarityThreshold = 0.85;

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
    
    final newFile = File(newImagePath);
    if (!await newFile.exists()) return results;
    
    final newBytes = await newFile.readAsBytes();
    final newImage = img.decodeImage(newBytes);
    if (newImage == null) return results;
    
    final newHash = _calculatePerceptualHash(newImage);
    
    for (final entry in existingImages.entries) {
      final existingFile = File(entry.value);
      if (!await existingFile.exists()) continue;
      
      final existingBytes = await existingFile.readAsBytes();
      final existingImage = img.decodeImage(existingBytes);
      if (existingImage == null) continue;
      
      final existingHash = _calculatePerceptualHash(existingImage);
      final similarity = _compareHashes(newHash, existingHash);
      
      if (similarity >= _similarityThreshold) {
        results.add(ImageComparisonResult(
          imagePath: entry.value,
          similarity: similarity,
          productId: entry.key,
        ));
      }
    }
    
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    return results;
  }
}
