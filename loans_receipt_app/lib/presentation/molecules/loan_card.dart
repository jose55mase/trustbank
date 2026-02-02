import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/user.dart';
import '../atoms/status_badge.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final User user;
  final VoidCallback onTap;
  final double? montoRestanteParaCompletarCuota;

  const LoanCard({
    super.key,
    required this.loan,
    required this.user,
    required this.onTap,
    this.montoRestanteParaCompletarCuota,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      user.name,
                      style: AppTextStyles.h3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(status: loan.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoColumn(
                    label: 'Monto',
                    value: currencyFormat.format(loan.amount),
                  ),
                  _InfoColumn(
                    label: 'Ganancia',
                    value: currencyFormat.format(loan.profit),
                    valueColor: AppColors.secondary,
                  ),
                  _InfoColumn(
                    label: 'Cuotas',
                    value: '${loan.paidInstallments}/${loan.installments}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Mostrar monto restante para completar cuota si existe
              if (montoRestanteParaCompletarCuota != null && montoRestanteParaCompletarCuota! > 0) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.purple, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Monto Restante: ${currencyFormat.format(montoRestanteParaCompletarCuota!)}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: loan.paidInstallments / loan.installments,
                  backgroundColor: AppColors.border.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
