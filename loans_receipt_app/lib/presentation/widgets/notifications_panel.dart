import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/api_service.dart';
import '../../domain/models/loan.dart';
import '../screens/loan_detail_screen.dart';

class NotificationsPanel extends StatefulWidget {
  final VoidCallback? onClose;
  
  const NotificationsPanel({super.key, this.onClose});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
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
        overdueLoans = loans;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        overdueLoans = [];
        isLoading = false;
      });
    }
  }
  


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Notificaciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: isLoading
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
                              'Sin notificaciones',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Todos los préstamos están al día',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.grey,
                              ),
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
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.warning,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Préstamo #${loan.id}',
                                          style: AppTextStyles.h3.copyWith(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Monto: ${NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO').format(loan.amount)}',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Cuotas: ${loan.paidInstallments}/${loan.installments}',
                                    style: AppTextStyles.caption,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Inicio: ${DateFormat('dd/MM/yyyy').format(loan.startDate)}',
                                    style: AppTextStyles.caption,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'VENCIDO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          try {
                                            // Obtener los datos completos del préstamo
                                            final loanData = await ApiService.getLoanByIdAsModel(loan.id);
                                            // Obtener los datos del usuario
                                            final users = await ApiService.getUsers();
                                            final user = users.firstWhere(
                                              (u) => u.id == loanData.userId,
                                              orElse: () => throw Exception('Usuario no encontrado'),
                                            );
                                            
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LoanDetailScreen(
                                                  loan: loanData,
                                                  user: user,
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error al cargar préstamo: $e'),
                                                backgroundColor: AppColors.error,
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Pagar',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}