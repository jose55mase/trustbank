import 'dart:math' as Math;
import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_input.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../models/credit_option.dart';
import 'credit_validation_screen.dart';
import '../../notifications/bloc/notifications_bloc.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';

class CreditSimulationScreen extends StatefulWidget {
  final CreditOption creditOption;

  const CreditSimulationScreen({
    super.key,
    required this.creditOption,
  });

  @override
  State<CreditSimulationScreen> createState() => _CreditSimulationScreenState();
}

class _CreditSimulationScreenState extends State<CreditSimulationScreen> {
  final _amountController = TextEditingController();
  int _selectedMonths = 12;
  double _monthlyPayment = 0;
  double _totalPayment = 0;
  double _totalInterest = 0;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.creditOption.minAmount.toString();
    _selectedMonths = widget.creditOption.minTermMonths;
    _calculatePayment();
  }

  void _calculatePayment() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > 0) {
      final monthlyRate = widget.creditOption.interestRate / 100 / 12;
      final payment = amount * (monthlyRate * Math.pow(1 + monthlyRate, _selectedMonths)) / 
                     (Math.pow(1 + monthlyRate, _selectedMonths) - 1);
      
      setState(() {
        _monthlyPayment = payment;
        _totalPayment = payment * _selectedMonths;
        _totalInterest = _totalPayment - amount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      appBar: AppBar(
        title: Text('Simular ${widget.creditOption.title}', style: TBTypography.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TBSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    'Configura tu crédito',
                    style: TBTypography.titleLarge,
                  ),
                  const SizedBox(height: TBSpacing.lg),
                  TBInput(
                    label: 'Monto del crédito (USD)',
                    hint: 'Ingresa el monto',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculatePayment(),
                  ),
                  const SizedBox(height: TBSpacing.lg),
                  Text(
                    'Plazo: $_selectedMonths meses',
                    style: TBTypography.labelMedium.copyWith(color: TBColors.grey700),
                  ),
                  const SizedBox(height: TBSpacing.sm),
                  Slider(
                    value: _selectedMonths.toDouble(),
                    min: widget.creditOption.minTermMonths.toDouble(),
                    max: widget.creditOption.maxTermMonths.toDouble(),
                    divisions: (widget.creditOption.maxTermMonths - widget.creditOption.minTermMonths) ~/ 6,
                    activeColor: TBColors.primary,
                    onChanged: (value) {
                      setState(() {
                        _selectedMonths = value.round();
                      });
                      _calculatePayment();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: TBSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(TBSpacing.lg),
              decoration: BoxDecoration(
                gradient: TBColors.primaryGradient,
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
              ),
              child: Column(
                children: [
                  Text(
                    'Tu cuota mensual sería',
                    style: TBTypography.bodyMedium.copyWith(
                      color: TBColors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: TBSpacing.sm),
                  Text(
                    '\$${_monthlyPayment.toStringAsFixed(2)}',
                    style: TBTypography.displayLarge.copyWith(
                      color: TBColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TBSpacing.lg),
            Container(
              padding: const EdgeInsets.all(TBSpacing.md),
              decoration: BoxDecoration(
                color: TBColors.surface,
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                border: Border.all(color: TBColors.grey300.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Total a pagar:', '\$${_totalPayment.toStringAsFixed(2)}'),
                  const SizedBox(height: TBSpacing.sm),
                  _buildDetailRow('Total intereses:', '\$${_totalInterest.toStringAsFixed(2)}'),
                  const SizedBox(height: TBSpacing.sm),
                  _buildDetailRow('Tasa de interés:', '${widget.creditOption.interestRate}% EA'),
                ],
              ),
            ),
            const SizedBox(height: TBSpacing.xl),
            TBButton(
              text: 'Solicitar crédito',
              fullWidth: true,
              onPressed: () async {
                final amount = double.tryParse(_amountController.text) ?? 0;
                
                try {
                  final userId = await AuthService.getCurrentUserId() ?? 1;
                  final response = await ApiService.applyForCredit({
                    'userId': userId,
                    'creditType': widget.creditOption.title,
                    'amount': amount,
                    'termMonths': _selectedMonths,
                    'interestRate': widget.creditOption.interestRate,
                    'monthlyPayment': _monthlyPayment,
                  });
                  
                  if (response['status'] == 201) {
                    NotificationsBloc().add(AddCreditNotification(
                      creditType: widget.creditOption.title,
                      amount: amount,
                    ));
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreditValidationScreen(
                          creditType: widget.creditOption.title,
                          amount: amount,
                          months: _selectedMonths,
                        ),
                      ),
                    );
                  } else {
                    throw Exception(response['message'] ?? 'Error al procesar solicitud');
                  }
                } catch (e) {
                  TBDialogHelper.showError(
                    context,
                    title: 'Error en la solicitud',
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
        ),
        Text(
          value,
          style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}