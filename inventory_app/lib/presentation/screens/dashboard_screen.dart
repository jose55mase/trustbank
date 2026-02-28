import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(
                icon: Icons.inventory_2,
                title: 'Productos',
                value: '0',
                color: AppColors.primary,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.shopping_cart,
                title: 'Ventas Hoy',
                value: currencyFormat.format(0),
                color: AppColors.success,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(
                icon: Icons.people,
                title: 'Clientes',
                value: '0',
                color: AppColors.secondary,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.warning,
                title: 'Stock Bajo',
                value: '0',
                color: AppColors.error,
              )),
            ],
          ),
          const SizedBox(height: 24),
          Text('Actividad Reciente', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          _EmptyState(
            icon: Icons.timeline,
            message: 'No hay actividad reciente',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.h2.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.bodySecondary),
          ],
        ),
      ),
    );
  }
}
