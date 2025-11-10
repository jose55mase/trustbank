import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';
import '../../spacing/tb_spacing.dart';
import '../molecules/login_header.dart';
import '../molecules/login_form.dart';

class LoginCard extends StatelessWidget {
  final Function(String email, String password) onLogin;
  final bool isLoading;
  final String? errorMessage;

  const LoginCard({
    super.key,
    required this.onLogin,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const LoginHeader(),
          const SizedBox(height: TBSpacing.xxl),
          LoginForm(
            onSubmit: onLogin,
            isLoading: isLoading,
            errorMessage: errorMessage,
          ),
        ],
      ),
    );
  }
}