import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_input.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';
import '../../../design_system/components/molecules/tb_loading_overlay.dart';
import '../../../services/api_service.dart';
import '../../../utils/currency_input_formatter.dart';

class AdjustBalanceScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdjustBalanceScreen({super.key, required this.user});

  @override
  State<AdjustBalanceScreen> createState() => _AdjustBalanceScreenState();
}

class _AdjustBalanceScreenState extends State<AdjustBalanceScreen> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String _operation = 'ADD';

  String get _userName =>
      widget.user['firstName'] ?? widget.user['fistName'] ?? widget.user['username'] ?? 'Usuario';

  int get _currentBalance => widget.user['moneyclean'] ?? 0;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      appBar: AppBar(
        title: Text('Ajustar Saldo', style: TBTypography.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TBSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info del usuario
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(TBSpacing.md),
              decoration: BoxDecoration(
                color: TBColors.surface,
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                border: Border.all(color: TBColors.grey300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: TBTypography.titleLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user['email'] ?? '',
                    style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
                  ),
                  const SizedBox(height: TBSpacing.sm),
                  Row(
                    children: [
                      Text('Saldo actual: ', style: TBTypography.bodyMedium),
                      Text(
                        '\$$_currentBalance',
                        style: TBTypography.titleLarge.copyWith(
                          color: TBColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: TBSpacing.lg),

            // Tipo de operación
            Text(
              'Tipo de operación',
              style: TBTypography.labelMedium.copyWith(color: TBColors.grey700),
            ),
            const SizedBox(height: TBSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _operation = 'ADD'),
                    child: Container(
                      padding: const EdgeInsets.all(TBSpacing.md),
                      decoration: BoxDecoration(
                        color: _operation == 'ADD'
                            ? TBColors.success.withOpacity(0.1)
                            : TBColors.surface,
                        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                        border: Border.all(
                          color: _operation == 'ADD' ? TBColors.success : TBColors.grey300,
                          width: _operation == 'ADD' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: _operation == 'ADD' ? TBColors.success : TBColors.grey600,
                            size: 32,
                          ),
                          const SizedBox(height: TBSpacing.xs),
                          Text(
                            'Agregar',
                            style: TBTypography.bodyMedium.copyWith(
                              color: _operation == 'ADD' ? TBColors.success : TBColors.grey600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: TBSpacing.md),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _operation = 'SUBTRACT'),
                    child: Container(
                      padding: const EdgeInsets.all(TBSpacing.md),
                      decoration: BoxDecoration(
                        color: _operation == 'SUBTRACT'
                            ? TBColors.error.withOpacity(0.1)
                            : TBColors.surface,
                        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                        border: Border.all(
                          color: _operation == 'SUBTRACT' ? TBColors.error : TBColors.grey300,
                          width: _operation == 'SUBTRACT' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.remove_circle_outline,
                            color: _operation == 'SUBTRACT' ? TBColors.error : TBColors.grey600,
                            size: 32,
                          ),
                          const SizedBox(height: TBSpacing.xs),
                          Text(
                            'Quitar',
                            style: TBTypography.bodyMedium.copyWith(
                              color: _operation == 'SUBTRACT' ? TBColors.error : TBColors.grey600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: TBSpacing.lg),

            // Monto
            TBInput(
              label: 'Monto',
              hint: '\$0.00',
              controller: _amountController,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.attach_money),
              isCurrency: true,
            ),

            const SizedBox(height: TBSpacing.lg),

            // Razón
            TBInput(
              label: 'Razón (opcional)',
              hint: 'Motivo del ajuste',
              controller: _reasonController,
              prefixIcon: const Icon(Icons.note_outlined),
            ),

            const SizedBox(height: TBSpacing.xl),

            // Botón
            TBButton(
              text: _operation == 'ADD' ? 'Agregar Saldo' : 'Quitar Saldo',
              fullWidth: true,
              onPressed: _adjustBalance,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adjustBalance() async {
    final amount = CurrencyInputFormatter.getNumericValue(_amountController.text);
    final reason = _reasonController.text.trim().isEmpty
        ? 'Ajuste administrativo'
        : _reasonController.text.trim();

    if (amount <= 0) {
      TBDialogHelper.showWarning(
        context,
        title: 'Monto inválido',
        message: 'Ingresa un monto mayor a cero.',
      );
      return;
    }

    try {
      await TBLoadingOverlay.showWithDelay(
        context,
        ApiService.adjustUserBalance(
          userId: widget.user['id'],
          amount: amount,
          operation: _operation,
          reason: reason,
        ),
        message: _operation == 'ADD' ? 'Agregando saldo...' : 'Quitando saldo...',
        minDelayMs: 1500,
      );

      if (!mounted) return;

      TBDialogHelper.showSuccess(
        context,
        title: '¡Saldo actualizado!',
        message: _operation == 'ADD'
            ? 'Se agregaron \$${amount.toStringAsFixed(0)} al usuario $_userName.'
            : 'Se quitaron \$${amount.toStringAsFixed(0)} al usuario $_userName.',
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(true); // Return true to refresh
        },
      );
    } catch (e) {
      if (!mounted) return;
      TBDialogHelper.showError(
        context,
        title: 'Error',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
