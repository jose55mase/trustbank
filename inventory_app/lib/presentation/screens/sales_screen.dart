import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/product_bloc.dart';
import '../../bloc/product_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product.dart';
import '../../data/services/product_recognition_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/product_scanner.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _recognitionService = ProductRecognitionService();
  final List<Product> _cart = [];
  bool _isScanning = false;

  Future<void> _onProductScanned(String imagePath) async {
    setState(() => _isScanning = true);

    final state = context.read<ProductBloc>().state;
    if (state is ProductLoaded) {
      final product = await _recognitionService.recognizeProduct(
        imagePath,
        state.products,
      );

      if (mounted) {
        setState(() => _isScanning = false);

        if (product != null) {
          setState(() => _cart.add(product));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto agregado: ${product.name}'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto no reconocido'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  double get _total {
    return _cart.fold(0, (sum, product) => sum + product.price);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => setState(() => _cart.clear()),
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/sales'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ProductScanner(onImageCaptured: _onProductScanned),
          ),
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 80, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text('Carrito vacío', style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        Text('Escanea productos para agregar',
                            style: AppTextStyles.bodySecondary),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final product = _cart[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.inventory_2,
                              color: AppColors.primary),
                          title: Text(product.name, style: AppTextStyles.body),
                          subtitle: Text(product.category,
                              style: AppTextStyles.caption),
                          trailing: Text(
                            currencyFormat.format(product.price),
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: AppTextStyles.h2),
                      Text(
                        currencyFormat.format(_total),
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Venta procesada exitosamente'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        setState(() => _cart.clear());
                      },
                      child: const Text('Procesar Venta'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
