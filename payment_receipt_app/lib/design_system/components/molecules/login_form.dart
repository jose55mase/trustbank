import 'package:flutter/material.dart';
import '../../spacing/tb_spacing.dart';
import '../atoms/tb_input.dart';
import '../atoms/tb_button.dart';

class LoginForm extends StatefulWidget {
  final Function(String email, String password) onSubmit;
  final bool isLoading;
  final String? errorMessage;

  const LoginForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TBInput(
            label: 'Email o número de celular',
            hint: 'Ingresa tu email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          const SizedBox(height: TBSpacing.lg),
          TBInput(
            label: 'Contraseña',
            hint: 'Ingresa tu contraseña',
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
          const SizedBox(height: TBSpacing.xl),
          TBButton(
            text: 'Iniciar sesión',
            fullWidth: true,
            isLoading: widget.isLoading,
            onPressed: () {
              if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                widget.onSubmit(_emailController.text, _passwordController.text);
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
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}