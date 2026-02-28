import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/sale.dart';
import '../widgets/app_drawer.dart';

class SalesHistoryScreen extends StatefulWidget {
  final List<Sale> sales;

  const SalesHistoryScreen({super.key, required this.sales});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas'),
      ),
      drawer: const AppDrawer(currentRoute: '/sales-history'),
      body: widget.sales.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No hay ventas registradas', style: AppTextStyles.h3),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.sales.length,
              itemBuilder: (context, index) {
                final sale = widget.sales[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '${sale.products.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      currencyFormat.format(sale.total),
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateFormat.format(sale.date)),
                        if (sale.assignedUser != null)
                          Text('Usuario: ${sale.assignedUser!.name}', style: AppTextStyles.caption),
                        if (sale.customer != null)
                          Text('Cliente: ${sale.customer!.name}', style: AppTextStyles.caption),
                      ],
                    ),
                    children: sale.products.map((product) => ListTile(
                      dense: true,
                      title: Text(product.name),
                      trailing: Text(currencyFormat.format(product.price)),
                    )).toList(),
                  ),
                );
              },
            ),
    );
  }
}
