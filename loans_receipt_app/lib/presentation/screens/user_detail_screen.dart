import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/dummy_data.dart';
import '../../domain/models/user.dart';
import '../molecules/loan_card.dart';
import '../widgets/app_drawer.dart';
import 'loan_detail_screen.dart';

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final userLoans = DummyData.getLoansByUserId(user.id);
    final totalLent = userLoans.fold<double>(0, (sum, loan) => sum + loan.amount);
    final totalProfit = userLoans.fold<double>(0, (sum, loan) => sum + loan.profit);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
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
                  const Text('Información del Usuario', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  _buildInfoRow('Teléfono', user.phone),
                  _buildInfoRow('Email', user.email),
                  _buildInfoRow('Registro', DateFormat('dd/MM/yyyy').format(user.registrationDate)),
                  _buildInfoRow('Total Prestado', NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO').format(totalLent)),
                  _buildInfoRow('Ganancia Total', NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO').format(totalProfit)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Préstamos (${userLoans.length})', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          ...userLoans.map((loan) => LoanCard(
                loan: loan,
                user: user,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoanDetailScreen(loan: loan, user: user),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySecondary),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
