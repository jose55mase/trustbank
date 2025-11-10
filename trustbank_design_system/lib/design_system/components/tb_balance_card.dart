import 'package:flutter/material.dart';
import '../colors/tb_colors.dart';
import '../typography/tb_typography.dart';
import '../spacing/tb_spacing.dart';

class TBBalanceCard extends StatelessWidget {
  final String balance;
  final String currency;
  final String? subtitle;
  final bool showBalance;
  final VoidCallback? onToggleVisibility;
  final List<Widget>? actions;

  const TBBalanceCard({
    super.key,
    required this.balance,
    this.currency = 'COP',
    this.subtitle,
    this.showBalance = true,
    this.onToggleVisibility,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TBSpacing.lg),
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
                currency,
                style: TBTypography.titleMedium.copyWith(
                  color: TBColors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: TBSpacing.xs),
              Expanded(
                child: Text(
                  showBalance ? balance : '••••••',
                  style: TBTypography.displayMedium.copyWith(
                    color: TBColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: TBSpacing.xs),
            Text(
              subtitle!,
              style: TBTypography.bodySmall.copyWith(
                color: TBColors.white.withOpacity(0.7),
              ),
            ),
          ],
          if (actions != null) ...[
            const SizedBox(height: TBSpacing.lg),
            Row(
              children: actions!
                  .expand((action) => [action, const SizedBox(width: TBSpacing.sm)])
                  .take(actions!.length * 2 - 1)
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}