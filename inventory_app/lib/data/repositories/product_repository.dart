import '../models/product.dart';

class ProductRepository {
  final List<Product> _products = [];

  Future<List<Product>> getProducts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_products);
  }

  Future<Product> addProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newProduct = product.copyWith(id: _products.length + 1);
    _products.add(newProduct);
    return newProduct;
  }

  Future<Product> updateProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
    return product;
  }

  Future<void> deleteProduct(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _products.removeWhere((p) => p.id == id);
  }
}
