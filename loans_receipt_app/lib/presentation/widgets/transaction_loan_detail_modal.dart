import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/loan_status.dart';
import '../../domain/models/user.dart';
import '../../data/dummy_data.dart';

class TransactionLoanDetailModal extends StatelessWidget {
  final Transaction transaction;

  const TransactionLoanDetailModal({
    super.key,
    required this.transaction,
  });

  static void show(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TransactionLoanDetailModal(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');
    
    // Buscar el préstamo relacionado
    final loan = DummyData.loans.firstWhere(
      (l) => l.id == transaction.loanId,
      orElse: () => _createLoanFromTransaction(),
    );
    
    // Buscar el usuario
    final user = DummyData.users.firstWhere(
      (u) => u.name == transaction.userId,
      orElse: () => User(
        id: 'temp',
        name: transaction.userId,
        userCode: 'TEMP',
        phone: 'N/A',
        direccion: 'N/A',
        registrationDate: DateTime.now(),
      ),
    );

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
                          'ID: ${loan.id}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                            currencyFormat.format(loan.totalAmount),
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
                        _InfoRow('Monto Original', currencyFormat.format(loan.amount)),
                        _InfoRow('Tasa de Interés', '${loan.interestRate}%'),
                        _InfoRow('Interés Total', currencyFormat.format(loan.profit)),
                        _InfoRow('Monto Restante', currencyFormat.format(loan.remainingAmount)),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Información de cuotas
                    _buildSection(
                      'Cuotas',
                      Icons.schedule,
                      [
                        _InfoRow('Total de Cuotas', '${loan.installments}'),
                        _InfoRow('Cuotas Pagadas', '${loan.paidInstallments}'),
                        _InfoRow('Cuotas Pendientes', '${loan.installments - loan.paidInstallments}'),
                        _InfoRow('Valor por Cuota', currencyFormat.format(loan.installmentAmount)),
                        _InfoRow('Fecha de Inicio', DateFormat('dd/MM/yyyy').format(loan.startDate)),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Información de la transacción actual
                    _buildSection(
                      'Transacción Actual',
                      Icons.receipt,
                      [
                        _InfoRow('ID Transacción', transaction.id),
                        _InfoRow('Tipo', transaction.type == TransactionType.loan ? 'Préstamo' : 'Pago'),
                        _InfoRow('Monto', currencyFormat.format(transaction.amount)),
                        _InfoRow('Forma de Pago', _getPaymentMethodText(transaction.paymentMethod)),
                        _InfoRow('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)),
                        if (transaction.notes?.isNotEmpty == true)
                          _InfoRow('Notas', transaction.notes!),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Estado del préstamo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(loan.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(loan.status).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(loan.status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getStatusIcon(loan.status),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estado del Préstamo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _getStatusText(loan.status),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(loan.status),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Aquí se puede implementar la funcionalidad de imprimir o exportar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funcionalidad próximamente')),
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Imprimir'),
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

  Loan _createLoanFromTransaction() {
    // Crear un préstamo temporal basado en la transacción
    return Loan(
      id: transaction.loanId,
      userId: transaction.userId,
      amount: transaction.amount,
      interestRate: 15.0, // Tasa por defecto
      installments: 12, // Cuotas por defecto
      paidInstallments: transaction.type == TransactionType.payment ? 1 : 0,
      startDate: transaction.date,
      status: LoanStatus.active,
      remainingAmount: transaction.amount, // Monto restante por defecto
    );
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.check:
        return 'Cheque';
    }
  }

  Color _getStatusColor(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return AppColors.primary;
      case LoanStatus.completed:
        return AppColors.success;
      case LoanStatus.overdue:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return Icons.schedule;
      case LoanStatus.completed:
        return Icons.check_circle;
      case LoanStatus.overdue:
        return Icons.warning;
    }
  }

  String _getStatusText(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return 'Activo';
      case LoanStatus.completed:
        return 'Completado';
      case LoanStatus.overdue:
        return 'Vencido';
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