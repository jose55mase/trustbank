import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../widgets/register_form.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/screens/home_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
                }
              },
              builder: (context, state) {
                return Center(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(TBSpacing.screenPadding),
                      padding: const EdgeInsets.all(TBSpacing.xl),
                      decoration: BoxDecoration(
                        color: TBColors.surface,
                        borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: TBColors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: TBColors.primaryGradient,
                              borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                            ),
                            child: const Icon(
                              Icons.person_add,
                              color: TBColors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: TBSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logobanklettersblak.png',
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: TBSpacing.xs),
                              Text(
                                'TrustBank',
                                style: TBTypography.headlineMedium.copyWith(
                                  color: TBColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TBSpacing.sm),
                          Text(
                            'Crear cuenta',
                            style: TBTypography.headlineMedium.copyWith(
                              color: TBColors.primary,
                            ),
                          ),
                          const SizedBox(height: TBSpacing.sm),
                          Text(
                            'Únete a TrustBank',
                            style: TBTypography.bodyLarge.copyWith(
                              color: TBColors.grey600,
                            ),
                          ),
                          const SizedBox(height: TBSpacing.xl),
                          RegisterForm(
                            onSuccess: () {
                              Navigator.of(context).pop();
                            },
                            errorMessage: state is AuthError ? state.message : null,
                          ),
                          const SizedBox(height: TBSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '¿Ya tienes cuenta? ',
                                style: TBTypography.bodyMedium.copyWith(
                                  color: TBColors.grey600,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Iniciar sesión',
                                  style: TBTypography.bodyMedium.copyWith(
                                    color: TBColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}