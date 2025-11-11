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
import '../../../design_system/components/molecules/tb_loading_dialog.dart';
import '../../recharge/screens/recharge_screen.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _bankController = TextEditingController();
  final _typeController = TextEditingController();
  double _currentBalance = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentBalance();
  }
  
  Future<void> _loadCurrentBalance() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentBalance = (user['moneyclean'] ?? user['balance'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {
      _currentBalance = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      appBar: AppBar(
        title: Text('Enviar dinero', style: TBTypography.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(TBSpacing.screenPadding),
        child: Column(
          children: [
            // Indicador de saldo disponible
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(TBSpacing.md),
              margin: const EdgeInsets.only(bottom: TBSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TBColors.primary.withOpacity(0.1), TBColors.secondary.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                border: Border.all(color: TBColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: TBColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: TBSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo disponible',
                        style: TBTypography.labelMedium.copyWith(
                          color: TBColors.grey600,
                        ),
                      ),
                      Text(
                        '\$${_currentBalance.toStringAsFixed(2)}',
                        style: TBTypography.headlineSmall.copyWith(
                          color: TBColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadCurrentBalance,
                    icon: Icon(
                      Icons.refresh,
                      color: TBColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
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
                children: [
                  TBInput(
                    label: 'Descripción',
                    hint: 'Descripción del envío',
                    controller: _descriptionController,
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                  const SizedBox(height: TBSpacing.lg),
                  TBInput(
                    label: 'Monto',
                    hint: '0.00',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.attach_money),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  // Indicador de validación de monto
                  if (_amountController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: TBSpacing.xs),
                      child: Builder(
                        builder: (context) {
                          final amount = double.tryParse(_amountController.text) ?? 0;
                          final isValid = amount > 0 && amount <= _currentBalance;
                          return Row(
                            children: [
                              Icon(
                                isValid ? Icons.check_circle : Icons.error,
                                size: 16,
                                color: isValid ? TBColors.success : TBColors.error,
                              ),
                              const SizedBox(width: TBSpacing.xs),
                              Expanded(
                                child: Text(
                                  isValid 
                                      ? 'Monto válido'
                                      : amount > _currentBalance
                                          ? 'Saldo insuficiente'
                                          : 'Ingresa un monto válido',
                                  style: TBTypography.labelSmall.copyWith(
                                    color: isValid ? TBColors.success : TBColors.error,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: TBSpacing.lg),
                  TBInput(
                    label: 'Banco',
                    hint: 'Nombre del banco',
                    controller: _bankController,
                    prefixIcon: const Icon(Icons.account_balance),
                  ),
                  const SizedBox(height: TBSpacing.lg),
                  TBInput(
                    label: 'Tipo',
                    hint: 'Tipo de transferencia',
                    controller: _typeController,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                ],
              ),
            ),
            const Spacer(),
            TBButton(
              text: 'Enviar dinero',
              fullWidth: true,
              onPressed: () async {
                final amount = double.tryParse(_amountController.text) ?? 0;
                final description = _descriptionController.text;
                final bank = _bankController.text;
                final type = _typeController.text;
                
                if (amount <= 0 || description.isEmpty || bank.isEmpty || type.isEmpty) {
                  TBDialogHelper.showWarning(
                    context,
                    title: 'Campos incompletos',
                    message: 'Por favor, completa todos los campos requeridos.',
                  );
                  return;
                }
                
                // Validar saldo suficiente
                await _loadCurrentBalance();
                if (amount > _currentBalance) {
                  TBDialogHelper.showError(
                    context,
                    title: 'Saldo insuficiente',
                    message: 'No tienes suficiente saldo para realizar este envío.\n\nSaldo disponible: \$${_currentBalance.toStringAsFixed(2)}\nMonto a enviar: \$${amount.toStringAsFixed(2)}\n\n¿Deseas hacer una recarga?',
                    buttonText: 'Recargar ahora',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RechargeScreen()),
                      );
                    },
                  );
                  return;
                }
                
                try {
                  final userId = await AuthService.getCurrentUserId() ?? 1;
                  final response = await ApiService.createAdminRequest({
                    'requestType': 'SEND_MONEY',
                    'userId': userId,
                    'amount': amount,
                    'details': 'Descripción: $description. Banco: $bank. Tipo: $type',
                  });
                  
                  TBDialogHelper.showSuccess(
                    context,
                    title: '¡Solicitud enviada!',
                    message: 'Tu solicitud de envío ha sido creada y está pendiente de aprobación.',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  );
                } catch (e) {
                  TBDialogHelper.showError(
                    context,
                    title: 'Error en el envío',
                    message: e.toString().replaceAll('Exception: ', ''),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}