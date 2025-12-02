import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_input.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../models/credit_option.dart';
import 'credit_status_screen.dart';
import '../../notifications/bloc/notifications_bloc.dart';
import '../bloc/credits_bloc.dart';
import '../bloc/credits_event.dart';
import '../bloc/credits_state.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/currency_input_formatter.dart';

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
    _selectedMonths = widget.creditOption.minTermMonths;
    
    // Initialize with formatted currency
    final initialAmount = widget.creditOption.minAmount;
    _amountController.text = '\$${initialAmount.toStringAsFixed(2)}';
    
    // Calculate initial payment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatePayment();
    });
  }

  void _calculatePayment() {
    try {
      double amount;
      
      // Try to get amount from formatted text
      if (_amountController.text.contains('\$')) {
        amount = CurrencyInputFormatter.getNumericValue(_amountController.text);
      } else {
        // Fallback for plain number
        final cleanText = _amountController.text.replaceAll(RegExp(r'[^\d.]'), '');
        amount = double.tryParse(cleanText) ?? 0.0;
      }
      
      if (amount > 0 && _selectedMonths > 0) {
        final monthlyRate = widget.creditOption.interestRate / 100 / 12;
        
        if (monthlyRate > 0) {
          final payment = amount * (monthlyRate * math.pow(1 + monthlyRate, _selectedMonths)) / 
                         (math.pow(1 + monthlyRate, _selectedMonths) - 1);
          
          if (mounted) {
            setState(() {
              _monthlyPayment = payment.isFinite ? payment : 0.0;
              _totalPayment = _monthlyPayment * _selectedMonths;
              _totalInterest = _totalPayment - amount;
            });
          }
        } else {
          // Handle zero interest rate
          if (mounted) {
            setState(() {
              _monthlyPayment = amount / _selectedMonths;
              _totalPayment = amount;
              _totalInterest = 0.0;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _monthlyPayment = 0.0;
            _totalPayment = 0.0;
            _totalInterest = 0.0;
          });
        }
      }
    } catch (e) {
      // Handle any calculation errors silently
      if (mounted) {
        setState(() {
          _monthlyPayment = 0.0;
          _totalPayment = 0.0;
          _totalInterest = 0.0;
        });
      }
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
                    hint: '\$0.00',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    isCurrency: true,
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
                    CurrencyFormatter.format(_monthlyPayment),
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
                  _buildDetailRow('Total a pagar:', CurrencyFormatter.format(_totalPayment)),
                  const SizedBox(height: TBSpacing.sm),
                  _buildDetailRow('Total intereses:', CurrencyFormatter.format(_totalInterest)),
                  const SizedBox(height: TBSpacing.sm),
                  _buildDetailRow('Tasa de interés:', '${widget.creditOption.interestRate}% EA'),
                ],
              ),
            ),
            const SizedBox(height: TBSpacing.xl),
            BlocProvider(
              create: (context) => CreditsBloc(),
              child: BlocConsumer<CreditsBloc, CreditsState>(
                listener: (context, state) {
                  if (state is CreditApplicationSubmitted) {
                    NotificationsBloc().add(AddCreditNotification(
                      creditType: widget.creditOption.title,
                      amount: CurrencyInputFormatter.getNumericValue(_amountController.text),
                    ));
                    
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreditStatusScreen(
                          application: state.application,
                        ),
                      ),
                    );
                  } else if (state is CreditsError) {
                    TBDialogHelper.showError(
                      context,
                      title: 'Error en la solicitud',
                      message: state.message,
                    );
                  }
                },
                builder: (context, state) {
                  return TBButton(
                    text: state is CreditsSubmitting ? 'Procesando...' : 'Solicitar crédito',
                    fullWidth: true,
                    isLoading: state is CreditsSubmitting,
                    onPressed: state is CreditsSubmitting ? null : () {
                      final amount = CurrencyInputFormatter.getNumericValue(_amountController.text);
                      
                      context.read<CreditsBloc>().add(SubmitCreditApplication(
                        creditType: widget.creditOption.title,
                        amount: amount,
                        termMonths: _selectedMonths,
                        interestRate: widget.creditOption.interestRate,
                        monthlyPayment: _monthlyPayment,
                      ));
                    },
                  );
                },
              ),
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