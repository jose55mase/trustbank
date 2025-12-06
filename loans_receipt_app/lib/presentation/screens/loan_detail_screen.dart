import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/user.dart';
import '../atoms/status_badge.dart';
import '../atoms/info_row.dart';
import '../widgets/app_drawer.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  final User user;

  const LoanDetailScreen({super.key, required this.loan, required this.user});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Préstamo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(user.name, style: AppTextStyles.h2),
                      StatusBadge(status: loan.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('ID: ${loan.id}', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Información del Préstamo', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  InfoRow(label: 'Monto Prestado', value: currencyFormat.format(loan.amount)),
                  InfoRow(label: 'Tasa de Interés', value: '${loan.interestRate}%'),
                  InfoRow(
                    label: 'Ganancia',
                    value: currencyFormat.format(loan.profit),
                    valueColor: AppColors.secondary,
                  ),
                  InfoRow(
                    label: 'Total a Pagar',
                    value: currencyFormat.format(loan.totalAmount),
                    valueColor: AppColors.primary,
                  ),
                  const Divider(height: 24),
                  InfoRow(label: 'Cuotas Totales', value: '${loan.installments}'),
                  InfoRow(label: 'Cuotas Pagadas', value: '${loan.paidInstallments}'),
                  InfoRow(label: 'Cuotas Pendientes', value: '${loan.installments - loan.paidInstallments}'),
                  InfoRow(label: 'Valor por Cuota', value: currencyFormat.format(loan.installmentAmount)),
                  InfoRow(
                    label: 'Monto Restante',
                    value: currencyFormat.format(loan.remainingAmount),
                    valueColor: AppColors.warning,
                  ),
                  const Divider(height: 24),
                  InfoRow(label: 'Fecha de Inicio', value: DateFormat('dd/MM/yyyy').format(loan.startDate)),
                  const SizedBox(height: 16),
                  const Text('Progreso', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: loan.paidInstallments / loan.installments,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((loan.paidInstallments / loan.installments) * 100).toStringAsFixed(1)}% completado',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
