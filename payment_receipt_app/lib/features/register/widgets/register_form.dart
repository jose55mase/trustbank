import 'package:flutter/material.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_input.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';

class RegisterForm extends StatefulWidget {
  final Function(String name, String email, String phone, String password) onSubmit;
  final bool isLoading;
  final String? errorMessage;

  const RegisterForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TBInput(
          label: 'Nombre completo',
          hint: 'Ingresa tu nombre',
          controller: _nameController,
          prefixIcon: const Icon(Icons.person_outline),
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
          isLoading: widget.isLoading,
          onPressed: () {
            if (_validateForm()) {
              widget.onSubmit(
                _nameController.text,
                _emailController.text,
                _phoneController.text,
                _passwordController.text,
              );
            }
          },
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

  bool _validateForm() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}