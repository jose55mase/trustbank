import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../models/credit_application.dart';
import '../bloc/credits_bloc.dart';
import '../bloc/credits_event.dart';
import '../bloc/credits_state.dart';
import '../../../utils/currency_formatter.dart';

class CreditStatusScreen extends StatefulWidget {
  final CreditApplication application;

  const CreditStatusScreen({
    super.key,
    required this.application,
  });

  @override
  State<CreditStatusScreen> createState() => _CreditStatusScreenState();
}

class _CreditStatusScreenState extends State<CreditStatusScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late CreditsBloc _creditsBloc;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _creditsBloc = CreditsBloc();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    if (widget.application.status == CreditStatus.pending || 
        widget.application.status == CreditStatus.underReview) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
      
      // Verificar estado cada 30 segundos
      _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _creditsBloc.add(CheckApplicationStatus(applicationId: widget.application.id));
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _statusCheckTimer?.cancel();
    _creditsBloc.close();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.application.status) {
      case CreditStatus.pending:
      case CreditStatus.underReview:
        return TBColors.warning;
      case CreditStatus.approved:
      case CreditStatus.disbursed:
        return TBColors.success;
      case CreditStatus.rejected:
        return TBColors.error;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.application.status) {
      case CreditStatus.pending:
        return Icons.schedule;
      case CreditStatus.underReview:
        return Icons.search;
      case CreditStatus.approved:
        return Icons.check_circle;
      case CreditStatus.rejected:
        return Icons.cancel;
      case CreditStatus.disbursed:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildStatusIcon() {
    final color = _getStatusColor();
    final icon = _getStatusIcon();
    
    if (widget.application.status == CreditStatus.pending || 
        widget.application.status == CreditStatus.underReview) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: color, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 60),
                  ),
                );
              },
            ),
          );
        },
      );
    }
    
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _creditsBloc,
      child: BlocListener<CreditsBloc, CreditsState>(
        listener: (context, state) {
          if (state is CreditStatusUpdated) {
            if (state.application.status != widget.application.status) {
              // Estado cambió, actualizar UI
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CreditStatusScreen(application: state.application),
                ),
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: TBColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(TBSpacing.screenPadding),
              child: Column(
                children: [
                  const Spacer(),
                  _buildStatusIcon(),
                  const SizedBox(height: TBSpacing.xl),
                  Text(
                    widget.application.statusText,
                    style: TBTypography.displayLarge.copyWith(
                      color: _getStatusColor(),
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TBSpacing.md),
                  Text(
                    widget.application.statusDescription,
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
                          'Detalles de tu solicitud',
                          style: TBTypography.titleLarge,
                        ),
                        const SizedBox(height: TBSpacing.md),
                        _buildDetailRow('Tipo de crédito:', widget.application.creditType),
                        const SizedBox(height: TBSpacing.sm),
                        _buildDetailRow('Monto:', CurrencyFormatter.format(widget.application.amount)),
                        const SizedBox(height: TBSpacing.sm),
                        _buildDetailRow('Plazo:', '${widget.application.termMonths} meses'),
                        const SizedBox(height: TBSpacing.sm),
                        _buildDetailRow('Cuota mensual:', CurrencyFormatter.format(widget.application.monthlyPayment)),
                        const SizedBox(height: TBSpacing.sm),
                        _buildDetailRow('Fecha de solicitud:', _formatDate(widget.application.applicationDate)),
                      ],
                    ),
                  ),
                  if (widget.application.status == CreditStatus.rejected && 
                      widget.application.rejectionReason != null) ...[
                    const SizedBox(height: TBSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(TBSpacing.md),
                      decoration: BoxDecoration(
                        color: TBColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: TBColors.error, size: 20),
                          const SizedBox(width: TBSpacing.sm),
                          Expanded(
                            child: Text(
                              'Motivo: ${widget.application.rejectionReason}',
                              style: TBTypography.bodyMedium.copyWith(color: TBColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.application.status == CreditStatus.approved && 
                      widget.application.approvalComments != null) ...[
                    const SizedBox(height: TBSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(TBSpacing.md),
                      decoration: BoxDecoration(
                        color: TBColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: TBColors.success, size: 20),
                          const SizedBox(width: TBSpacing.sm),
                          Expanded(
                            child: Text(
                              widget.application.approvalComments!,
                              style: TBTypography.bodyMedium.copyWith(color: TBColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.application.status == CreditStatus.pending || 
                      widget.application.status == CreditStatus.underReview) ...[
                    const SizedBox(height: TBSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(TBSpacing.md),
                      decoration: BoxDecoration(
                        color: TBColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: TBColors.secondary, size: 20),
                          const SizedBox(width: TBSpacing.sm),
                          Expanded(
                            child: Text(
                              'Te contactaremos en las próximas 24-48 horas con el resultado',
                              style: TBTypography.bodyMedium.copyWith(color: TBColors.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      if (widget.application.status == CreditStatus.pending || 
                          widget.application.status == CreditStatus.underReview)
                        Expanded(
                          child: TBButton(
                            text: 'Verificar estado',
                            type: TBButtonType.outline,
                            onPressed: () {
                              _creditsBloc.add(CheckApplicationStatus(applicationId: widget.application.id));
                            },
                          ),
                        ),
                      if (widget.application.status == CreditStatus.pending || 
                          widget.application.status == CreditStatus.underReview)
                        const SizedBox(width: TBSpacing.md),
                      Expanded(
                        child: TBButton(
                          text: 'Volver al inicio',
                          onPressed: () {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}