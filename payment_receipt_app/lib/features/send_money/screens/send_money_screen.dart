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
                
                if (amount > 0 && description.isNotEmpty && bank.isNotEmpty && type.isNotEmpty) {
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
                } else {
                  TBDialogHelper.showWarning(
                    context,
                    title: 'Campos incompletos',
                    message: 'Por favor, completa todos los campos requeridos.',
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