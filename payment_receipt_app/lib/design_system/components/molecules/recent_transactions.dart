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
  final String type;
  final DateTime date;

  Transaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    this.isIncome = false,
    this.type = 'INCOME',
    required this.date,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Ayer';
    } else if (difference < 7) {
      return 'Hace $difference días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

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
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TBColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: TBColors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: TBColors.grey200.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: transaction.isIncome 
                            ? [TBColors.success.withOpacity(0.8), TBColors.success]
                            : [TBColors.error.withOpacity(0.8), TBColors.error],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (transaction.isIncome ? TBColors.success : TBColors.error).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      transaction.icon,
                      color: TBColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: TBSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: TBTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: TBColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transaction.subtitle,
                          style: TBTypography.bodySmall.copyWith(
                            color: TBColors.grey600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${transaction.isIncome ? '+' : '-'}\$${transaction.amount}',
                        style: TBTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: transaction.isIncome ? TBColors.success : TBColors.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(transaction.date),
                        style: TBTypography.labelSmall.copyWith(
                          color: TBColors.grey500,
                        ),
                      ),
                    ],
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