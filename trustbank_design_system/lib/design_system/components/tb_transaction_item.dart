import 'package:flutter/material.dart';
import '../colors/tb_colors.dart';
import '../typography/tb_typography.dart';
import '../spacing/tb_spacing.dart';

enum TBTransactionType { income, expense, transfer }

class TBTransactionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final TBTransactionType type;
  final IconData? icon;
  final VoidCallback? onTap;

  const TBTransactionItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.type,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TBSpacing.md),
        margin: const EdgeInsets.symmetric(vertical: TBSpacing.xs),
        decoration: BoxDecoration(
          color: TBColors.surface,
          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
          border: Border.all(color: TBColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(),
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
              ),
              child: Icon(
                icon ?? _getDefaultIcon(),
                color: _getIconColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: TBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TBTypography.titleMedium.copyWith(
                      color: TBColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: TBSpacing.xs),
                  Text(
                    subtitle,
                    style: TBTypography.bodySmall.copyWith(
                      color: TBColors.grey600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(),
                  style: TBTypography.titleMedium.copyWith(
                    color: _getAmountColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: TBSpacing.xs),
                Text(
                  date,
                  style: TBTypography.bodySmall.copyWith(
                    color: TBColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case TBTransactionType.income:
        return Icons.arrow_downward;
      case TBTransactionType.expense:
        return Icons.arrow_upward;
      case TBTransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  Color _getIconBackgroundColor() {
    switch (type) {
      case TBTransactionType.income:
        return TBColors.success.withOpacity(0.1);
      case TBTransactionType.expense:
        return TBColors.error.withOpacity(0.1);
      case TBTransactionType.transfer:
        return TBColors.info.withOpacity(0.1);
    }
  }

  Color _getIconColor() {
    switch (type) {
      case TBTransactionType.income:
        return TBColors.success;
      case TBTransactionType.expense:
        return TBColors.error;
      case TBTransactionType.transfer:
        return TBColors.info;
    }
  }

  Color _getAmountColor() {
    switch (type) {
      case TBTransactionType.income:
        return TBColors.success;
      case TBTransactionType.expense:
        return TBColors.error;
      case TBTransactionType.transfer:
        return TBColors.black;
    }
  }

  String _formatAmount() {
    switch (type) {
      case TBTransactionType.income:
        return '+$amount';
      case TBTransactionType.expense:
        return '-$amount';
      case TBTransactionType.transfer:
        return amount;
    }
  }
}