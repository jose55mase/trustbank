import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';
import '../../typography/tb_typography.dart';
import '../../spacing/tb_spacing.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: TBColors.primaryGradient,
            borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: TBColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: TBColors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: TBSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logobanklettersblak.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: TBSpacing.sm),
            Text(
              'TrustBank',
              style: TBTypography.displayLarge.copyWith(
                color: TBColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: TBSpacing.sm),
        Text(
          'Tu dinero, siempre seguro',
          style: TBTypography.bodyLarge.copyWith(
            color: TBColors.grey600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}