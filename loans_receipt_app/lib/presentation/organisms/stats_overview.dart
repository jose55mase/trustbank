import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class StatsOverview extends StatelessWidget {
  final double totalLent;
  final double totalProfit;
  final int activeLoans;

  const StatsOverview({
    super.key,
    required this.totalLent,
    required this.totalProfit,
    required this.activeLoans,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _StatItem(
              icon: Icons.account_balance_wallet,
              label: 'Total Prestado',
              value: currencyFormat.format(totalLent),
              color: AppColors.primary,
            ),
            const Divider(height: 24),
            _StatItem(
              icon: Icons.trending_up,
              label: 'Ganancia Total',
              value: currencyFormat.format(totalProfit),
              color: AppColors.secondary,
            ),
            const Divider(height: 24),
            _StatItem(
              icon: Icons.receipt_long,
              label: 'Préstamos Activos',
              value: activeLoans.toString(),
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 4),
              Text(value, style: AppTextStyles.h3),
            ],
          ),
        ),
      ],
    );
  }
}
