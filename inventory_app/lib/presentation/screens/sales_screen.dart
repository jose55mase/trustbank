import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/product_bloc.dart';
import '../../bloc/product_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../data/models/user.dart';
import '../../data/models/customer.dart';
import '../../data/services/product_recognition_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/product_scanner.dart';
import 'sales_history_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _recognitionService = ProductRecognitionService();
  final List<Product> _cart = [];
  final List<Sale> _pendingSales = [];
  final List<Sale> _processedSales = [];
  bool _isScanning = false;
  Customer? _selectedCustomer;
  
  final List<User> _users = [
    User(id: '1', name: 'Juan Pérez'),
    User(id: '2', name: 'María García'),
    User(id: '3', name: 'Carlos López'),
  ];
  
  final List<Customer> _customers = [
    Customer(id: '1', name: 'Cliente General'),
    Customer(id: '2', name: 'Empresa ABC'),
    Customer(id: '3', name: 'Tienda XYZ'),
  ];

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
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SalesHistoryScreen(sales: _processedSales),
              ),
            ),
          ),
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
                  if (_selectedCustomer != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedCustomer!.name,
                              style: AppTextStyles.body.copyWith(color: AppColors.primary),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _selectedCustomer = null),
                          ),
                        ],
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _showCustomerSelectionDialog(),
                    icon: const Icon(Icons.person_add),
                    label: Text(_selectedCustomer == null ? 'Asignar Cliente (Opcional)' : 'Cambiar Cliente'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      onPressed: () => _showUserSelectionDialog(),
                      child: const Text('Apilar Venta'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _pendingSales.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showPendingSalesDialog(),
              icon: const Icon(Icons.layers),
              label: Text('${_pendingSales.length}'),
            )
          : null,
    );
  }

  void _showCustomerSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _customers.map((customer) => ListTile(
            title: Text(customer.name),
            onTap: () {
              setState(() => _selectedCustomer = customer);
              Navigator.pop(context);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showUserSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _users.map((user) => ListTile(
            title: Text(user.name),
            onTap: () {
              Navigator.pop(context);
              _addSaleToPending(user);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _addSaleToPending(User user) {
    final sale = Sale(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      products: List.from(_cart),
      total: _total,
      date: DateTime.now(),
      assignedUser: user,
      customer: _selectedCustomer,
    );
    setState(() {
      _pendingSales.add(sale);
      _cart.clear();
      _selectedCustomer = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Venta apilada para ${user.name}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showPendingSalesDialog() {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ventas Pendientes'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _pendingSales.length,
            itemBuilder: (context, index) {
              final sale = _pendingSales[index];
              return Card(
                child: ListTile(
                  title: Text(sale.assignedUser?.name ?? 'Sin usuario'),
                  subtitle: Text(
                    sale.customer != null
                        ? '${sale.products.length} productos • ${sale.customer!.name}'
                        : '${sale.products.length} productos',
                  ),
                  trailing: Text(
                    currencyFormat.format(sale.total),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processAllSales();
            },
            child: const Text('Procesar Todas'),
          ),
        ],
      ),
    );
  }

  void _processAllSales() {
    final total = _pendingSales.fold(0.0, (sum, sale) => sum + sale.total);
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);
    setState(() {
      _processedSales.addAll(_pendingSales);
      _pendingSales.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ventas procesadas: ${currencyFormat.format(total)}'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
