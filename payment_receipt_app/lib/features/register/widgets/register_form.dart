import 'package:flutter/material.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_input.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';
import '../../../design_system/components/molecules/tb_loading_overlay.dart';
import '../../../services/register_service.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback? onSuccess;
  final String? errorMessage;

  const RegisterForm({
    super.key,
    this.onSuccess,
    this.errorMessage,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TBInput(
          label: 'Nombre',
          hint: 'Ingresa tu nombre',
          controller: _firstNameController,
          prefixIcon: const Icon(Icons.person_outline),
        ),
        const SizedBox(height: TBSpacing.md),
        TBInput(
          label: 'Apellido',
          hint: 'Ingresa tu apellido',
          controller: _lastNameController,
          prefixIcon: const Icon(Icons.person_outline),
        ),
        const SizedBox(height: TBSpacing.md),
        TBInput(
          label: 'Nombre de usuario',
          hint: 'Elige un nombre de usuario',
          controller: _usernameController,
          prefixIcon: const Icon(Icons.alternate_email),
        ),
        const SizedBox(height: TBSpacing.md),
        TBInput(
          label: 'Email',
          hint: 'correo@ejemplo.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        const SizedBox(height: TBSpacing.md),
        TBInput(
          label: 'Teléfono',
          hint: '+1 234 567 8900',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
        const SizedBox(height: TBSpacing.md),
        TBInput(
          label: 'Contraseña',
          hint: 'Mínimo 6 caracteres',
          controller: _passwordController,
          obscureText: _obscurePassword,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        const SizedBox(height: TBSpacing.md),
        TBInput(
          label: 'Confirmar contraseña',
          hint: 'Repite tu contraseña',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
        const SizedBox(height: TBSpacing.xl),
        TBButton(
          text: 'Crear cuenta',
          fullWidth: true,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleSubmit,
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: TBSpacing.md),
          Text(
            widget.errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await TBLoadingOverlay.showWithDelay(
        context,
        RegisterService.registerUser(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        ),
        message: 'Creando tu cuenta...',
        minDelayMs: 2500,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          TBDialogHelper.showSuccess(
            context,
            title: '¡Registro exitoso!',
            message: 'Tu cuenta ha sido creada correctamente. Ya puedes iniciar sesión.',
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onSuccess != null) {
                widget.onSuccess!();
              } else {
                Navigator.of(context).pop();
              }
            },
          );
        } else {
          String errorMessage = result['error'] ?? 'No se pudo crear la cuenta';
          String title = 'Error en el registro';
          
          if (errorMessage.contains('email ya está registrado')) {
            title = 'Email en uso';
            errorMessage = 'Este email ya está registrado. Intenta con otro email o inicia sesión.';
          } else if (errorMessage.contains('nombre de usuario ya está en uso')) {
            title = 'Username en uso';
            errorMessage = 'Este nombre de usuario ya está en uso. Elige otro nombre de usuario.';
          }
          
          TBDialogHelper.showError(
            context,
            title: title,
            message: errorMessage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        TBDialogHelper.showError(
          context,
          title: 'Error de conexión',
          message: 'No se pudo conectar con el servidor. Intenta nuevamente.',
        );
      }
    }
  }

  bool _validateForm() {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.length < 6 ||
        _passwordController.text != _confirmPasswordController.text) {
      if (_passwordController.text != _confirmPasswordController.text) {
        TBDialogHelper.showError(
          context,
          title: 'Contraseñas no coinciden',
          message: 'Las contraseñas ingresadas no son iguales. Por favor, verifica e intenta nuevamente.',
        );
      } else if (_passwordController.text.length < 6) {
        TBDialogHelper.showWarning(
          context,
          title: 'Contraseña muy corta',
          message: 'La contraseña debe tener al menos 6 caracteres para mayor seguridad.',
        );
      } else {
        TBDialogHelper.showWarning(
          context,
          title: 'Campos incompletos',
          message: 'Por favor, completa todos los campos requeridos para continuar con el registro.',
        );
      }
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}