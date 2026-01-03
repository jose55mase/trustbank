import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/dummy_data.dart';
import '../../domain/models/loan_status.dart';
import '../widgets/app_drawer.dart';

class LoansAnalyticsScreen extends StatefulWidget {
  const LoansAnalyticsScreen({super.key});

  @override
  State<LoansAnalyticsScreen> createState() => _LoansAnalyticsScreenState();
}

class _LoansAnalyticsScreenState extends State<LoansAnalyticsScreen> {
  String selectedView = 'Estado';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Préstamos'),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Distribución de Préstamos', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Estado', label: Text('Estado')),
              ButtonSegment(value: 'Montos', label: Text('Montos')),
              ButtonSegment(value: 'Intereses', label: Text('Intereses')),
            ],
            selected: {selectedView},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                selectedView = newSelection.first;
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
                  Text(_getChartTitle(), style: AppTextStyles.h3),
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
        ],
      ),
    );
  }

  String _getChartTitle() {
    switch (selectedView) {
      case 'Estado':
        return 'Préstamos por Estado';
      case 'Montos':
        return 'Montos Prestados por Usuario';
      case 'Intereses':
        return 'Tasas de Interés';
      default:
        return '';
    }
  }

  Widget _buildChart() {
    switch (selectedView) {
      case 'Estado':
        return _buildPieChart();
      case 'Montos':
        return _buildBarChart();
      case 'Intereses':
        return _buildInterestChart();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPieChart() {
    final active = DummyData.loans.where((l) => l.status == LoanStatus.active).length;
    final completed = DummyData.loans.where((l) => l.status == LoanStatus.completed).length;
    final overdue = DummyData.loans.where((l) => l.status == LoanStatus.overdue).length;

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: active.toDouble(),
            title: 'Activos\n$active',
            color: AppColors.primary,
            radius: 100,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            value: completed.toDouble(),
            title: 'Completados\n$completed',
            color: AppColors.secondary,
            radius: 100,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            value: overdue.toDouble(),
            title: 'Vencidos\n$overdue',
            color: Colors.red,
            radius: 100,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildBarChart() {
    final userLoans = <String, double>{};
    for (var loan in DummyData.loans) {
      final user = DummyData.getUserById(loan.userId);
      userLoans[user.name] = (userLoans[user.name] ?? 0) + loan.amount;
    }

    final sortedEntries = userLoans.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: sortedEntries.first.value * 1.2,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                  final name = sortedEntries[value.toInt()].key.split(' ')[0];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(name, style: AppTextStyles.caption),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${(value / 1000000).toStringAsFixed(0)}M',
                  style: AppTextStyles.caption,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: sortedEntries.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: AppColors.primary,
                width: 20,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInterestChart() {
    final interestGroups = <String, int>{};
    for (var loan in DummyData.loans) {
      final range = '${(loan.interestRate ~/ 5) * 5}-${((loan.interestRate ~/ 5) * 5) + 5}%';
      interestGroups[range] = (interestGroups[range] ?? 0) + 1;
    }

    final sortedEntries = interestGroups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble() + 1,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(sortedEntries[value.toInt()].key, style: AppTextStyles.caption),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: AppTextStyles.caption);
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: sortedEntries.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value.toDouble(),
                color: AppColors.secondary,
                width: 20,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalLoans = DummyData.loans.length;
    final totalAmount = DummyData.loans.fold<double>(0, (sum, loan) => sum + loan.amount);
    final totalProfit = DummyData.loans.fold<double>(0, (sum, loan) => sum + loan.profit);
    final avgInterest = DummyData.loans.fold<double>(0, (sum, loan) => sum + loan.interestRate) / totalLoans;
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen General', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SummaryItem(
                  label: 'Total Préstamos',
                  value: totalLoans.toString(),
                  icon: Icons.receipt_long,
                  color: AppColors.primary,
                ),
                _SummaryItem(
                  label: 'Monto Total',
                  value: currencyFormat.format(totalAmount),
                  icon: Icons.attach_money,
                  color: AppColors.secondary,
                ),
                _SummaryItem(
                  label: 'Ganancia Total',
                  value: currencyFormat.format(totalProfit),
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                _SummaryItem(
                  label: 'Interés Promedio',
                  value: '${avgInterest.toStringAsFixed(1)}%',
                  icon: Icons.percent,
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
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
