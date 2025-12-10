import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/user.dart';
import '../../domain/models/transaction.dart';
import '../../data/services/transaction_service.dart';
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
                  const InfoRow(label: 'Forma de Pago', value: 'Mensual'),
                  const InfoRow(label: 'Tipo de Préstamo', value: 'Fijo'),
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
                  const InfoRow(label: 'Estado Pago Anterior', value: 'Pagado', valueColor: AppColors.success),
                  const InfoRow(label: 'Estado Pago Actual', value: 'Pendiente', valueColor: AppColors.warning),
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
      bottomNavigationBar: loan.status == LoanStatus.active
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showPaymentDialog(context, loan, currencyFormat);
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Registrar Pago'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _showPaymentDialog(BuildContext context, Loan loan, NumberFormat currencyFormat) {
    final paymentController = TextEditingController(
      text: loan.installmentAmount.toStringAsFixed(0),
    );
    final notesController = TextEditingController();
    bool useCustomAmount = false;
    String selectedPaymentMethod = 'Efectivo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrar Pago'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuota #${loan.paidInstallments + 1}', style: AppTextStyles.caption),
                const SizedBox(height: 16),
                const Text('Valor de la cuota:'),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(loan.installmentAmount),
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ingresar monto diferente'),
                  value: useCustomAmount,
                  onChanged: (value) {
                    setState(() {
                      useCustomAmount = value ?? false;
                      if (!useCustomAmount) {
                        paymentController.text = loan.installmentAmount.toStringAsFixed(0);
                      }
                    });
                  },
                ),
                if (useCustomAmount) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: paymentController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Monto a pagar',
                      prefixText: '\$ ',
                      border: const OutlineInputBorder(),
                      helperText: 'Máximo: ${currencyFormat.format(loan.remainingAmount)}',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Método de pago:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPaymentMethod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: ['Efectivo', 'Transferencia', 'Cheque']
                      .map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(paymentController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El monto debe ser mayor a 0')),
                  );
                  return;
                }
                
                if (amount > loan.remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El monto no puede exceder el saldo pendiente')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                _processPayment(context, loan, amount, selectedPaymentMethod, notesController.text, currencyFormat);
              },
              child: const Text('Confirmar Pago'),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment(BuildContext context, Loan loan, double amount, String paymentMethod, String notes, NumberFormat currencyFormat) {
    final interestPortion = (amount * loan.interestRate / 100).clamp(0.0, amount);
    final principalPortion = amount - interestPortion;
    
    // Crear la transacción real
    PaymentMethod method;
    switch (paymentMethod) {
      case 'Transferencia':
        method = PaymentMethod.transfer;
        break;
      case 'Cheque':
        method = PaymentMethod.check;
        break;
      default:
        method = PaymentMethod.cash;
    }
    
    final transaction = TransactionService.createPayment(
      loanId: loan.id,
      userId: user.id,
      amount: amount,
      paymentMethod: method,
      notes: notes.isNotEmpty ? notes : 'Pago cuota #${loan.paidInstallments + 1}',
    );
    
    // Actualizar la transacción con los montos de interés y capital
    final updatedTransaction = Transaction(
      id: transaction.id,
      type: transaction.type,
      userId: transaction.userId,
      loanId: transaction.loanId,
      amount: transaction.amount,
      date: transaction.date,
      paymentMethod: transaction.paymentMethod,
      notes: transaction.notes,
      interestAmount: interestPortion,
      principalAmount: principalPortion,
    );
    
    // Reemplazar en la lista (simulación de actualización)
    final transactions = TransactionService.getAllTransactions();
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = updatedTransaction;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pago Registrado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID Transacción: ${transaction.id}'),
            const SizedBox(height: 8),
            Text('Monto total: ${currencyFormat.format(amount)}'),
            Text('Capital: ${currencyFormat.format(principalPortion)}'),
            Text('Interés: ${currencyFormat.format(interestPortion)}'),
            Text('Método: $paymentMethod'),
            if (notes.isNotEmpty) Text('Notas: $notes'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}