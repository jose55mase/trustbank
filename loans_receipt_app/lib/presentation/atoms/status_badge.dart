import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/loan_status.dart';

class StatusBadge extends StatelessWidget {
  final LoanStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return _StatusConfig('Activo', AppColors.success);
      case LoanStatus.completed:
        return _StatusConfig('Completado', AppColors.info);
      case LoanStatus.overdue:
        return _StatusConfig('Vencido', AppColors.error);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  _StatusConfig(this.label, this.color);
}
