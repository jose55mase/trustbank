import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';

class CreditValidationScreen extends StatefulWidget {
  final String creditType;
  final double amount;
  final int months;

  const CreditValidationScreen({
    super.key,
    required this.creditType,
    required this.amount,
    required this.months,
  });

  @override
  State<CreditValidationScreen> createState() => _CreditValidationScreenState();
}

class _CreditValidationScreenState extends State<CreditValidationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TBSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: TBColors.primaryGradient,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: TBColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animation.value * 2 * 3.14159,
                      child: const Icon(
                        Icons.hourglass_empty,
                        color: TBColors.white,
                        size: 60,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: TBSpacing.xl),
              Text(
                'Validando tu solicitud',
                style: TBTypography.displayLarge.copyWith(
                  color: TBColors.primary,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TBSpacing.md),
              Text(
                'Estamos revisando tu información\ny capacidad de pago',
                style: TBTypography.bodyLarge.copyWith(
                  color: TBColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TBSpacing.xl),
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
                    Text(
                      'Resumen de tu solicitud',
                      style: TBTypography.titleLarge,
                    ),
                    const SizedBox(height: TBSpacing.md),
                    _buildDetailRow('Tipo de crédito:', widget.creditType),
                    const SizedBox(height: TBSpacing.sm),
                    _buildDetailRow('Monto solicitado:', '\$${widget.amount.toStringAsFixed(2)}'),
                    const SizedBox(height: TBSpacing.sm),
                    _buildDetailRow('Plazo:', '${widget.months} meses'),
                  ],
                ),
              ),
              const SizedBox(height: TBSpacing.xl),
              Container(
                padding: const EdgeInsets.all(TBSpacing.md),
                decoration: BoxDecoration(
                  color: TBColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: TBColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: TBSpacing.sm),
                    Expanded(
                      child: Text(
                        'Te contactaremos en las próximas 24 horas con el resultado',
                        style: TBTypography.bodyMedium.copyWith(
                          color: TBColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TBButton(
                text: 'Volver al inicio',
                fullWidth: true,
                onPressed: () {
                  TBDialogHelper.showSuccess(
                    context,
                    title: '¡Solicitud enviada!',
                    message: 'Tu solicitud de crédito ha sido enviada exitosamente. Te contactaremos pronto con el resultado.',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  );
                },
              ),
            ],
          ),
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