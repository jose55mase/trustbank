import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/auth.dart';
import '../../providers/auth_providers.dart';

/// Pantalla de inicio de sesión para Repartidores y Administradores.
/// Permite seleccionar el tipo de usuario, ingresar credenciales y
/// redirige al panel correspondiente tras un login exitoso.
///
/// Requisitos: 5.1, 5.2, 5.3, 5.4
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();

  TipoUsuario _tipoUsuario = TipoUsuario.repartidor;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.login(
        _usuarioController.text.trim(),
        _passwordController.text,
        _tipoUsuario,
      );

      if (!mounted) return;

      if (result.exitoso) {
        // Invalidate session provider and wait for it to resolve
        // so the router guard sees the new session
        ref.invalidate(sesionActivaProvider);
        await ref.read(sesionActivaProvider.future);

        if (!mounted) return;

        // Redirect based on role (Req 5.2, 5.3)
        if (result.tipo == TipoUsuario.repartidor) {
          context.go('/repartidor');
        } else {
          context.go('/admin');
        }
      } else {
        // Show error for invalid credentials (Req 5.4)
        setState(() {
          _isLoading = false;
          _errorMessage = result.mensaje ?? 'Credenciales incorrectas';
        });
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header icon
                const Icon(
                  Icons.delivery_dining,
                  size: 64,
                  color: AppTheme.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bienvenido',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona tu rol e ingresa tus credenciales',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),

                // User type selector (Req 5.1)
                SegmentedButton<TipoUsuario>(
                  segments: const [
                    ButtonSegment<TipoUsuario>(
                      value: TipoUsuario.repartidor,
                      label: Text('Repartidor'),
                      icon: Icon(Icons.delivery_dining),
                    ),
                    ButtonSegment<TipoUsuario>(
                      value: TipoUsuario.administrador,
                      label: Text('Administrador'),
                      icon: Icon(Icons.admin_panel_settings),
                    ),
                  ],
                  selected: {_tipoUsuario},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _tipoUsuario = selection.first;
                      _errorMessage = null;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primary;
                      }
                      return AppTheme.surfaceVariant;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.textPrimary;
                      }
                      return AppTheme.textSecondary;
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // Username field
                TextFormField(
                  controller: _usuarioController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El usuario es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Error message (Req 5.4)
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.error.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),

                // Login button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.textPrimary,
                            ),
                          )
                        : const Text('Iniciar Sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
