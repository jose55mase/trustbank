import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';
import '../../../services/api_service.dart';
import '../../credits/models/credit_application.dart';
import '../../../utils/currency_formatter.dart';

class CreditsManagementScreen extends StatefulWidget {
  const CreditsManagementScreen({super.key});

  @override
  State<CreditsManagementScreen> createState() => _CreditsManagementScreenState();
}

class _CreditsManagementScreenState extends State<CreditsManagementScreen> {
  List<CreditApplication> _applications = [];
  bool _isLoading = true;
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadCreditApplications();
  }

  Future<void> _loadCreditApplications() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllCreditApplications();
      if (response['status'] == 200) {
        final applications = (response['data'] as List)
            .map((json) => CreditApplication.fromJson(json))
            .toList();
        
        setState(() {
          _applications = applications;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar solicitudes: $e')),
      );
    }
  }

  List<CreditApplication> get _filteredApplications {
    switch (_selectedFilter) {
      case 'pending':
        return _applications.where((app) => 
          app.status == CreditStatus.pending || 
          app.status == CreditStatus.underReview
        ).toList();
      case 'approved':
        return _applications.where((app) => 
          app.status == CreditStatus.approved || 
          app.status == CreditStatus.disbursed
        ).toList();
      case 'rejected':
        return _applications.where((app) => 
          app.status == CreditStatus.rejected
        ).toList();
      default:
        return _applications;
    }
  }

  Future<void> _processApplication(CreditApplication application, bool approve, {String? reason}) async {
    try {
      final response = await ApiService.processCreditApplication(
        application.id,
        approve ? 'approved' : 'rejected',
        reason,
      );

      if (response['status'] == 200) {
        // Si se aprueba, crear transacción para sumar al saldo
        if (approve) {
          await _createCreditTransaction(application);
        }

        TBDialogHelper.showSuccess(
          context,
          title: approve ? 'Crédito Aprobado' : 'Crédito Rechazado',
          message: approve 
            ? 'El crédito ha sido aprobado y el monto agregado al saldo del usuario'
            : 'El crédito ha sido rechazado',
          onPressed: () {
            Navigator.of(context).pop();
            _loadCreditApplications();
          },
        );
      }
    } catch (e) {
      TBDialogHelper.showError(
        context,
        title: 'Error',
        message: 'Error al procesar solicitud: $e',
      );
    }
  }

  Future<void> _createCreditTransaction(CreditApplication application) async {
    try {
      // Crear transacción de crédito aprobado
      await ApiService.createTransaction({
        'fromUserId': 1, // Sistema/Banco
        'toUserId': application.userId,
        'amount': application.amount,
        'type': 'INCOME',
        'description': 'Crédito ${application.creditType} aprobado',
        'category': 'CREDIT_DISBURSEMENT',
      });

      // Crear notificación de aprobación
      await ApiService.createNotification({
        'userId': application.userId,
        'title': '🎉 Crédito Aprobado',
        'message': 'Tu ${application.creditType} por ${CurrencyFormatter.format(application.amount)} ha sido aprobado y el dinero está disponible en tu cuenta.',
        'type': 'creditApproved',
        'additionalInfo': 'Monto: ${CurrencyFormatter.format(application.amount)} - Plazo: ${application.termMonths} meses',
      });
    } catch (e) {
      print('Error creating credit transaction: $e');
    }
  }

  void _showProcessDialog(CreditApplication application, bool approve) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Aprobar Crédito' : 'Rechazar Crédito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${application.creditType} - ${CurrencyFormatter.format(application.amount)}'),
            const SizedBox(height: TBSpacing.md),
            if (!approve) ...[
              Text('Motivo del rechazo:', style: TBTypography.labelMedium),
              const SizedBox(height: TBSpacing.sm),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Ingresa el motivo...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(TBSpacing.sm),
                decoration: BoxDecoration(
                  color: TBColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
                ),
                child: Text(
                  '✅ El monto será agregado automáticamente al saldo del usuario',
                  style: TBTypography.bodySmall.copyWith(color: TBColors.success),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processApplication(
                application, 
                approve, 
                reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? TBColors.success : TBColors.error,
            ),
            child: Text(approve ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
      case CreditStatus.underReview:
        return TBColors.warning;
      case CreditStatus.approved:
      case CreditStatus.disbursed:
        return TBColors.success;
      case CreditStatus.rejected:
        return TBColors.error;
    }
  }

  Widget _buildCreditCard(CreditApplication application) {
    final statusColor = _getStatusColor(application.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.md),
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.surface,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: TBColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.creditType,
                      style: TBTypography.titleMedium,
                    ),
                    Text(
                      'Usuario ID: ${application.userId}',
                      style: TBTypography.labelMedium.copyWith(color: TBColors.grey600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TBSpacing.sm,
                  vertical: TBSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
                ),
                child: Text(
                  application.statusText,
                  style: TBTypography.labelSmall.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: TBSpacing.md),
          Row(
            children: [
              _buildInfoItem('Monto', CurrencyFormatter.format(application.amount)),
              _buildInfoItem('Plazo', '${application.termMonths} meses'),
              _buildInfoItem('Tasa', '${application.interestRate}%'),
            ],
          ),
          const SizedBox(height: TBSpacing.md),
          _buildInfoItem('Cuota mensual', CurrencyFormatter.format(application.monthlyPayment)),
          const SizedBox(height: TBSpacing.md),
          _buildInfoItem('Fecha', _formatDate(application.applicationDate)),
          
          if (application.status == CreditStatus.pending || 
              application.status == CreditStatus.underReview) ...[
            const SizedBox(height: TBSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TBButton(
                    text: 'Rechazar',
                    variant: 'outline',
                    onPressed: () => _showProcessDialog(application, false),
                  ),
                ),
                const SizedBox(width: TBSpacing.sm),
                Expanded(
                  child: TBButton(
                    text: 'Aprobar',
                    onPressed: () => _showProcessDialog(application, true),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TBTypography.labelSmall.copyWith(color: TBColors.grey600),
          ),
          Text(
            value,
            style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      appBar: AppBar(
        title: Text('Gestión de Créditos', style: TBTypography.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCreditApplications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(TBSpacing.md),
            child: Row(
              children: [
                _buildFilterChip('Pendientes', 'pending'),
                const SizedBox(width: TBSpacing.sm),
                _buildFilterChip('Aprobados', 'approved'),
                const SizedBox(width: TBSpacing.sm),
                _buildFilterChip('Rechazados', 'rejected'),
                const SizedBox(width: TBSpacing.sm),
                _buildFilterChip('Todos', 'all'),
              ],
            ),
          ),
          
          // Lista de solicitudes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredApplications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.credit_card_off,
                              size: 64,
                              color: TBColors.grey400,
                            ),
                            const SizedBox(height: TBSpacing.md),
                            Text(
                              'No hay solicitudes',
                              style: TBTypography.titleLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(TBSpacing.md),
                        itemCount: _filteredApplications.length,
                        itemBuilder: (context, index) {
                          return _buildCreditCard(_filteredApplications[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TBSpacing.md,
          vertical: TBSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? TBColors.primary : TBColors.grey100,
          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        ),
        child: Text(
          label,
          style: TBTypography.labelMedium.copyWith(
            color: isSelected ? TBColors.white : TBColors.grey600,
          ),
        ),
      ),
    );
  }
}