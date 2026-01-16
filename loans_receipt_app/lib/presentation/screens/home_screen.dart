import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/api_service.dart';
import '../../domain/models/user.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/loan_status.dart';
import '../organisms/stats_overview.dart';
import '../widgets/app_drawer.dart';
import '../widgets/loan_detail_modal.dart';
import '../widgets/notifications_panel.dart';
import '../screens/expenses_screen.dart';
import 'new_loan_screen.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Loan> activeLoans = [];
  double totalLent = 0.0;
  double totalProfit = 0.0;
  double totalRemaining = 0.0;
  bool isLoading = true;
  bool showNotificationsPanel = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final response = await ApiService.getAllLoansAsModels();
      final remainingAmount = await ApiService.getTotalRemainingAmount();
      
      setState(() {
        activeLoans = response;
        totalLent = activeLoans.fold<double>(0, (sum, loan) => sum + loan.amount);
        totalProfit = activeLoans.fold<double>(0, (sum, loan) => sum + loan.profit);
        totalRemaining = remainingAmount;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    }
  }
  


  String _getStatusText(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return 'ACTIVO';
      case LoanStatus.completed:
        return 'COMPLETADO';
      case LoanStatus.overdue:
        return 'VENCIDO';
    }
  }

  Color _getStatusColor(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return AppColors.success;
      case LoanStatus.completed:
        return AppColors.primary;
      case LoanStatus.overdue:
        return AppColors.error;
    }
  }

  Widget _buildQuickAccessCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAllLoansModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
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
                    const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Todos los Préstamos Activos',
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
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeLoans.length,
                  itemBuilder: (context, index) {
                    final loan = activeLoans[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            final users = await ApiService.getUsers();
                            final user = users.firstWhere(
                              (u) => u.id == loan.userId,
                              orElse: () => User(
                                id: '0',
                                name: 'Usuario Desconocido',
                                userCode: 'N/A',
                                phone: 'N/A',
                                direccion: 'N/A',
                                registrationDate: DateTime.now(),
                              ),
                            );
                            if (mounted) {
                              final loanMap = {
                                'id': loan.id,
                                'amount': loan.amount,
                                'interestRate': loan.interestRate,
                                'installments': loan.installments,
                                'paidInstallments': loan.paidInstallments,
                                'startDate': loan.startDate.toIso8601String(),
                                'status': loan.status.name.toUpperCase(),
                                'totalAmount': loan.totalAmount,
                                'installmentAmount': loan.installmentAmount,
                                'remainingAmount': loan.remainingAmount,
                              };
                              LoanDetailModal.show(context, loanMap, user);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error al cargar detalles del préstamo')),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Préstamo #${loan.id}', style: AppTextStyles.h3),
                                  const SizedBox(height: 4),
                                  Text(NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO').format(loan.amount), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(loan.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(loan.status),
                                      style: TextStyle(color: _getStatusColor(loan.status), fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
        ),
      ),
    );
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
            onPressed: () {
              setState(() {
                showNotificationsPanel = !showNotificationsPanel;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StatsOverview(
                totalLent: totalLent,
                totalProfit: totalProfit,
                totalRemaining: totalRemaining,
                activeLoans: activeLoans.length,
              ),
              const SizedBox(height: 24),
              // Iconos de acceso rápido
              FutureBuilder<bool>(
                future: AuthService.hasPermission('view_transactions'),
                builder: (context, snapshot) {
                  final hasTransactionPermission = snapshot.data ?? false;
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mostrar Transacciones para ADMIN, Gastos Diarios para VIEWER
                      hasTransactionPermission
                          ? _buildQuickAccessCard(
                              'Transacciones',
                              Icons.receipt_long,
                              AppColors.primary,
                              () => Navigator.pushNamed(context, '/transactions'),
                            )
                          : _buildQuickAccessCard(
                              'Gastos\nDiarios',
                              Icons.receipt,
                              AppColors.error,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                              ),
                            ),
                      _buildQuickAccessCard(
                        'Usuarios',
                        Icons.people,
                        AppColors.secondary,
                        () => Navigator.pushNamed(context, '/users'),
                      ),
                      // Solo mostrar "Pagos Sin Registrar" para ADMIN
                      FutureBuilder<bool>(
                        future: AuthService.hasPermission('view_payments'),
                        builder: (context, paymentSnapshot) {
                          final hasPaymentPermission = paymentSnapshot.data ?? false;
                          
                          return hasPaymentPermission
                              ? _buildQuickAccessCard(
                                  'Pagos Sin\nRegistrar',
                                  Icons.payment,
                                  AppColors.warning,
                                  () => Navigator.pushNamed(context, '/unregistered-payments'),
                                )
                              : _buildQuickAccessCard(
                                  'Préstamos',
                                  Icons.account_balance_wallet,
                                  AppColors.success,
                                  () => _showAllLoansModal(),
                                );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Préstamos Activos', style: AppTextStyles.h2),
                  if (activeLoans.length > 5)
                    TextButton(
                      onPressed: _showAllLoansModal,
                      child: const Text('Ver todos'),
                    ),
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
                ...activeLoans.take(5).map((loan) => FutureBuilder<List<User>>(
                  future: ApiService.getUsers(),
                  builder: (context, snapshot) {
                    final users = snapshot.data ?? [];
                    final user = users.isNotEmpty
                        ? users.firstWhere(
                            (u) => u.id == loan.userId,
                            orElse: () => User(
                              id: '0',
                              name: 'Usuario Desconocido',
                              userCode: 'N/A',
                              phone: 'N/A',
                              direccion: 'N/A',
                              registrationDate: DateTime.now(),
                            ),
                          )
                        : User(
                            id: '0',
                            name: 'Cargando...',
                            userCode: '...',
                            phone: 'N/A',
                            direccion: 'N/A',
                            registrationDate: DateTime.now(),
                          );
                    
                    return Card(
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
                                direccion: 'N/A',
                                registrationDate: DateTime.now(),
                              ),
                            );
                            if (mounted) {
                              final loanMap = {
                                'id': loan.id,
                                'amount': loan.amount,
                                'interestRate': loan.interestRate,
                                'installments': loan.installments,
                                'paidInstallments': loan.paidInstallments,
                                'startDate': loan.startDate.toIso8601String(),
                                'status': loan.status.name.toUpperCase(),
                                'totalAmount': loan.totalAmount,
                                'installmentAmount': loan.installmentAmount,
                                'remainingAmount': loan.remainingAmount,
                              };
                              LoanDetailModal.show(context, loanMap, user);
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
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Préstamo #${loan.id}', style: AppTextStyles.h3),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            user.userCode,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.name,
                                      style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO').format(loan.amount),
                                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(loan.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(loan.status),
                                      style: TextStyle(color: _getStatusColor(loan.status), fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )),
            ],
          ),
          if (showNotificationsPanel)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: NotificationsPanel(
                onClose: () {
                  setState(() {
                    showNotificationsPanel = false;
                  });
                },
              ),
            ),
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