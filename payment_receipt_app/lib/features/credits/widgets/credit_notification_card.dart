import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/credit_application.dart';

class CreditNotificationCard extends StatelessWidget {
  final CreditApplication application;
  final VoidCallback? onTap;

  const CreditNotificationCard({
    super.key,
    required this.application,
    this.onTap,
  });

  Color _getStatusColor() {
    switch (application.status) {
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
    switch (application.status) {
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

  String _getStatusMessage() {
    switch (application.status) {
      case CreditStatus.pending:
        return 'Tu solicitud está en cola de revisión';
      case CreditStatus.underReview:
        return 'Estamos evaluando tu información crediticia';
      case CreditStatus.approved:
        return '¡Felicidades! Tu crédito ha sido aprobado';
      case CreditStatus.rejected:
        return 'Tu solicitud no pudo ser aprobada en esta ocasión';
      case CreditStatus.disbursed:
        return 'El dinero ya está disponible en tu cuenta';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: TBSpacing.sm),
        padding: const EdgeInsets.all(TBSpacing.md),
        decoration: BoxDecoration(
          color: TBColors.surface,
          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
          border: Border.all(color: statusColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: TBColors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: TBSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${application.creditType} - ${application.statusText}',
                    style: TBTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStatusMessage(),
                    style: TBTypography.labelMedium.copyWith(
                      color: TBColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: TBColors.grey400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}