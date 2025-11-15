import 'package:flutter/material.dart';
import '../design_system/colors/tb_colors.dart';
import '../design_system/typography/tb_typography.dart';
import '../design_system/spacing/tb_spacing.dart';

class AdminCredentialsInfo extends StatelessWidget {
  const AdminCredentialsInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(TBSpacing.md),
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: TBColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: TBColors.primary, size: 20),
              const SizedBox(width: TBSpacing.xs),
              Text(
                'Credenciales de Administrador',
                style: TBTypography.titleSmall.copyWith(
                  color: TBColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: TBSpacing.sm),
          _buildCredentialRow('Email:', 'admin@trustbank.com'),
          _buildCredentialRow('Contraseña:', 'admin123'),
          const SizedBox(height: TBSpacing.xs),
          Text(
            'Usa estas credenciales para acceder al panel administrativo',
            style: TBTypography.bodySmall.copyWith(
              color: TBColors.grey600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TBTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TBTypography.bodySmall.copyWith(
              fontFamily: 'monospace',
              color: TBColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}