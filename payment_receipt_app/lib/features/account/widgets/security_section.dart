import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import 'change_password_modal.dart';

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TBColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(TBSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: TBColors.primary,
                  size: 20,
                ),
                const SizedBox(width: TBSpacing.sm),
                Text(
                  'Seguridad',
                  style: TBTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildSecurityItem(
            context,
            icon: Icons.lock_outline,
            title: 'Cambiar contraseña',
            subtitle: 'Actualiza tu contraseña de acceso',
            onTap: () => _showChangePassword(context),
          ),
          _buildDivider(),
          _buildSecurityItem(
            context,
            icon: Icons.fingerprint,
            title: 'Autenticación biométrica',
            subtitle: 'Huella dactilar y Face ID',
            onTap: () => _showBiometricSettings(context),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: TBColors.primary,
            ),
          ),
          _buildDivider(),
          _buildSecurityItem(
            context,
            icon: Icons.phone_android,
            title: 'Dispositivos autorizados',
            subtitle: 'Gestiona tus dispositivos de confianza',
            onTap: () => _showDevices(context),
          ),
          _buildDivider(),
          _buildSecurityItem(
            context,
            icon: Icons.history,
            title: 'Actividad reciente',
            subtitle: 'Ver inicios de sesión y actividad',
            onTap: () => _showActivity(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TBSpacing.md,
          vertical: TBSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TBColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: TBColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: TBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TBTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TBTypography.bodySmall.copyWith(
                      color: TBColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right,
              color: TBColors.grey500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.md),
      child: Divider(
        height: 1,
        color: TBColors.grey300.withOpacity(0.5),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChangePasswordModal(),
    );
  }

  void _showBiometricSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: TBColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TBSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TBColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: TBSpacing.lg),
              Text(
                'Autenticación Biométrica',
                style: TBTypography.headlineSmall,
              ),
              const SizedBox(height: TBSpacing.md),
              _buildBiometricOption(
                'Huella dactilar',
                'Usa tu huella para acceder rápidamente',
                Icons.fingerprint,
                true,
              ),
              const SizedBox(height: TBSpacing.md),
              _buildBiometricOption(
                'Face ID',
                'Reconocimiento facial para mayor seguridad',
                Icons.face,
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricOption(String title, String subtitle, IconData icon, bool enabled) {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: TBColors.primary),
          const SizedBox(width: TBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TBTypography.bodySmall.copyWith(color: TBColors.grey600)),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) {},
            activeColor: TBColors.primary,
          ),
        ],
      ),
    );
  }

  void _showDevices(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: TBColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TBSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TBColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: TBSpacing.lg),
              Text(
                'Dispositivos Autorizados',
                style: TBTypography.headlineSmall,
              ),
              const SizedBox(height: TBSpacing.md),
              _buildDeviceItem('iPhone 15 Pro', 'Este dispositivo', Icons.phone_iphone, true),
              _buildDeviceItem('MacBook Pro', 'Último acceso: Hace 2 días', Icons.laptop_mac, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceItem(String name, String subtitle, IconData icon, bool current) {
    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.sm),
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: current ? TBColors.primary.withOpacity(0.1) : TBColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: current ? Border.all(color: TBColors.primary.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: current ? TBColors.primary : TBColors.grey600),
          const SizedBox(width: TBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TBTypography.bodySmall.copyWith(color: TBColors.grey600)),
              ],
            ),
          ),
          if (current)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TBColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Actual',
                style: TBTypography.labelSmall.copyWith(color: TBColors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _showActivity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: TBColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TBSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TBColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: TBSpacing.lg),
              Text(
                'Actividad Reciente',
                style: TBTypography.headlineSmall,
              ),
              const SizedBox(height: TBSpacing.md),
              _buildActivityItem('Inicio de sesión', 'Hoy, 10:30 AM', Icons.login, TBColors.success),
              _buildActivityItem('Cambio de contraseña', 'Hace 3 días', Icons.lock, TBColors.primary),
              _buildActivityItem('Nuevo dispositivo', 'Hace 1 semana', Icons.phone_android, Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.sm),
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: TBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(time, style: TBTypography.bodySmall.copyWith(color: TBColors.grey600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}