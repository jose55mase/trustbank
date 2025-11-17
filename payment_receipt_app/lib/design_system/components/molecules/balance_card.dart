import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';
import '../../typography/tb_typography.dart';
import '../../spacing/tb_spacing.dart';

class BalanceCard extends StatelessWidget {
  final String balance;
  final bool showBalance;
  final VoidCallback? onToggleVisibility;

  const BalanceCard({
    super.key,
    required this.balance,
    this.showBalance = true,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TBSpacing.lg),
      decoration: BoxDecoration(
        gradient: TBColors.primaryAccentGradient,
        borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: TBColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo disponible',
                style: TBTypography.labelMedium.copyWith(
                  color: TBColors.white.withOpacity(0.8),
                ),
              ),
              if (onToggleVisibility != null)
                IconButton(
                  onPressed: onToggleVisibility,
                  icon: Icon(
                    showBalance ? Icons.visibility : Icons.visibility_off,
                    color: TBColors.white.withOpacity(0.8),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: TBSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'USD',
                style: TBTypography.titleLarge.copyWith(
                  color: TBColors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: TBSpacing.xs),
              Expanded(
                child: Text(
                  showBalance ? balance : '••••••',
                  style: TBTypography.displayLarge.copyWith(
                    color: TBColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}