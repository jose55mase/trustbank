import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/loan.dart';

class StatsOverview extends StatelessWidget {
  final double totalLent;
  final double totalProfit;
  final double totalRemaining;
  final double totalRemainingFijo;
  final double totalRemainingRotativo;
  final double totalRemainingAhorros;
  final int activeLoans;
  final Function(String)? onLoanTypeClick;

  const StatsOverview({
    super.key,
    required this.totalLent,
    required this.totalProfit,
    required this.totalRemaining,
    required this.totalRemainingFijo,
    required this.totalRemainingRotativo,
    required this.totalRemainingAhorros,
    required this.activeLoans,
    this.onLoanTypeClick,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _StatItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Total Prestado',
              value: currencyFormat.format(totalLent),
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            _StatItem(
              icon: Icons.pending_actions_rounded,
              label: 'Saldo Pendiente Total',
              value: currencyFormat.format(totalRemaining),
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LoanTypeCard(
                    label: 'Fijo',
                    value: currencyFormat.format(totalRemainingFijo),
                    icon: Icons.lock_outline,
                    color: const Color(0xFF4CAF50),
                    onTap: () => onLoanTypeClick?.call('Fijo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _LoanTypeCard(
                    label: 'Rotativo',
                    value: currencyFormat.format(totalRemainingRotativo),
                    icon: Icons.autorenew,
                    color: const Color(0xFFFF9800),
                    onTap: () => onLoanTypeClick?.call('Rotativo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _LoanTypeCard(
                    label: 'Ahorros',
                    value: currencyFormat.format(totalRemainingAhorros),
                    icon: Icons.savings_outlined,
                    color: const Color(0xFF2196F3),
                    onTap: () => onLoanTypeClick?.call('Ahorros'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StatItem(
              icon: Icons.trending_up_rounded,
              label: 'Ganancia Total',
              value: currencyFormat.format(totalProfit),
              color: AppColors.secondaryLight,
            ),
            const SizedBox(height: 20),
            _StatItem(
              icon: Icons.receipt_long_rounded,
              label: 'Préstamos Activos',
              value: activeLoans.toString(),
              color: Colors.white,
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoanTypeCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _LoanTypeCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
