import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/account_model.dart';

class AccountStatusCard extends StatelessWidget {
  final UserAccount account;
  final Map<String, dynamic>? userData;

  const AccountStatusCard({super.key, required this.account, this.userData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TBSpacing.lg),
      decoration: BoxDecoration(
        gradient: _getStatusGradient(),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: TBColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getStatusIcon(), color: TBColors.white, size: 24),
              const SizedBox(width: TBSpacing.sm),
              Text(
                account.statusLabel,
                style: TBTypography.titleLarge.copyWith(
                  color: TBColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: TBSpacing.sm),
          Text(
            userData != null 
                ? '${userData!['fistName'] ?? userData!['firstName'] ?? ''} ${userData!['lastName'] ?? ''}'
                : account.userName,
            style: TBTypography.headlineMedium.copyWith(color: TBColors.white),
          ),
          Text(
            userData?['email'] ?? account.email,
            style: TBTypography.bodyMedium.copyWith(
              color: TBColors.white.withOpacity(0.9),
            ),
          ),
          if (userData != null) const SizedBox(height: TBSpacing.xs),
          if (userData != null)
            Text(
              'ID: ${userData!['id']} • Doc: ${userData!['document'] ?? 'N/A'}',
              style: TBTypography.labelMedium.copyWith(
                color: TBColors.white.withOpacity(0.8),
              ),
            ),
          const SizedBox(height: TBSpacing.md),
          Text(
            userData != null 
                ? _getRealStatusMessage(userData!['accountStatus'])
                : _getStatusMessage(),
            style: TBTypography.bodyMedium.copyWith(
              color: TBColors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getStatusGradient() {
    switch (account.status) {
      case AccountStatus.verified:
        return const LinearGradient(
          colors: [TBColors.success, Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AccountStatus.rejected:
        return const LinearGradient(
          colors: [TBColors.error, Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AccountStatus.suspended:
        return const LinearGradient(
          colors: [TBColors.grey600, TBColors.grey500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return TBColors.primaryGradient;
    }
  }

  IconData _getStatusIcon() {
    switch (account.status) {
      case AccountStatus.verified:
        return Icons.verified_user;
      case AccountStatus.rejected:
        return Icons.cancel;
      case AccountStatus.suspended:
        return Icons.block;
      default:
        return Icons.pending;
    }
  }

  String _getStatusMessage() {
    switch (account.status) {
      case AccountStatus.verified:
        return 'Tu cuenta está completamente verificada. Puedes usar todos los servicios.';
      case AccountStatus.rejected:
        return 'Tu cuenta fue rechazada. Revisa los documentos y vuelve a intentar.';
      case AccountStatus.suspended:
        return 'Tu cuenta está suspendida. Contacta soporte para más información.';
      default:
        return 'Sube todos los documentos requeridos para verificar tu cuenta.';
    }
  }
  
  String _getRealStatusMessage(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return 'Tu cuenta está activa. Puedes usar todos los servicios.';
      case 'SUSPENDED':
        return 'Tu cuenta está suspendida. Contacta soporte para más información.';
      case 'INACTIVE':
        return 'Tu cuenta está inactiva. Contacta al administrador.';
      case 'PENDING':
        return 'Tu cuenta está pendiente de verificación.';
      default:
        return 'Estado de cuenta: ${status ?? 'No especificado'}';
    }
  }
}