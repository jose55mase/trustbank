import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/request_model.dart';

class AdminStats extends StatelessWidget {
  final List<AdminRequest> requests;

  const AdminStats({super.key, required this.requests});

  @override
  Widget build(BuildContext context) {
    final pending = requests.where((r) => r.status == RequestStatus.pending).length;
    final approved = requests.where((r) => r.status == RequestStatus.approved).length;
    final rejected = requests.where((r) => r.status == RequestStatus.rejected).length;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Pendientes', pending, TBColors.primary)),
        const SizedBox(width: TBSpacing.sm),
        Expanded(child: _buildStatCard('Aprobadas', approved, TBColors.success)),
        const SizedBox(width: TBSpacing.sm),
        Expanded(child: _buildStatCard('Rechazadas', rejected, TBColors.error)),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
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
        children: [
          Text(
            count.toString(),
            style: TBTypography.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TBTypography.labelMedium.copyWith(color: TBColors.grey600),
          ),
        ],
      ),
    );
  }
}