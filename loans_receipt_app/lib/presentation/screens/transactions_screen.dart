import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/transaction.dart';
import '../../data/services/transaction_service.dart';
import '../widgets/app_drawer.dart';

class _DummyDataInitializer {
  static bool _initialized = false;
  
  static void initializeDummyData() {
    if (_initialized) return;
    _initialized = true;
    
    final now = DateTime.now();
    
    // Préstamos
    TransactionService.createLoan(
      loanId: 'L001',
      userId: 'Juan Pérez',
      amount: 5000000,
      notes: 'Préstamo para negocio',
      loanType: LoanType.fixed,
    );
    
    TransactionService.createLoan(
      loanId: 'L002',
      userId: 'María García',
      amount: 3000000,
      notes: 'Préstamo personal',
      loanType: LoanType.revolving,
    );
    
    TransactionService.createLoan(
      loanId: 'L003',
      userId: 'Carlos Rodríguez',
      amount: 8000000,
      notes: 'Préstamo para vivienda',
      loanType: LoanType.fixed,
    );
    
    // Pagos recientes
    TransactionService.createPayment(
      loanId: 'L001',
      userId: 'Juan Pérez',
      amount: 500000,
      paymentMethod: PaymentMethod.cash,
      notes: 'Pago cuota #1',
      loanType: LoanType.fixed,
    );
    
    TransactionService.createPayment(
      loanId: 'L002',
      userId: 'María García',
      amount: 350000,
      paymentMethod: PaymentMethod.transfer,
      notes: 'Pago cuota #1',
      loanType: LoanType.revolving,
    );
    
    TransactionService.createPayment(
      loanId: 'L001',
      userId: 'Juan Pérez',
      amount: 500000,
      paymentMethod: PaymentMethod.cash,
      notes: 'Pago cuota #2',
      loanType: LoanType.fixed,
    );
    
    TransactionService.createPayment(
      loanId: 'L003',
      userId: 'Carlos Rodríguez',
      amount: 750000,
      paymentMethod: PaymentMethod.transfer,
      notes: 'Pago cuota #1',
      loanType: LoanType.fixed,
    );
    
    // Modificar fechas para simular historial
    final transactions = TransactionService.getAllTransactions();
    if (transactions.length >= 7) {
      for (int i = 0; i < 7; i++) {
        transactions[i] = Transaction(
          id: transactions[i].id,
          type: transactions[i].type,
          userId: transactions[i].userId,
          loanId: transactions[i].loanId,
          amount: transactions[i].amount,
          date: now.subtract(Duration(days: 30 - (i * 5))),
          paymentMethod: transactions[i].paymentMethod,
          notes: transactions[i].notes,
          loanType: transactions[i].loanType,
          interestAmount: i >= 3 ? (transactions[i].amount * 0.15) : null,
          principalAmount: i >= 3 ? (transactions[i].amount * 0.85) : null,
        );
      }
    }
  }
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String selectedFilter = 'Todas';
  String? loanTypeFilter;
  DateTime? selectedDate;
  DateTimeRange? selectedDateRange;
  Transaction? selectedTransaction;

  List<Transaction> get transactions {
    _DummyDataInitializer.initializeDummyData();
    return TransactionService.getAllTransactions();
  }

  List<Transaction> get filteredTransactions {
    var filtered = transactions;
    
    if (selectedDate != null) {
      filtered = filtered.where((t) {
        return t.date.year == selectedDate!.year && 
               t.date.month == selectedDate!.month && 
               t.date.day == selectedDate!.day;
      }).toList();
    }
    
    if (selectedDateRange != null) {
      filtered = filtered.where((t) {
        return t.date.isAfter(selectedDateRange!.start.subtract(const Duration(days: 1))) &&
               t.date.isBefore(selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    if (selectedFilter != 'Todas') {
      final type = selectedFilter == 'Préstamo' ? TransactionType.loan : TransactionType.payment;
      filtered = filtered.where((t) => t.type == type).toList();
    }
    
    if (loanTypeFilter != null) {
      final loanType = loanTypeFilter == 'Fijo' ? LoanType.fixed : LoanType.revolving;
      filtered = filtered.where((t) => t.loanType == loanType).toList();
    }
    
    return filtered..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, double> get summaryData {
    return TransactionService.calculateAccountingSummary(filteredTransactions);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');
    final filtered = filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTransactionDialog(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildFilters(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${filtered.length} transacciones', style: AppTextStyles.h3),
                    if (filtered.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _exportTransactions(filtered),
                        icon: const Icon(Icons.download),
                        label: const Text('Exportar'),
                      ),
                  ],
                ),
                if (filtered.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet, 
                                       color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Total', 
                                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(_getTotalAmount(filtered)),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.secondary.withOpacity(0.1), AppColors.secondary.withOpacity(0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.trending_up, 
                                       color: AppColors.secondary, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Con Interés', 
                                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(_getTotalWithInterest(filtered)),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No hay transacciones', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: selectedTransaction != null ? 2 : 3,
                        child: Stack(
                          children: [
                            ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 100),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final transaction = filtered[index];
                                final isPayment = transaction.type == TransactionType.payment;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () => setState(() {
                                      selectedTransaction = selectedTransaction?.id == transaction.id ? null : transaction;
                                    }),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: (isPayment ? AppColors.success : AppColors.primary).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              isPayment ? Icons.arrow_downward : Icons.arrow_upward,
                                              color: isPayment ? AppColors.success : AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Usuario: ${transaction.userId}',
                                                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text('${isPayment ? 'Pago' : 'Préstamo'} • ${transaction.id}'),
                                                    if (transaction.loanType != null) ...[
                                                      const Text(' • '),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                        decoration: BoxDecoration(
                                                          color: transaction.loanType == LoanType.fixed 
                                                              ? Colors.blue.withOpacity(0.1) 
                                                              : Colors.orange.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          transaction.loanType == LoanType.fixed ? 'Fijo' : 'Rotativo',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: transaction.loanType == LoanType.fixed 
                                                                ? Colors.blue 
                                                                : Colors.orange,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
                                                  style: AppTextStyles.caption,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${isPayment ? '+' : '-'} ${currencyFormat.format(transaction.amount)}',
                                                    style: AppTextStyles.body.copyWith(
                                                      fontWeight: FontWeight.w700,
                                                      color: isPayment ? AppColors.success : AppColors.primary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.success.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      _getPaymentMethodText(transaction.paymentMethod),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors.success,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                selectedTransaction?.id == transaction.id 
                                                    ? Icons.keyboard_arrow_left 
                                                    : Icons.keyboard_arrow_right,
                                                color: Colors.grey,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      if (selectedTransaction != null)
                        Expanded(
                          flex: 1,
                          child: _buildTransactionDetailPanel(selectedTransaction!, currencyFormat),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetailPanel(Transaction transaction, NumberFormat currencyFormat) {
    final isPayment = transaction.type == TransactionType.payment;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: const Border(
          left: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Detalle ${isPayment ? 'Pago' : 'Préstamo'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => selectedTransaction = null),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow('ID Transacción', transaction.id),
                  _DetailRow('Usuario', transaction.userId),
                  _DetailRow('Monto', currencyFormat.format(transaction.amount)),
                  _DetailRow('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)),
                  const Divider(height: 24),
                  _DetailRow('ID Préstamo', transaction.loanId),
                  if (transaction.loanType != null)
                    _DetailRow('Tipo de Préstamo', transaction.loanType == LoanType.fixed ? 'Fijo' : 'Rotativo'),
                  _DetailRow('Método de Pago', _getPaymentMethodText(transaction.paymentMethod)),
                  if (transaction.notes?.isNotEmpty == true)
                    _DetailRow('Notas', transaction.notes!),
                  if (isPayment && transaction.interestAmount != null) ...[
                    const Divider(height: 24),
                    _DetailRow('Capital', currencyFormat.format(transaction.principalAmount ?? 0)),
                    _DetailRow('Interés', currencyFormat.format(transaction.interestAmount ?? 0)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Filtros:'),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                      selectedDateRange = null;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(selectedDate != null 
                    ? DateFormat('dd/MM/yyyy').format(selectedDate!) 
                    : 'Fecha'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: selectedDateRange,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDateRange = picked;
                      selectedDate = null;
                    });
                  }
                },
                icon: const Icon(Icons.date_range),
                label: const Text('Rango'),
              ),
              const SizedBox(width: 8),
              if (selectedDate != null || selectedDateRange != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedDate = null;
                      selectedDateRange = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Todas', label: Text('Todas')),
              ButtonSegment(value: 'Préstamo', label: Text('Préstamos')),
              ButtonSegment(value: 'Pago', label: Text('Pagos')),
            ],
            selected: {selectedFilter},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                selectedFilter = newSelection.first;
                if (selectedFilter != 'Pago') {
                  loanTypeFilter = null;
                }
              });
            },
          ),
          if (selectedFilter == 'Pago')
            const SizedBox(height: 12),
          if (selectedFilter == 'Pago')
            Row(
              children: [
                const Text('Tipo: '),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<String?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('Todos')),
                      ButtonSegment(value: 'Fijo', label: Text('Fijo')),
                      ButtonSegment(value: 'Rotativo', label: Text('Rotativo')),
                    ],
                    selected: {loanTypeFilter},
                    onSelectionChanged: (Set<String?> newSelection) {
                      setState(() {
                        loanTypeFilter = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Transacción'),
        content: const Text('Esta funcionalidad se implementará próximamente.\n\nPor ahora, las transacciones se crean automáticamente al registrar préstamos y pagos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _exportTransactions(List<Transaction> transactions) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de exportación próximamente'),
      ),
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

  double _getTotalAmount(List<Transaction> transactions) {
    return transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double _getTotalWithInterest(List<Transaction> transactions) {
    double total = 0.0;
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.loan) {
        // Para préstamos, agregar 15% de interés (tasa promedio)
        total += transaction.amount * 1.15;
      } else {
        // Para pagos, usar el monto tal como está
        total += transaction.amount;
      }
    }
    return total;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}