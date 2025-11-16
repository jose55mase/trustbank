import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_input.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../notifications/bloc/notifications_bloc.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/currency_input_formatter.dart';
import '../../../design_system/components/molecules/tb_loading_overlay.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'Tarjeta de crédito';

  final List<String> _methods = [
    'Tarjeta de crédito',
    'Tarjeta de débito',
    'Transferencia bancaria',
    'PayPal',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      appBar: AppBar(
        title: Text('Recargar saldo', style: TBTypography.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(TBSpacing.screenPadding),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(TBSpacing.lg),
              decoration: BoxDecoration(
                color: TBColors.surface,
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
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
                  TBInput(
                    label: 'Monto a recargar',
                    hint: '\$0.00',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.attach_money),
                    isCurrency: true,
                  ),
                  const SizedBox(height: TBSpacing.lg),
                  Text(
                    'Método de pago',
                    style: TBTypography.labelMedium.copyWith(color: TBColors.grey700),
                  ),
                  const SizedBox(height: TBSpacing.sm),
                  ...(_methods.map((method) => RadioListTile<String>(
                    title: Text(method, style: TBTypography.bodyMedium),
                    value: method,
                    groupValue: _selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value!;
                      });
                    },
                    activeColor: TBColors.primary,
                  ))),
                ],
              ),
            ),
            const Spacer(),
            TBButton(
              text: 'Recargar saldo',
              fullWidth: true,
              onPressed: () async {
                final amount = CurrencyInputFormatter.getNumericValue(_amountController.text);
                
                if (amount > 0) {
                  try {
                    await TBLoadingOverlay.showWithDelay(
                      context,
                      _processRecharge(amount),
                      message: 'Procesando recarga...',
                      minDelayMs: 2000,
                    );
                    
                    // Actualizar notificaciones
                    NotificationsBloc().add(LoadNotifications());
                    
                    TBDialogHelper.showSuccess(
                      context,
                      title: 'Solicitud enviada',
                      message: 'Tu solicitud de recarga ha sido enviada y está pendiente de aprobación.',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                    );
                  } catch (e) {
                    TBDialogHelper.showError(
                      context,
                      title: 'Error',
                      message: e.toString().replaceAll('Exception: ', ''),
                    );
                  }
                } else {
                  TBDialogHelper.showWarning(
                    context,
                    title: 'Monto inválido',
                    message: 'Ingresa un monto válido mayor a cero.',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _processRecharge(double amount) async {
    final userId = await AuthService.getCurrentUserId();
    if (userId == null) throw Exception('Usuario no encontrado');
    
    final requestData = {
      'requestType': 'RECHARGE',
      'userId': userId,
      'amount': amount,
      'description': 'Solicitud de recarga de saldo',
      'details': 'Método: $_selectedMethod - Monto: ${CurrencyFormatter.format(amount)}',
      'status': 'PENDING'
    };
    
    await ApiService.createAdminRequest(requestData);
  }
}