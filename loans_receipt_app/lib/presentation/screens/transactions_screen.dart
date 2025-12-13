import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/transaction.dart';
import '../../data/services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/loan_id_row.dart';

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
  List<dynamic> _transactions = [];
  List<dynamic> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> transactions;
      if (selectedDateRange != null) {
        transactions = await ApiService.getTransactionsByDateRange(
          startDate: selectedDateRange!.start,
          endDate: selectedDateRange!.end,
        );
      } else {
        transactions = await ApiService.getAllTransactions();
      }
      
      // Cargar préstamos también
      final loans = await ApiService.getAllLoans();
      
      setState(() {
        _transactions = transactions;
        _loans = loans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  List<dynamic> get filteredTransactions {
    if (selectedFilter == 'Préstamo') {
      return _loans; // Mostrar préstamos del API
    }
    
    var filtered = _transactions;
    
    // Filtrar por tipo de transacción
    if (selectedFilter == 'Pago') {
      filtered = filtered.where((t) => t['type'] == 'PAYMENT').toList();
    }
    
    // Filtrar por tipo de préstamo si está seleccionado
    if (loanTypeFilter != null) {
      filtered = filtered.where((t) {
        final loan = t['loan'];
        if (loan == null) return false;
        final loanType = loan['loanType']?.toString();
        return (loanTypeFilter == 'Fijo' && loanType == 'FIXED') ||
               (loanTypeFilter == 'Rotativo' && loanType == 'REVOLVING');
      }).toList();
    }
    
    return filtered;
  }
  
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      _loadTransactions();
    }
  }
  
  void _clearDateFilter() {
    setState(() {
      selectedDate = null;
      selectedDateRange = null;
    });
    _loadTransactions();
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
                    _loadTransactions();
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(selectedDate != null 
                    ? DateFormat('dd/MM/yyyy').format(selectedDate!) 
                    : 'Fecha'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  selectedDateRange != null
                      ? '${DateFormat('dd/MM').format(selectedDateRange!.start)}-${DateFormat('dd/MM').format(selectedDateRange!.end)}'
                      : 'Rango',
                ),
              ),
              const SizedBox(width: 8),
              if (selectedDate != null || selectedDateRange != null)
                IconButton(
                  onPressed: _clearDateFilter,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpiar filtro de fecha',
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
                if (selectedFilter == 'Préstamo') {
                  loanTypeFilter = null;
                }
              });
            },
          ),
          if (selectedFilter == 'Todas' || selectedFilter == 'Pago') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Tipo de préstamo: '),
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
        ],
      ),
    );
  }
  
  void _exportTransactions(List<dynamic> transactions) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de exportación pendiente')),
    );
  }

  double get totalPayments {
    return filteredTransactions
        .where((t) => t['type'] == 'PAYMENT')
        .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  }

  double get totalInterest {
    return filteredTransactions
        .where((t) => t['type'] == 'PAYMENT')
        .fold(0.0, (sum, t) => sum + ((t['interestAmount'] as num?)?.toDouble() ?? 0.0));
  }

  double get totalPrincipal {
    return filteredTransactions
        .where((t) => t['type'] == 'PAYMENT')
        .fold(0.0, (sum, t) => sum + ((t['principalAmount'] as num?)?.toDouble() ?? 0.0));
  }

  double get totalAllTransactions {
    return filteredTransactions
        .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'CASH':
        return 'Efectivo';
      case 'TRANSFER':
        return 'Transferencia';
      case 'CHECK':
        return 'Cheque';
      default:
        return method;
    }
  }

  String _getLoanStatusText(String? status) {
    switch (status) {
      case 'ACTIVE':
        return 'Activo';
      case 'PAID':
        return 'Pagado';
      case 'OVERDUE':
        return 'Vencido';
      case 'CANCELLED':
        return 'Cancelado';
      default:
        return status ?? 'Desconocido';
    }
  }

  void _showSummaryModal(NumberFormat currencyFormat) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Resumen Financiero',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSummaryCard(
                        'Total General',
                        currencyFormat.format(totalAllTransactions),
                        Icons.account_balance_wallet,
                        AppColors.primary,
                        'Suma de todas las transacciones filtradas',
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryCard(
                        'Total Intereses',
                        currencyFormat.format(totalInterest),
                        Icons.trending_up,
                        AppColors.success,
                        'Ganancias por intereses de pagos',
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryCard(
                        'Total Capital',
                        currencyFormat.format(totalPrincipal),
                        Icons.payments,
                        AppColors.secondary,
                        'Capital recuperado de préstamos',
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryCard(
                        'Total Pagos',
                        currencyFormat.format(totalPayments),
                        Icons.payment,
                        AppColors.warning,
                        'Solo transacciones de tipo pago',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLoanDetail(String loanId) async {
    try {
      final loan = await ApiService.getLoanById(loanId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _LoanInfoDialog(loan: loan),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar préstamo: $e')),
        );
      }
    }
  }

  void _showTransactionDetail(Map<String, dynamic> transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');
    final isPayment = transaction['type'] == 'PAYMENT';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isPayment ? AppColors.success : AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPayment ? Icons.payment : Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPayment ? 'Detalle del Pago' : 'Detalle del Préstamo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${transaction['id']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailSection(
                        title: 'Información General',
                        children: [
                          _DetailRow('Tipo', isPayment ? 'Pago' : 'Préstamo'),
                          _DetailRow('Monto', currencyFormat.format(transaction['amount'] ?? 0)),
                          _DetailRow('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaction['date']))),
                          _DetailRow('Método de Pago', _getPaymentMethodText(transaction['paymentMethod']?.toString() ?? '')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DetailSection(
                        title: 'Información del Préstamo',
                        children: [
                          LoanIdRow(
                            loanId: transaction['loan']?['id']?.toString() ?? 'N/A',
                            onTap: transaction['loan']?['id'] != null
                                ? () {
                                    Navigator.pop(context);
                                    _showLoanDetail(transaction['loan']['id'].toString());
                                  }
                                : null,
                          ),
                          if (transaction['loan']?['user'] != null) ...[
                            _DetailRow('Cliente', transaction['loan']['user']['name'] ?? 'N/A'),
                            _DetailRow('Teléfono', transaction['loan']['user']['phone'] ?? 'N/A'),
                            _DetailRow('Email', transaction['loan']['user']['email'] ?? 'N/A'),
                          ],
                          if (transaction['loan'] != null) ...[
                            _DetailRow('Monto Préstamo', currencyFormat.format(transaction['loan']['amount'] ?? 0)),
                            _DetailRow('Tasa Interés', '${transaction['loan']['interestRate'] ?? 0}%'),
                            _DetailRow('Cuotas Totales', '${transaction['loan']['installments'] ?? 0}'),
                            _DetailRow('Cuotas Pagadas', '${transaction['loan']['paidInstallments'] ?? 0}'),
                            _DetailRow('Estado', _getLoanStatusText(transaction['loan']['status']?.toString())),
                            if (transaction['loan']['startDate'] != null)
                              _DetailRow('Fecha Inicio', DateFormat('dd/MM/yyyy').format(DateTime.parse(transaction['loan']['startDate']))),
                          ],
                        ],
                      ),
                      if (isPayment && (transaction['interestAmount'] != null || transaction['principalAmount'] != null)) ...[
                        const SizedBox(height: 20),
                        _DetailSection(
                          title: 'Desglose del Pago',
                          children: [
                            if (transaction['principalAmount'] != null)
                              _DetailRow('Capital', currencyFormat.format(transaction['principalAmount'])),
                            if (transaction['interestAmount'] != null)
                              _DetailRow('Interés', currencyFormat.format(transaction['interestAmount'])),
                          ],
                        ),
                      ],
                      if (transaction['notes']?.isNotEmpty == true) ...[
                        const SizedBox(height: 20),
                        _DetailSection(
                          title: 'Notas',
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                transaction['notes'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (transaction['loan']?['id'] != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showLoanDetail(transaction['loan']['id'].toString());
                          },
                          icon: const Icon(Icons.account_balance_wallet),
                          label: Text('Ver Préstamo #${transaction['loan']['id']}'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (transaction['loan']?['id'] != null)
                      const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
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

              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
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
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          if (item == null) return const SizedBox.shrink();
                          
                          // Determinar si es préstamo o transacción
                          final isLoan = selectedFilter == 'Préstamo';
                          final isPayment = !isLoan && item['type'] == 'PAYMENT';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => isLoan ? _showLoanDetail(item['id'].toString()) : _showTransactionDetail(item),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: (isLoan ? AppColors.warning : (isPayment ? AppColors.success : AppColors.primary)).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isLoan ? Icons.account_balance_wallet : (isPayment ? Icons.arrow_downward : Icons.arrow_upward),
                                        color: isLoan ? AppColors.warning : (isPayment ? AppColors.success : AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isLoan 
                                                ? 'Cliente: ${item['user']?['name'] ?? 'N/A'}'
                                                : 'Préstamo ID: ${item['loan']?['id'] ?? 'N/A'}',
                                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isLoan 
                                                ? 'Préstamo • ${item['id']}'
                                                : '${isPayment ? 'Pago' : 'Transacción'} • ${item['id']}',
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isLoan 
                                                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(item['startDate']))
                                                : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['date'])),
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          currencyFormat.format(item['amount'] ?? 0),
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isLoan ? AppColors.warning : (isPayment ? AppColors.success : AppColors.primary),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (isLoan ? AppColors.warning : AppColors.success).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isLoan 
                                                ? _getLoanStatusText(item['status']?.toString())
                                                : _getPaymentMethodText(item['paymentMethod']?.toString() ?? ''),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isLoan ? AppColors.warning : AppColors.success,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSummaryModal(NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.analytics),
        label: const Text('Resumen'),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanInfoDialog extends StatelessWidget {
  final Map<String, dynamic> loan;

  const _LoanInfoDialog({required this.loan});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información del Préstamo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${loan['id']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (loan['user'] != null) ...[
                      _DetailSection(
                        title: 'Cliente',
                        children: [
                          _DetailRow('Nombre', loan['user']['name'] ?? 'N/A'),
                          _DetailRow('Teléfono', loan['user']['phone'] ?? 'N/A'),
                          _DetailRow('Email', loan['user']['email'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    _DetailSection(
                      title: 'Detalles del Préstamo',
                      children: [
                        _DetailRow('Monto', currencyFormat.format(loan['amount'] ?? 0)),
                        _DetailRow('Tasa de Interés', '${loan['interestRate'] ?? 0}%'),
                        _DetailRow('Cuotas Totales', '${loan['installments'] ?? 0}'),
                        _DetailRow('Cuotas Pagadas', '${loan['paidInstallments'] ?? 0}'),
                        _DetailRow('Estado', loan['status'] ?? 'N/A'),
                        if (loan['startDate'] != null)
                          _DetailRow('Fecha Inicio', DateFormat('dd/MM/yyyy').format(DateTime.parse(loan['startDate']))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}