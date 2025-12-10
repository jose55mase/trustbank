import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/dummy_data.dart';
import '../widgets/app_drawer.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedPeriod = 'Diario';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Ganancias'),
      ),
      drawer: const AppDrawer(),
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
        ],
      ),
    );
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
    final totalProfit = DummyData.loans.fold<double>(0, (sum, loan) => sum + loan.profit);
    
    switch (selectedPeriod) {
      case 'Diario':
        return [
          ChartData('Lun', totalProfit * 0.12),
          ChartData('Mar', totalProfit * 0.15),
          ChartData('Mié', totalProfit * 0.18),
          ChartData('Jue', totalProfit * 0.14),
          ChartData('Vie', totalProfit * 0.20),
          ChartData('Sáb', totalProfit * 0.11),
          ChartData('Dom', totalProfit * 0.10),
        ];
      case '15 Días':
        return [
          ChartData('1-5', totalProfit * 0.35),
          ChartData('6-10', totalProfit * 0.40),
          ChartData('11-15', totalProfit * 0.25),
        ];
      case 'Mensual':
        return [
          ChartData('Ene', totalProfit * 0.08),
          ChartData('Feb', totalProfit * 0.09),
          ChartData('Mar', totalProfit * 0.11),
          ChartData('Abr', totalProfit * 0.10),
          ChartData('May', totalProfit * 0.12),
          ChartData('Jun', totalProfit * 0.09),
          ChartData('Jul', totalProfit * 0.08),
          ChartData('Ago', totalProfit * 0.10),
          ChartData('Sep', totalProfit * 0.09),
          ChartData('Oct', totalProfit * 0.07),
          ChartData('Nov', totalProfit * 0.04),
          ChartData('Dic', totalProfit * 0.03),
        ];
      default:
        return [];
    }
  }

  Widget _buildSummaryCard() {
    final data = _getChartData();
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    final average = total / data.length;
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');

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
