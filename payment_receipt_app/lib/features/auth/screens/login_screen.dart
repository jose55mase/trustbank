import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/components/organisms/login_card.dart';
import '../bloc/auth_bloc.dart';
import '../../../services/auth_service.dart';
import '../../../services/admin_setup_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';
import '../../../design_system/components/molecules/tb_loading_overlay.dart';
import '../../home/screens/home_screen.dart';
import '../../register/screens/register_screen.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6C63FF),
                Color(0xFF9C96FF),
                Color(0xFFE8E6FF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthAuthenticated) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                } else if (state is AccountSuspended) {
                  TBDialogHelper.showError(
                    context,
                    title: 'Cuenta Suspendida',
                    message: state.message,
                  );
                }
              },
              builder: (context, state) {
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoginCard(
                          onLogin: (email, password) async {
                            try {
                              final result = await TBLoadingOverlay.showWithDelay(
                                context,
                                _performLogin(email, password),
                                message: 'Iniciando sesión...',
                                minDelayMs: 2000,
                              );
                              
                              if (result['success']) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                                );
                              } else {
                                TBDialogHelper.showError(
                                  context,
                                  title: 'Error de autenticación',
                                  message: result['error'] ?? 'Error desconocido',
                                );
                              }
                            } catch (e) {
                              TBDialogHelper.showError(
                                context,
                                title: 'Error de conexión',
                                message: 'No se pudo conectar con el servidor',
                              );
                            }
                          },
                          isLoading: state is AuthLoading,
                          errorMessage: state is AuthError ? state.message : 
                                       state is AccountSuspended ? state.message : null,
                        ),
                        const SizedBox(height: TBSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿No tienes cuenta? ',
                              style: TBTypography.bodyMedium.copyWith(
                                color: TBColors.white.withOpacity(0.8),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Regístrate',
                                style: TBTypography.bodyMedium.copyWith(
                                  color: TBColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TBSpacing.lg),
                        //const AdminCredentialsInfo(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Future<Map<String, dynamic>> _performLogin(String email, String password) async {
    // Crear admin por defecto si no existe
    await AdminSetupService.createDefaultAdmin();
    
    // Verificar si es el admin por defecto
    final isDefaultAdmin = await AdminSetupService.isDefaultAdmin(email, password);
    
    if (isDefaultAdmin) {
      final admin = await AdminSetupService.getDefaultAdmin();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(admin));
      await prefs.setBool('is_logged_in', true);
      return {'success': true};
    }
    
    // Login normal para otros usuarios
    return await AuthService.login(email, password);
  }
}