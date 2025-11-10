import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';
import '../../typography/tb_typography.dart';
import '../../spacing/tb_spacing.dart';

class Transaction {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final bool isIncome;

  Transaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    this.isIncome = false,
  });
}

class RecentTransactions extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback? onSeeAll;

  const RecentTransactions({
    super.key,
    required this.transactions,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Movimientos recientes',
              style: TBTypography.titleLarge.copyWith(
                color: TBColors.black,
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  'Ver todos',
                  style: TBTypography.labelMedium.copyWith(
                    color: TBColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: TBSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: TBSpacing.sm),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Container(
              padding: const EdgeInsets.all(TBSpacing.md),
              decoration: BoxDecoration(
                color: TBColors.surface,
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                border: Border.all(color: TBColors.grey300.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: transaction.isIncome 
                          ? TBColors.success.withOpacity(0.1)
                          : TBColors.grey100,
                      borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                    ),
                    child: Icon(
                      transaction.icon,
                      color: transaction.isIncome ? TBColors.success : TBColors.grey600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: TBSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: TBTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          transaction.subtitle,
                          style: TBTypography.labelMedium.copyWith(
                            color: TBColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${transaction.isIncome ? '+' : '-'}\$${transaction.amount}',
                    style: TBTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: transaction.isIncome ? TBColors.success : TBColors.black,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}