import '../models/product.dart';
import 'image_comparison_service.dart';

class ProductRecognitionService {
  final _comparisonService = ImageComparisonService();

  Future<ProductRecognitionResult> recognizeProduct(
    String imagePath,
    List<Product> products,
  ) async {
    final existingImages = <String, String>{};
    
    for (var product in products) {
      if (product.imageUrl != null && product.id != null) {
        existingImages[product.id.toString()] = product.imageUrl!;
      }
    }
    
    final matches = await _comparisonService.compareWithExisting(
      imagePath,
      existingImages,
    );
    
    if (matches.isEmpty) {
      return ProductRecognitionResult(product: null, similarProducts: []);
    }
    
    final bestMatch = matches.first;
    final matchedProduct = products.firstWhere(
      (p) => p.id.toString() == bestMatch.productId,
    );
    
    final similarProducts = matches
        .skip(1)
        .map((m) => products.firstWhere((p) => p.id.toString() == m.productId))
        .toList();
    
    return ProductRecognitionResult(
      product: matchedProduct,
      similarProducts: similarProducts,
      similarity: bestMatch.similarity,
    );
  }
}

class ProductRecognitionResult {
  final Product? product;
  final List<Product> similarProducts;
  final double? similarity;

  ProductRecognitionResult({
    required this.product,
    required this.similarProducts,
    this.similarity,
  });
}
