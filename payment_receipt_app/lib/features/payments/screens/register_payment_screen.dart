import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_input.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';
import '../../../design_system/components/molecules/tb_loading_overlay.dart';
import '../../../services/payment_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/currency_input_formatter.dart';

class RegisterPaymentScreen extends StatefulWidget {
  const RegisterPaymentScreen({super.key});

  @override
  State<RegisterPaymentScreen> createState() => _RegisterPaymentScreenState();
}

class _RegisterPaymentScreenState extends State<RegisterPaymentScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _remainingAmountController = TextEditingController();
  String _selectedMethod = 'CASH';
  String _selectedType = 'INCOME';
  DateTime _selectedDate = DateTime.now();
  bool _isPartialPayment = false;

  final List<Map<String, String>> _methods = [
    {'value': 'CASH', 'label': 'Efectivo'},
    {'value': 'TRANSFER', 'label': 'Transferencia'},
    {'value': 'CARD', 'label': 'Tarjeta'},
    {'value': 'CHECK', 'label': 'Cheque'},
  ];

  final List<Map<String, String>> _types = [
    {'value': 'INCOME', 'label': 'Entrada (Ingreso)'},
    {'value': 'EXPENSE', 'label': 'Salida (Gasto)'},
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TBColors.primary,
              onPrimary: TBColors.white,
              surface: TBColors.white,
              onSurface: TBColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: TBColors.primary,
                onPrimary: TBColors.white,
                surface: TBColors.white,
                onSurface: TBColors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      appBar: AppBar(
        title: Text('Registrar Pago', style: TBTypography.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(TBSpacing.screenPadding),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
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
                      // Tipo de transacción
                      Text(
                        'Tipo de transacción',
                        style: TBTypography.labelMedium.copyWith(color: TBColors.grey700),
                      ),
                      const SizedBox(height: TBSpacing.sm),
                      ...(_types.map((type) => RadioListTile<String>(
                        title: Text(type['label']!, style: TBTypography.bodyMedium),
                        value: type['value']!,
                        groupValue: _selectedType,
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                        activeColor: TBColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ))),
                      
                      const SizedBox(height: TBSpacing.lg),
                      
                      // Monto
                      TBInput(
                        label: 'Monto',
                        hint: '\\$0.00',
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.attach_money),
                        isCurrency: true,
                      ),
                      
                      const SizedBox(height: TBSpacing.lg),
                      
                      // Descripción
                      TBInput(
                        label: 'Descripción',
                        hint: 'Descripción del pago',
                        controller: _descriptionController,
                        prefixIcon: const Icon(Icons.description_outlined),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: TBSpacing.lg),
                      
                      // Método de pago
                      Text(
                        'Método de pago',
                        style: TBTypography.labelMedium.copyWith(color: TBColors.grey700),
                      ),
                      const SizedBox(height: TBSpacing.sm),
                      DropdownButtonFormField<String>(
                        value: _selectedMethod,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: TBSpacing.md,
                            vertical: TBSpacing.sm,
                          ),
                        ),
                        items: _methods.map((method) {
                          return DropdownMenuItem<String>(
                            value: method['value'],
                            child: Text(method['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMethod = value!;
                          });
                        },
                      ),
                      
                      const SizedBox(height: TBSpacing.lg),
                      
                      // Checkbox para pago menor a cuota
                      CheckboxListTile(
                        title: Text(
                          'Pago menor a cuota',
                          style: TBTypography.bodyMedium,
                        ),
                        subtitle: Text(
                          'Marcar si el pago no cubre la cuota completa',
                          style: TBTypography.labelMedium.copyWith(
                            color: TBColors.grey600,
                          ),
                        ),
                        value: _isPartialPayment,
                        onChanged: (value) {
                          setState(() {
                            _isPartialPayment = value ?? false;
                            if (!_isPartialPayment) {
                              _remainingAmountController.clear();
                            }
                          });
                        },
                        activeColor: TBColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      
                      // Campo condicional para monto restante
                      if (_isPartialPayment) ..[
                        const SizedBox(height: TBSpacing.lg),
                        TBInput(
                          label: 'Monto restante para completar cuota',
                          hint: '\\$0.00',
                          controller: _remainingAmountController,
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.money_off),
                          isCurrency: true,
                        ),
                        const SizedBox(height: TBSpacing.xs),
                        Container(
                          padding: const EdgeInsets.all(TBSpacing.sm),
                          decoration: BoxDecoration(
                            color: TBColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
                            border: Border.all(color: TBColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, color: TBColors.warning, size: 16),
                              const SizedBox(width: TBSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Este campo indica cuánto le falta al cliente para completar su cuota.',
                                  style: TBTypography.labelMedium.copyWith(
                                    color: TBColors.warning,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: TBSpacing.lg),
                      
                      // Fecha y hora
                      Text(
                        'Fecha y hora',
                        style: TBTypography.labelMedium.copyWith(color: TBColors.grey700),
                      ),
                      const SizedBox(height: TBSpacing.sm),
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(TBSpacing.md),
                          decoration: BoxDecoration(
                            border: Border.all(color: TBColors.grey300),
                            borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: TBColors.grey600),
                              const SizedBox(width: TBSpacing.sm),
                              Text(
                                _formatDateTime(_selectedDate),
                                style: TBTypography.bodyMedium,
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down, color: TBColors.grey600),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: TBSpacing.lg),
                      
                      // Información importante
                      Container(
                        padding: const EdgeInsets.all(TBSpacing.md),
                        decoration: BoxDecoration(
                          color: TBColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
                          border: Border.all(color: TBColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: TBColors.primary, size: 20),
                            const SizedBox(width: TBSpacing.sm),
                            Expanded(
                              child: Text(
                                'El pago se registrará con la fecha y hora seleccionada del dispositivo.',
                                style: TBTypography.labelMedium.copyWith(
                                  color: TBColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: TBSpacing.lg),
            
            // Botón de registro
            TBButton(
              text: 'Registrar Pago',
              fullWidth: true,
              onPressed: () async {
                final amount = CurrencyInputFormatter.getNumericValue(_amountController.text);
                final description = _descriptionController.text.trim();
                
                if (amount <= 0) {
                  TBDialogHelper.showWarning(
                    context,
                    title: 'Monto inválido',
                    message: 'Por favor, ingresa un monto válido mayor a cero.',
                  );
                  return;
                }
                
                if (description.isEmpty) {
                  TBDialogHelper.showWarning(
                    context,
                    title: 'Descripción requerida',
                    message: 'Por favor, ingresa una descripción para el pago.',
                  );
                  return;
                }
                
                if (_isPartialPayment && _remainingAmountController.text.isEmpty) {
                  TBDialogHelper.showWarning(
                    context,
                    title: 'Monto restante requerido',
                    message: 'Por favor, ingresa el monto restante para completar la cuota.',
                  );
                  return;
                }
                
                try {
                  final userId = await AuthService.getCurrentUserId();
                  if (userId == null) {
                    throw Exception('Usuario no encontrado');
                  }
                  
                  await TBLoadingOverlay.showWithDelay(
                    context,
                    _registerPayment(userId, amount, description),
                    message: 'Registrando pago...',
                    minDelayMs: 1500,
                  );
                  
                  TBDialogHelper.showSuccess(
                    context,
                    title: '¡Pago registrado!',
                    message: 'El pago ha sido registrado exitosamente con la fecha seleccionada.',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  );
                } catch (e) {
                  TBDialogHelper.showError(
                    context,
                    title: 'Error al registrar',
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
  
  Future<void> _registerPayment(int userId, double amount, String description) async {
    Map<String, dynamic> result;
    final remainingAmount = _isPartialPayment ? 
        CurrencyInputFormatter.getNumericValue(_remainingAmountController.text) : null;
    
    if (_selectedType == 'INCOME') {
      result = await PaymentService.registerIncome(
        userId: userId,
        amount: amount,
        paymentMethod: _selectedMethod,
        description: description,
        customDate: _selectedDate,
      );
    } else {
      result = await PaymentService.registerPayment(
        userId: userId,
        amount: amount,
        paymentMethod: _selectedMethod,
        debtPayment: amount,
        interestPayment: 0.0,
        description: description,
        customDate: _selectedDate,
        pagoMenorACuota: _isPartialPayment,
        valorRealCuota: remainingAmount,
      );
    }
    
    if (!result['success']) {
      throw Exception(result['error']);
    }
  }
}