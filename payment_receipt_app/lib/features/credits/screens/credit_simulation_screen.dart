import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_input.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../models/credit_option.dart';
import 'credit_processing_screen.dart';
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
              child: BlocBuilder<CreditsBloc, CreditsState>(
                builder: (context, state) {
                  return TBButton(
                    text: state is CreditsSubmitting ? 'Enviando solicitud...' : 'Solicitar crédito',
                    fullWidth: true,
                    isLoading: state is CreditsSubmitting,
                    onPressed: state is CreditsSubmitting ? null : () {
                      final amount = CurrencyInputFormatter.getNumericValue(_amountController.text);
                      
                      // Validar monto mínimo y máximo
                      if (amount < widget.creditOption.minAmount) {
                        TBDialogHelper.showWarning(
                          context,
                          title: 'Monto inválido',
                          message: 'El monto mínimo es \$${widget.creditOption.minAmount.toStringAsFixed(0)}',
                        );
                        return;
                      }
                      
                      if (amount > widget.creditOption.maxAmount) {
                        TBDialogHelper.showWarning(
                          context,
                          title: 'Monto inválido',
                          message: 'El monto máximo es \$${widget.creditOption.maxAmount.toStringAsFixed(0)}',
                        );
                        return;
                      }
                      
                      // Mostrar confirmación antes de enviar
                      _showConfirmationDialog(context, amount);
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
  
  void _showConfirmationDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirmar Solicitud',
            style: TBTypography.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseas solicitar este crédito?',
                style: TBTypography.bodyMedium,
              ),
              const SizedBox(height: TBSpacing.md),
              Container(
                padding: const EdgeInsets.all(TBSpacing.sm),
                decoration: BoxDecoration(
                  color: TBColors.grey100,
                  borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Tipo:', widget.creditOption.title),
                    const SizedBox(height: TBSpacing.xs),
                    _buildDetailRow('Monto:', CurrencyFormatter.format(amount)),
                    const SizedBox(height: TBSpacing.xs),
                    _buildDetailRow('Plazo:', '$_selectedMonths meses'),
                    const SizedBox(height: TBSpacing.xs),
                    _buildDetailRow('Cuota mensual:', CurrencyFormatter.format(_monthlyPayment)),
                  ],
                ),
              ),
              const SizedBox(height: TBSpacing.sm),
              Text(
                'Una vez enviada, la solicitud será revisada y aprobada por un administrador.',
                style: TBTypography.bodySmall.copyWith(color: TBColors.grey600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TBTypography.labelMedium.copyWith(color: TBColors.grey600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                // Navegar inmediatamente a pantalla de procesamiento
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreditProcessingScreen(
                      creditsBloc: context.read<CreditsBloc>(),
                    ),
                  ),
                );
                
                // Enviar solicitud
                context.read<CreditsBloc>().add(SubmitCreditApplication(
                  creditType: widget.creditOption.title,
                  amount: amount,
                  termMonths: _selectedMonths,
                  interestRate: widget.creditOption.interestRate,
                  monthlyPayment: _monthlyPayment,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TBColors.primary,
                foregroundColor: TBColors.white,
              ),
              child: Text(
                'Confirmar',
                style: TBTypography.labelMedium.copyWith(color: TBColors.white),
              ),
            ),
          ],
        );
      },
    );
  }

}