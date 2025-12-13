import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/api_service.dart';
import '../../domain/models/user.dart';
import '../../domain/models/loan.dart';
import '../widgets/app_drawer.dart';
import 'loan_detail_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  List<Loan> userLoans = [];
  double totalLent = 0.0;
  double totalProfit = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserLoans();
  }

  Future<void> _loadUserLoans() async {
    try {
      final allLoans = await ApiService.getAllLoansAsModels();
      final loans = allLoans.where((loan) => loan.userId == widget.user.id).toList();
      setState(() {
        userLoans = loans;
        totalLent = loans.fold<double>(0, (sum, loan) => sum + loan.amount);
        totalProfit = loans.fold<double>(0, (sum, loan) => sum + loan.profit);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.user.name),
        ),
        drawer: const AppDrawer(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
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
                  _buildInfoRow('Código', widget.user.userCode),
                  _buildInfoRow('Teléfono', widget.user.phone),
                  _buildInfoRow('Email', widget.user.email),
                  _buildInfoRow('Registro', DateFormat('dd/MM/yyyy').format(widget.user.registrationDate)),
                  _buildInfoRow('Total Prestado', NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO').format(totalLent)),
                  _buildInfoRow('Ganancia Total', NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO').format(totalProfit)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Préstamos (${userLoans.length})', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          if (userLoans.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Este usuario no tiene préstamos aún', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            )
          else
            ...userLoans.map((loan) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoanDetailScreen(loan: loan, user: widget.user),
                    ),
                  );
                  if (result == true) {
                    _loadUserLoans();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Préstamo #${loan.id}', style: AppTextStyles.h3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  loan.status.name.toUpperCase(),
                                  style: TextStyle(color: AppColors.success, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Monto: \$${NumberFormat('#,###').format(loan.amount)}'),
                      Text('Tasa de Interés: ${loan.interestRate}%'),
                      Text('Cuotas: ${loan.paidInstallments}/${loan.installments}'),
                      Text('Fecha de Inicio: ${DateFormat('dd/MM/yyyy').format(loan.startDate)}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            loan.pagoAnterior ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: loan.pagoAnterior ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pago Ant: ${loan.pagoAnterior ? "Pagado" : "Pendiente"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: loan.pagoAnterior ? AppColors.success : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            loan.pagoActual ? Icons.check_circle : Icons.schedule,
                            size: 16,
                            color: loan.pagoActual ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pago Act: ${loan.pagoActual ? "Pagado" : "Pendiente"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: loan.pagoActual ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Toca para ver detalles completos', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
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