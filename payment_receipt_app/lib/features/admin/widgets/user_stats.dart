import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';

class UserStats extends StatelessWidget {
  final Map<String, int> stats;

  const UserStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.md),
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
            'Estadísticas de Usuarios',
            style: TBTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TBSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats['total'] ?? 0,
                  TBColors.primary,
                  Icons.people,
                ),
              ),
              const SizedBox(width: TBSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  'Activos',
                  stats['active'] ?? 0,
                  TBColors.success,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: TBSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  stats['pending'] ?? 0,
                  Colors.orange,
                  Icons.pending,
                ),
              ),
              const SizedBox(width: TBSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  'Suspendidos',
                  stats['suspended'] ?? 0,
                  TBColors.error,
                  Icons.block,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: TBSpacing.xs),
          Text(
            value.toString(),
            style: TBTypography.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TBTypography.labelMedium.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}