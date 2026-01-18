import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/api_service.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/loan_status.dart';
import '../widgets/app_drawer.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedPeriod = 'Diario';
  List<Loan> loans = [];
  List<dynamic> transactions = [];
  List<dynamic> expenses = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final loansData = await ApiService.getAllLoansAsModels();
      final transactionsData = await ApiService.getAllTransactions();
      final expensesData = await ApiService.getAllExpenses();
      setState(() {
        loans = loansData;
        transactions = transactionsData;
        expenses = expensesData.map((e) => e.toJson()).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        loans = [];
        transactions = [];
        expenses = [];
        isLoading = false;
      });
    }
  }
  
  List<Loan> _getDummyLoans() {
    return [
      Loan(
        id: '1',
        userId: '1',
        amount: 5000000.0,
        interestRate: 15.0,
        installments: 12,
        paidInstallments: 5,
        startDate: DateTime(2024, 1, 15),
        status: LoanStatus.active,
        remainingAmount: 2500000.0,
      ),
      Loan(
        id: '2',
        userId: '2',
        amount: 10000000.0,
        interestRate: 12.0,
        installments: 24,
        paidInstallments: 10,
        startDate: DateTime(2024, 1, 20),
        status: LoanStatus.active,
        remainingAmount: 6000000.0,
      ),
      Loan(
        id: '3',
        userId: '1',
        amount: 7500000.0,
        interestRate: 14.0,
        installments: 18,
        paidInstallments: 8,
        startDate: DateTime(2024, 2, 1),
        status: LoanStatus.active,
        remainingAmount: 4000000.0,
      ),
    ];
  }
  
  List<dynamic> _getDummyTransactions() {
    return [
      {
        'id': 1,
        'amount': 520833.33,
        'interestAmount': 62500.00,
        'principalAmount': 458333.33,
        'date': '2024-02-15T10:00:00',
        'loan': {'id': 1}
      },
      {
        'id': 2,
        'amount': 520833.33,
        'interestAmount': 60729.17,
        'principalAmount': 460104.16,
        'date': '2024-03-15T10:00:00',
        'loan': {'id': 1}
      },
      {
        'id': 3,
        'amount': 520833.33,
        'interestAmount': 100000.00,
        'principalAmount': 420833.33,
        'date': '2024-02-20T14:00:00',
        'loan': {'id': 2}
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Análisis'),
        ),
        drawer: const AppDrawer(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis'),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFinancialSummaryModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.analytics, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Ganancias por Período', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Diario', label: Text('Diario')),
              ButtonSegment(value: '15 Días', label: Text('15 Días')),
              ButtonSegment(value: 'Mensual', label: Text('Mensual')),
            ],
            selected: {selectedPeriod},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                selectedPeriod = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ganancias - $selectedPeriod', style: AppTextStyles.h3),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: _buildChart(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildLoansSummary(),
          const SizedBox(height: 16),
          _buildTransactionsSummary(),
        ],
      ),
    );
  }
  
  DateTime? startDate = DateTime.now();
  DateTime? endDate = DateTime.now();
  bool showAhorrosDetails = false;
  
  void _showFinancialSummaryModal() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Resumen Financiero'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setModalState(() {
                              startDate = date;
                            });
                          }
                        },
                        child: Text(startDate != null 
                            ? 'Desde: ${DateFormat('dd/MM/yyyy').format(startDate!)}'
                            : 'Fecha Inicio'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setModalState(() {
                              endDate = date;
                            });
                          }
                        },
                        child: Text(endDate != null 
                            ? 'Hasta: ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                            : 'Fecha Fin'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModalSummaryItem(
                  'Total Ingresos (Capital + Intereses)',
                  '\$${NumberFormat('#,##0', 'es_CO').format(_calculateTotalIngresosByDate())}',
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildModalSummaryItem(
                  'Entradas',
                  '\$${NumberFormat('#,##0', 'es_CO').format(_calculateEntradasByDate())}',
                  Icons.trending_up,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildModalSummaryItem(
                  'Salidas',
                  '\$${NumberFormat('#,##0', 'es_CO').format(_calculateSalidasByDate())}',
                  Icons.trending_down,
                  Colors.red,
                ),
                const SizedBox(height: 16),
                _buildModalSummaryItem(
                  'Gastos',
                  '\$${NumberFormat('#,##0', 'es_CO').format(_calculateGastosByDate())}',
                  Icons.receipt,
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    setModalState(() {
                      showAhorrosDetails = !showAhorrosDetails;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.savings, color: Colors.purple, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cartera Ahorros', style: AppTextStyles.h3.copyWith(color: Colors.purple)),
                              Text('\$${NumberFormat('#,##0', 'es_CO').format(_calculateAhorrosByDate())}', 
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Icon(
                          showAhorrosDetails ? Icons.expand_less : Icons.expand_more,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
                if (showAhorrosDetails) ..._buildAhorrosDetails(setModalState),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildAhorrosDetails(StateSetter setModalState) {
    final ahorrosLoans = loans.where((loan) => loan.loanType == 'Ahorro').toList();
    if (startDate != null && endDate != null) {
      ahorrosLoans.retainWhere((loan) => 
        loan.startDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
        loan.startDate.isBefore(endDate!.add(const Duration(days: 1))));
    }
    
    final totalAhorros = ahorrosLoans.fold<double>(0, (sum, loan) => sum + loan.amount);
    final ahorrosTransactions = transactions.where((t) {
      final loanId = t['loan']?['id']?.toString();
      return ahorrosLoans.any((loan) => loan.id == loanId);
    }).toList();
    
    final totalInteresAhorros = ahorrosTransactions.fold<double>(0, (sum, t) {
      final interestAmount = t['interestAmount'] ?? 0.0;
      return sum + (interestAmount as num).toDouble();
    });
    
    final totalCapitalAhorros = ahorrosTransactions.fold<double>(0, (sum, t) {
      final principalAmount = t['principalAmount'] ?? 0.0;
      return sum + (principalAmount as num).toDouble();
    });
    
    return [
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Column(
          children: [
            _buildAhorrosDetailItem('Préstamos Otorgados', totalAhorros, Icons.arrow_upward, Colors.red),
            const SizedBox(height: 8),
            _buildAhorrosDetailItem('Capital Recuperado', totalCapitalAhorros, Icons.account_balance, Colors.blue),
            const SizedBox(height: 8),
            _buildAhorrosDetailItem('Intereses Cobrados', totalInteresAhorros, Icons.trending_up, Colors.green),
          ],
        ),
      ),
    ];
  }
  
  Widget _buildAhorrosDetailItem(String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption.copyWith(color: color)),
                Text('\$${NumberFormat('#,##0', 'es_CO').format(value)}', 
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModalSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3.copyWith(color: color)),
                Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  double _calculateTotalIngresosByDate() {
    // Excluir transacciones de préstamos tipo 'Ahorro'
    final ahorrosLoanIds = loans.where((loan) => loan.loanType == 'Ahorro').map((loan) => loan.id).toSet();
    
    if (startDate == null || endDate == null) {
      return transactions.where((transaction) {
        final loanId = transaction['loan']?['id']?.toString();
        return !ahorrosLoanIds.contains(loanId);
      }).fold<double>(0, (sum, transaction) {
        final amount = transaction['amount'] ?? 0.0;
        return sum + (amount as num).toDouble();
      });
    }
    
    return transactions.where((transaction) {
      final loanId = transaction['loan']?['id']?.toString();
      if (ahorrosLoanIds.contains(loanId)) return false;
      
      final transactionDate = DateTime.parse(transaction['date']);
      return transactionDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
             transactionDate.isBefore(endDate!.add(const Duration(days: 1)));
    }).fold<double>(0, (sum, transaction) {
      final amount = transaction['amount'] ?? 0.0;
      return sum + (amount as num).toDouble();
    });
  }
  
  double _calculateEntradasByDate() {
    // Excluir transacciones de préstamos tipo 'Ahorro'
    final ahorrosLoanIds = loans.where((loan) => loan.loanType == 'Ahorro').map((loan) => loan.id).toSet();
    
    if (startDate == null || endDate == null) {
      return transactions.where((transaction) {
        final loanId = transaction['loan']?['id']?.toString();
        return !ahorrosLoanIds.contains(loanId);
      }).fold<double>(0, (sum, transaction) {
        final interestAmount = transaction['interestAmount'] ?? 0.0;
        return sum + (interestAmount as num).toDouble();
      });
    }
    
    return transactions.where((transaction) {
      final loanId = transaction['loan']?['id']?.toString();
      if (ahorrosLoanIds.contains(loanId)) return false;
      
      final transactionDate = DateTime.parse(transaction['date']);
      return transactionDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
             transactionDate.isBefore(endDate!.add(const Duration(days: 1)));
    }).fold<double>(0, (sum, transaction) {
      final interestAmount = transaction['interestAmount'] ?? 0.0;
      return sum + (interestAmount as num).toDouble();
    });
  }
  
  double _calculateAhorrosByDate() {
    final ahorrosLoans = loans.where((loan) => loan.loanType == 'Ahorro');
    
    if (startDate == null || endDate == null) {
      return ahorrosLoans.fold<double>(0, (sum, loan) => sum + loan.amount);
    }
    
    return ahorrosLoans.where((loan) {
      return loan.startDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
             loan.startDate.isBefore(endDate!.add(const Duration(days: 1)));
    }).fold<double>(0, (sum, loan) => sum + loan.amount);
  }
  
  double _calculateSalidasByDate() {
    if (startDate == null || endDate == null) {
      return _calculateSalidas();
    }
    
    return loans.where((loan) {
      return loan.startDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
             loan.startDate.isBefore(endDate!.add(const Duration(days: 1)));
    }).fold<double>(0, (sum, loan) => sum + loan.amount);
  }
  
  double _calculateSalidas() {
    return loans.fold<double>(0, (sum, loan) => sum + loan.amount);
  }
  
  double _calculateGastosByDate() {
    if (startDate == null || endDate == null) {
      return _calculateGastos();
    }
    
    // Ajustar las fechas para incluir todo el día
    final startOfDay = DateTime(startDate!.year, startDate!.month, startDate!.day, 0, 0, 0);
    final endOfDay = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59, 999);
    
    return expenses.where((expense) {
      final expenseDate = DateTime.parse(expense['expenseDate']);
      return expenseDate.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
             expenseDate.isBefore(endOfDay.add(const Duration(milliseconds: 1)));
    }).fold<double>(0, (sum, expense) {
      final amount = expense['amount'] ?? 0.0;
      return sum + (amount as num).toDouble();
    });
  }
  
  double _calculateGastos() {
    return expenses.fold<double>(0, (sum, expense) {
      final amount = expense['amount'] ?? 0.0;
      return sum + (amount as num).toDouble();
    });
  }

  Widget _buildChart() {
    final data = _getChartData();
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.deepOrange,
    ];
    
    return PieChart(
      PieChartData(
        sections: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return PieChartSectionData(
            value: item.value,
            title: '${item.label}\n\$${(item.value / 1000000).toStringAsFixed(1)}M',
            color: colors[index % colors.length],
            radius: 100,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  List<ChartData> _getChartData() {
    final totalInterest = _getTotalInterestFromTransactions();
    
    switch (selectedPeriod) {
      case 'Diario':
        return _getDailyData(totalInterest);
      case '15 Días':
        return _getBiweeklyData(totalInterest);
      case 'Mensual':
        return _getMonthlyData(totalInterest);
      default:
        return [];
    }
  }
  
  double _getTotalInterestFromTransactions() {
    return transactions.fold<double>(0, (sum, transaction) {
      final interestAmount = transaction['interestAmount'] ?? 0.0;
      return sum + (interestAmount as num).toDouble();
    });
  }
  
  List<ChartData> _getDailyData(double totalInterest) {
    final data = <ChartData>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayName = DateFormat('EEE').format(date);
      final dayInterest = _getInterestForDate(date);
      data.add(ChartData(dayName, dayInterest));
    }
    
    return data;
  }
  
  List<ChartData> _getBiweeklyData(double totalInterest) {
    final now = DateTime.now();
    final data = <ChartData>[];
    
    for (int period = 1; period <= 3; period++) {
      final startDay = (period - 1) * 5 + 1;
      final endDay = period * 5;
      final periodInterest = _getInterestForPeriod(startDay, endDay);
      data.add(ChartData('$startDay-$endDay', periodInterest));
    }
    
    return data;
  }
  
  List<ChartData> _getMonthlyData(double totalInterest) {
    final now = DateTime.now();
    final data = <ChartData>[];
    
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthName = DateFormat('MMM').format(month);
      final monthInterest = _getInterestForMonth(month);
      data.add(ChartData(monthName, monthInterest));
    }
    
    return data;
  }
  
  double _getInterestForDate(DateTime date) {
    return transactions.where((transaction) {
      final transactionDate = DateTime.parse(transaction['date']);
      return transactionDate.year == date.year &&
             transactionDate.month == date.month &&
             transactionDate.day == date.day;
    }).fold<double>(0, (sum, transaction) {
      final interestAmount = transaction['interestAmount'] ?? 0.0;
      return sum + (interestAmount as num).toDouble();
    });
  }
  
  double _getInterestForMonth(DateTime month) {
    return transactions.where((transaction) {
      final transactionDate = DateTime.parse(transaction['date']);
      return transactionDate.year == month.year &&
             transactionDate.month == month.month;
    }).fold<double>(0, (sum, transaction) {
      final interestAmount = transaction['interestAmount'] ?? 0.0;
      return sum + (interestAmount as num).toDouble();
    });
  }
  
  double _getInterestForPeriod(int startDay, int endDay) {
    final now = DateTime.now();
    return transactions.where((transaction) {
      final transactionDate = DateTime.parse(transaction['date']);
      return transactionDate.year == now.year &&
             transactionDate.month == now.month &&
             transactionDate.day >= startDay &&
             transactionDate.day <= endDay;
    }).fold<double>(0, (sum, transaction) {
      final interestAmount = transaction['interestAmount'] ?? 0.0;
      return sum + (interestAmount as num).toDouble();
    });
  }

  Widget _buildSummaryCard() {
    final data = _getChartData();
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    final average = total / data.length;
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Total',
                  value: currencyFormat.format(total),
                  icon: Icons.attach_money,
                  color: AppColors.primary,
                ),
                _SummaryItem(
                  label: 'Promedio',
                  value: currencyFormat.format(average),
                  icon: Icons.trending_up,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoansSummary() {
    final activeLoans = loans.where((loan) => loan.status == LoanStatus.active).length;
    final overdueLoans = loans.where((loan) => loan.status == LoanStatus.overdue).length;
    final completedLoans = loans.where((loan) => loan.status == LoanStatus.completed).length;
    final totalLent = loans.fold<double>(0, (sum, loan) => sum + loan.amount);
    final totalProfit = _getTotalInterestFromTransactions();
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de Préstamos', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Activos',
                  value: activeLoans.toString(),
                  icon: Icons.trending_up,
                  color: AppColors.success,
                ),
                _SummaryItem(
                  label: 'Vencidos',
                  value: overdueLoans.toString(),
                  icon: Icons.warning,
                  color: AppColors.error,
                ),
                _SummaryItem(
                  label: 'Completados',
                  value: completedLoans.toString(),
                  icon: Icons.check_circle,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Total Prestado',
                  value: currencyFormat.format(totalLent),
                  icon: Icons.account_balance,
                  color: AppColors.secondary,
                ),
                _SummaryItem(
                  label: 'Ganancia Esperada',
                  value: currencyFormat.format(totalProfit),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionsSummary() {
    final totalTransactions = transactions.length;
    final totalInterest = _getTotalInterestFromTransactions();
    final totalPrincipal = transactions.fold<double>(0, (sum, transaction) {
      final principalAmount = transaction['principalAmount'] ?? 0.0;
      return sum + (principalAmount as num).toDouble();
    });
    final totalAmount = transactions.fold<double>(0, (sum, transaction) {
      final amount = transaction['amount'] ?? 0.0;
      return sum + (amount as num).toDouble();
    });
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de Transacciones', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Total Pagos',
                  value: totalTransactions.toString(),
                  icon: Icons.payment,
                  color: AppColors.primary,
                ),
                _SummaryItem(
                  label: 'Intereses Cobrados',
                  value: currencyFormat.format(totalInterest),
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Capital Recuperado',
                  value: currencyFormat.format(totalPrincipal),
                  icon: Icons.account_balance_wallet,
                  color: AppColors.secondary,
                ),
                _SummaryItem(
                  label: 'Total Recaudado',
                  value: currencyFormat.format(totalAmount),
                  icon: Icons.attach_money,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String label;
  final double value;
  ChartData(this.label, this.value);
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
