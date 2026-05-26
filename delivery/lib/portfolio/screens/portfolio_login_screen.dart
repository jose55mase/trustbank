import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/portfolio_providers.dart';
import '../router/portfolio_routes.dart';
import '../theme/portfolio_theme.dart';

/// Login screen for the portfolio admin panel.
///
/// Features:
/// - Email/username and password fields
/// - Generic error messages on failure (does not reveal which field is wrong)
/// - Lockout countdown when account is locked after 5 failed attempts
/// - Redirects to original route after successful login
///
/// Validates: Requirements 4.1, 4.2, 4.3, 4.5
class PortfolioLoginScreen extends ConsumerStatefulWidget {
  const PortfolioLoginScreen({super.key});

  @override
  ConsumerState<PortfolioLoginScreen> createState() =>
      _PortfolioLoginScreenState();
}

class _PortfolioLoginScreenState extends ConsumerState<PortfolioLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    // Read returnTo query parameter and set it as redirectAfterLogin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setRedirectFromUrl();
    });
  }

  void _setRedirectFromUrl() {
    final uri = GoRouterState.of(context).uri;
    final returnTo = uri.queryParameters['returnTo'];
    if (returnTo != null && returnTo.isNotEmpty) {
      ref
          .read(portfolioAuthProvider.notifier)
          .setRedirectAfterLogin(returnTo);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authNotifier = ref.read(portfolioAuthProvider.notifier);
    final authState = ref.read(portfolioAuthProvider);

    // Check if currently locked out
    if (authState.isLockedOut) {
      _startLockoutCountdown();
      return;
    }

    // Capture redirect path before login (login clears it on success)
    final redirectPath =
        authState.redirectAfterLogin ?? PortfolioRoutes.admin;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await authNotifier.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      context.go(redirectPath);
    } else {
      // Check if account got locked after this attempt
      final updatedState = ref.read(portfolioAuthProvider);
      if (updatedState.isLockedOut) {
        _startLockoutCountdown();
      } else {
        setState(() {
          _errorMessage = 'Credenciales incorrectas';
        });
      }
    }
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _updateLockoutMessage();

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _lockoutTimer?.cancel();
        return;
      }
      final authState = ref.read(portfolioAuthProvider);
      if (!authState.isLockedOut) {
        _lockoutTimer?.cancel();
        setState(() {
          _errorMessage = null;
        });
      } else {
        _updateLockoutMessage();
      }
    });
  }

  void _updateLockoutMessage() {
    final authState = ref.read(portfolioAuthProvider);
    if (authState.lockoutUntil != null) {
      final remaining =
          authState.lockoutUntil!.difference(DateTime.now());
      if (remaining.isNegative) {
        setState(() {
          _errorMessage = null;
        });
        _lockoutTimer?.cancel();
      } else {
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;
        setState(() {
          if (minutes > 0) {
            _errorMessage =
                'Cuenta bloqueada. Intente de nuevo en $minutes minutos';
          } else {
            _errorMessage =
                'Cuenta bloqueada. Intente de nuevo en $seconds segundos';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(portfolioAuthProvider);
    final isLockedOut = authState.isLockedOut;

    return Theme(
      data: PortfolioTheme.lightTheme,
      child: Scaffold(
        backgroundColor: PortfolioTheme.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      'Panel Administrativo',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: PortfolioTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesión para gestionar tu portafolio',
                      style: TextStyle(
                        fontSize: 14,
                        color: PortfolioTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PortfolioTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PortfolioTheme.error.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: PortfolioTheme.error,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Username field
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !isLockedOut && !_isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese su correo electrónico';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outlined),
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      enabled: !isLockedOut && !_isLoading,
                      onFieldSubmitted: (_) => _handleLogin(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            (isLockedOut || _isLoading) ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PortfolioTheme.primaryBlue,
                          foregroundColor: PortfolioTheme.accentBlack,
                          disabledBackgroundColor:
                              PortfolioTheme.primaryBlue.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: PortfolioTheme.accentBlack,
                                ),
                              )
                            : const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
