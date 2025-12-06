import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/loan.dart';

class StatusBadge extends StatelessWidget {
  final LoanStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return _StatusConfig('Activo', AppColors.secondary);
      case LoanStatus.completed:
        return _StatusConfig('Completado', AppColors.primary);
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
