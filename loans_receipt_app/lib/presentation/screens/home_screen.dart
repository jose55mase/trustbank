import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/api_service.dart';
import '../../domain/models/user.dart';
import '../../domain/models/loan.dart';
import '../organisms/stats_overview.dart';
import '../widgets/app_drawer.dart';
import 'loan_detail_screen.dart';
import 'new_loan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Loan> activeLoans = [];
  double totalLent = 0.0;
  double totalProfit = 0.0;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final response = await ApiService.getAllLoansAsModels();
      setState(() {
        activeLoans = response;
        totalLent = activeLoans.fold<double>(0, (sum, loan) => sum + loan.amount);
        totalProfit = activeLoans.fold<double>(0, (sum, loan) => sum + loan.profit);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        debugPrint('Error cargando préstamos: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Préstamos'),
        ),
        drawer: const AppDrawer(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
          if (activeLoans.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay préstamos activos', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Crea un nuevo préstamo para comenzar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            )
          else
            ...activeLoans.map((loan) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () async {
                  try {
                    final users = await ApiService.getUsers();
                    final user = users.firstWhere(
                      (u) => u.id == loan.userId,
                      orElse: () => User(
                        id: '0',
                        name: 'Usuario Desconocido',
                        userCode: 'N/A',
                        phone: 'N/A',
                        email: 'N/A',
                        registrationDate: DateTime.now(),
                      ),
                    );
                    if (mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoanDetailScreen(loan: loan, user: user),
                        ),
                      );
                      if (result == true) {
                        _loadData();
                      }
                    }
                  } catch (e) {
                    debugPrint('Error cargando detalles: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al cargar detalles del préstamo')),
                      );
                    }
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
                      Text('Monto: \$${loan.amount.toStringAsFixed(0)}'),
                      Text('Tasa: ${loan.interestRate}%'),
                      Text('Cuotas: ${loan.paidInstallments}/${loan.installments}'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewLoanScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Préstamo', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 4,
      ),
    );
  }
}