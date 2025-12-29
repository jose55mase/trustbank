import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/user.dart';

class LoanDetailModal extends StatelessWidget {
  final Map<String, dynamic> loan;
  final User user;

  const LoanDetailModal({
    super.key,
    required this.loan,
    required this.user,
  });

  static void show(BuildContext context, Map<String, dynamic> loan, User user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => LoanDetailModal(loan: loan, user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');
    final amount = loan['amount'] ?? 0.0;
    final interestRate = loan['interestRate'] ?? 0.0;
    final installments = loan['installments'] ?? 0;
    final paidInstallments = loan['paidInstallments'] ?? 0;
    final totalAmount = loan['totalAmount'] ?? (amount + (amount * interestRate / 100));
    final installmentAmount = loan['installmentAmount'] ?? (totalAmount / installments);
    final remainingAmount = loan['remainingAmount'] ?? (installmentAmount * (installments - paidInstallments));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalle del Préstamo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${loan['id']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monto total destacado
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.secondary.withOpacity(0.1), AppColors.secondary.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Monto Total a Pagar',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(totalAmount),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Información del cliente
                    _buildSection(
                      'Cliente',
                      Icons.person,
                      [
                        _InfoRow('Nombre', user.name),
                        _InfoRow('Código', user.userCode),
                        _InfoRow('Teléfono', user.phone),
                        _InfoRow('Dirección', user.direccion),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Detalles financieros
                    _buildSection(
                      'Información Financiera',
                      Icons.attach_money,
                      [
                        _InfoRow('Monto Original', currencyFormat.format(amount)),
                        _InfoRow('Tasa de Interés', '${interestRate.toStringAsFixed(1)}%'),
                        _InfoRow('Tipo de Préstamo', loan['loanType'] ?? 'N/A'),
                        _InfoRow('Forma de Pago', loan['paymentFrequency'] ?? 'N/A'),
                        _InfoRow('Interés Total', currencyFormat.format(totalAmount - amount)),
                        _InfoRow('Monto Restante', currencyFormat.format(remainingAmount)),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Información de cuotas
                    _buildSection(
                      'Cuotas',
                      Icons.schedule,
                      [
                        _InfoRow('Total de Cuotas', '$installments'),
                        _InfoRow('Cuotas Pagadas', '$paidInstallments'),
                        _InfoRow('Cuotas Pendientes', '${installments - paidInstallments}'),
                        _InfoRow('Valor por Cuota', currencyFormat.format(installmentAmount)),
                        _InfoRow('Fecha de Inicio', loan['startDate'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(loan['startDate'])) : 'N/A'),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Estado del préstamo
                    _buildSection(
                      'Estado del Préstamo',
                      Icons.info,
                      [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(loan['status']),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getStatusIcon(loan['status']),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Estado Actual',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _getStatusText(loan['status']),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(loan['status']),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (loan['previousStatus'] != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow('Estado Anterior', _getStatusText(loan['previousStatus'])),
                          if (loan['statusChangeDate'] != null)
                            _InfoRow('Cambio de Estado', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(loan['statusChangeDate']!))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer con botones
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.primary;
      case 'COMPLETED':
        return AppColors.success;
      case 'OVERDUE':
        return AppColors.error;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'ACTIVE':
        return Icons.schedule;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'OVERDUE':
        return Icons.warning;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'ACTIVE':
        return 'Activo';
      case 'COMPLETED':
        return 'Completado';
      case 'OVERDUE':
        return 'Vencido';
      case 'CANCELLED':
        return 'Cancelado';
      default:
        return 'Activo';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}