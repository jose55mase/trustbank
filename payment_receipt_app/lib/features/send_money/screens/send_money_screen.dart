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
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _conceptController = TextEditingController();

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
                    label: 'Destinatario',
                    hint: 'Email o número de teléfono',
                    controller: _recipientController,
                    prefixIcon: const Icon(Icons.person_outline),
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
                    label: 'Concepto (opcional)',
                    hint: 'Descripción del pago',
                    controller: _conceptController,
                    prefixIcon: const Icon(Icons.note_outlined),
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
                final recipient = _recipientController.text;
                
                if (amount > 0 && recipient.isNotEmpty) {
                  try {
                    final userId = await AuthService.getCurrentUserId() ?? 1;
                    final response = await ApiService.createAdminRequest({
                      'requestType': 'SEND_MONEY',
                      'userId': userId,
                      'amount': amount,
                      'details': 'Envío a: $recipient. Concepto: ${_conceptController.text}',
                    });
                    
                    if (response['status'] == 201) {
                      NotificationsBloc().add(AddSendMoneyNotification(
                        recipient: recipient,
                        amount: amount,
                      ));
                      
                      TBDialogHelper.showSuccess(
                        context,
                        title: '¡Envío exitoso!',
                        message: response['message'] ?? 'Tu solicitud de envío ha sido creada exitosamente.',
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                      );
                    } else {
                      throw Exception(response['message'] ?? 'Error desconocido');
                    }
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
                    message: 'Por favor, completa todos los campos requeridos para continuar con el envío.',
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