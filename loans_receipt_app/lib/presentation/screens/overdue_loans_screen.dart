import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/api_service.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/loan_status.dart';
import '../../domain/models/user.dart';
import '../widgets/loan_detail_modal.dart';

class OverdueLoansScreen extends StatefulWidget {
  const OverdueLoansScreen({super.key});

  @override
  State<OverdueLoansScreen> createState() => _OverdueLoansScreenState();
}

class _OverdueLoansScreenState extends State<OverdueLoansScreen> {
  List<Loan> overdueLoans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOverdueLoans();
  }

  Future<void> _loadOverdueLoans() async {
    try {
      final loans = await ApiService.getOverdueLoans();
      setState(() {
        // Si el servicio devuelve array vacío, usar datos dummy
        overdueLoans = loans.isEmpty ? _getDummyOverdueLoans() : loans;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        overdueLoans = _getDummyOverdueLoans();
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar préstamos vencidos: $e')),
        );
      }
    }
  }
  
  List<Loan> _getDummyOverdueLoans() {
    return [
      Loan(
        id: '4',
        userId: '3',
        amount: 3000000.0,
        interestRate: 18.0,
        installments: 12,
        paidInstallments: 2,
        startDate: DateTime(2023, 10, 15),
        status: LoanStatus.overdue,
        remainingAmount: 2500000.0,
      ),
      Loan(
        id: '5',
        userId: '4',
        amount: 8000000.0,
        interestRate: 16.0,
        installments: 24,
        paidInstallments: 4,
        startDate: DateTime(2023, 11, 20),
        status: LoanStatus.overdue,
        remainingAmount: 6500000.0,
      ),
      Loan(
        id: '6',
        userId: '5',
        amount: 4500000.0,
        interestRate: 20.0,
        installments: 18,
        paidInstallments: 3,
        startDate: DateTime(2023, 12, 1),
        status: LoanStatus.overdue,
        remainingAmount: 3800000.0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préstamos Vencidos'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : overdueLoans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay préstamos vencidos',
                        style: AppTextStyles.h2.copyWith(color: AppColors.success),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Todos los préstamos están al día',
                        style: AppTextStyles.body.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: overdueLoans.length,
                  itemBuilder: (context, index) {
                    final loan = overdueLoans[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.error.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
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
                              // Convertir Loan a Map para el modal
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
                                const SnackBar(
                                  content: Text('Error al cargar detalles'),
                                ),
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Préstamo #${loan.id}',
                                          style: AppTextStyles.h3.copyWith(
                                            color: AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          NumberFormat.currency(
                                            symbol: '\$ ',
                                            decimalDigits: 0,
                                            locale: 'es_CO',
                                          ).format(loan.amount),
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'VENCIDO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Inicio: ${DateFormat('dd/MM/yyyy').format(loan.startDate)}',
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.payment,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cuotas: ${loan.paidInstallments}/${loan.installments}',
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Tasa: ${loan.interestRate}%',
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 13,
                                      color: Colors.grey[600],
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
    );
  }
}