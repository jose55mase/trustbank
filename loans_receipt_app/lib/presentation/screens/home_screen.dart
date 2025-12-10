import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/dummy_data.dart';
import '../../domain/models/loan.dart';
import '../organisms/stats_overview.dart';
import '../molecules/loan_card.dart';
import '../widgets/app_drawer.dart';
import 'loan_detail_screen.dart';
import 'new_loan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeLoans = DummyData.loans.where((l) => l.status == LoanStatus.active).toList();
    final totalLent = activeLoans.fold<double>(0, (sum, loan) => sum + loan.amount);
    final totalProfit = activeLoans.fold<double>(0, (sum, loan) => sum + loan.profit);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Préstamos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatsOverview(
            totalLent: totalLent,
            totalProfit: totalProfit,
            activeLoans: activeLoans.length,
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Préstamos Activos', style: AppTextStyles.h2),
            ],
          ),
          const SizedBox(height: 16),
          ...activeLoans.map((loan) {
            final user = DummyData.getUserById(loan.userId);
            return LoanCard(
              loan: loan,
              user: user,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoanDetailScreen(loan: loan, user: user),
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewLoanScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Préstamo', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 4,
      ),
    );
  }
}
