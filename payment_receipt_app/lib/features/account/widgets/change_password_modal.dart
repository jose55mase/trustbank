import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_input.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';
import '../../../design_system/components/molecules/tb_loading_overlay.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class ChangePasswordModal extends StatefulWidget {
  const ChangePasswordModal({super.key});

  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: TBColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: TBSpacing.lg,
          right: TBSpacing.lg,
          top: TBSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + TBSpacing.lg,
        ),
        child: Form(
          key: _formKey,
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
                'Cambiar Contraseña',
                style: TBTypography.headlineSmall,
              ),
              const SizedBox(height: TBSpacing.md),
              Text(
                'Para tu seguridad, necesitamos verificar tu identidad antes de cambiar tu contraseña.',
                style: TBTypography.bodyMedium.copyWith(
                  color: TBColors.grey600,
                ),
              ),
              const SizedBox(height: TBSpacing.lg),
              TBInput(
                label: 'Contraseña actual',
                hint: 'Ingresa tu contraseña actual',
                controller: _currentPasswordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              const SizedBox(height: TBSpacing.md),
              TBInput(
                label: 'Nueva contraseña',
                hint: 'Ingresa tu nueva contraseña',
                controller: _newPasswordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock),
              ),
              const SizedBox(height: TBSpacing.md),
              TBInput(
                label: 'Confirmar nueva contraseña',
                hint: 'Confirma tu nueva contraseña',
                controller: _confirmPasswordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock),
              ),
              const SizedBox(height: TBSpacing.sm),
              Text(
                'La contraseña debe tener al menos 6 caracteres',
                style: TBTypography.bodySmall.copyWith(
                  color: TBColors.grey600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: TBButton(
                      text: 'Cancelar',
                      type: TBButtonType.outline,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: TBSpacing.md),
                  Expanded(
                    child: TBButton(
                      text: 'Cambiar',
                      onPressed: _changePassword,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_validateForm()) return;

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          TBDialogHelper.showError(
            context,
            title: 'Error',
            message: 'No se pudo obtener la información del usuario',
          );
        }
        return;
      }

      if (mounted) {
        await TBLoadingOverlay.showWithDelay(
          context,
          _performPasswordChange(user['email']),
          message: 'Cambiando contraseña...',
          minDelayMs: 1500,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        TBDialogHelper.showSuccess(
          context,
          title: '¡Contraseña actualizada!',
          message: 'Tu contraseña ha sido cambiada exitosamente.',
        );
      }
    } catch (e) {
      if (mounted) {
        TBDialogHelper.showError(
          context,
          title: 'Error al cambiar contraseña',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _performPasswordChange(String email) async {
    await ApiService.changePassword(
      email: email,
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
  }

  bool _validateForm() {
    if (_currentPasswordController.text.isEmpty) {
      TBDialogHelper.showWarning(
        context,
        title: 'Campo requerido',
        message: 'Ingresa tu contraseña actual',
      );
      return false;
    }

    if (_newPasswordController.text.isEmpty) {
      TBDialogHelper.showWarning(
        context,
        title: 'Campo requerido',
        message: 'Ingresa tu nueva contraseña',
      );
      return false;
    }

    if (_newPasswordController.text.length < 6) {
      TBDialogHelper.showWarning(
        context,
        title: 'Contraseña muy corta',
        message: 'La nueva contraseña debe tener al menos 6 caracteres',
      );
      return false;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      TBDialogHelper.showWarning(
        context,
        title: 'Contraseñas no coinciden',
        message: 'La nueva contraseña y su confirmación deben ser iguales',
      );
      return false;
    }

    if (_currentPasswordController.text == _newPasswordController.text) {
      TBDialogHelper.showWarning(
        context,
        title: 'Contraseña igual',
        message: 'La nueva contraseña debe ser diferente a la actual',
      );
      return false;
    }

    return true;
  }
}