import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/dummy_data.dart';
import '../widgets/app_drawer.dart';
import 'new_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String selectedPeriod = 'Día';

  List<dynamic> get filteredExpenses {
    final expenses = DummyData.expenses;
    final now = DateTime.now();

    switch (selectedPeriod) {
      case 'Día':
        return expenses.where((e) => 
          e.date.year == now.year && 
          e.date.month == now.month && 
          e.date.day == now.day
        ).toList();
      case 'Mes':
        return expenses.where((e) => 
          e.date.year == now.year && 
          e.date.month == now.month
        ).toList();
      default:
        return expenses;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = filteredExpenses;
    final totalExpenses = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');

    final expensesByCategory = <String, double>{};
    for (var expense in expenses) {
      expensesByCategory[expense.category] = (expensesByCategory[expense.category] ?? 0) + expense.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Diarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Día', label: Text('Día')),
              ButtonSegment(value: 'Mes', label: Text('Mes')),
            ],
            selected: {selectedPeriod},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                selectedPeriod = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resumen de Gastos', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Gastado:', style: AppTextStyles.body),
                      Text(
                        currencyFormat.format(totalExpenses),
                        style: AppTextStyles.h2.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (expensesByCategory.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gráfica de Gastos - $selectedPeriod', style: AppTextStyles.h3),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: expensesByCategory.entries.map((entry) {
                            return PieChartSectionData(
                              value: entry.value,
                              title: '${((entry.value / totalExpenses) * 100).toStringAsFixed(0)}%',
                              color: _getCategoryColor(entry.key),
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text('Por Categoría', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ...expensesByCategory.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(entry.key).withOpacity(0.1),
                  child: Icon(_getCategoryIcon(entry.key), color: _getCategoryColor(entry.key)),
                ),
                title: Text(entry.key),
                trailing: Text(
                  currencyFormat.format(entry.value),
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('Gastos Recientes', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ...expenses.map((expense) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(expense.category).withOpacity(0.1),
                  child: Icon(_getCategoryIcon(expense.category), color: _getCategoryColor(expense.category)),
                ),
                title: Text(expense.description),
                subtitle: Text('${expense.category} • ${DateFormat('dd/MM/yyyy').format(expense.date)}'),
                trailing: Text(
                  currencyFormat.format(expense.amount),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Gasto'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Comida':
        return Icons.restaurant;
      case 'Ropa':
        return Icons.shopping_bag;
      case 'Transporte':
        return Icons.directions_car;
      case 'Entretenimiento':
        return Icons.movie;
      case 'Salud':
        return Icons.medical_services;
      default:
        return Icons.attach_money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Comida':
        return Colors.orange;
      case 'Ropa':
        return Colors.purple;
      case 'Transporte':
        return Colors.blue;
      case 'Entretenimiento':
        return Colors.pink;
      case 'Salud':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }
}
