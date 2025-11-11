import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/spacing/tb_spacing.dart';

class LoadingHome extends StatelessWidget {
  const LoadingHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Balance card skeleton
        Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: TBColors.grey200,
            borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: TBColors.primary),
          ),
        ),
        const SizedBox(height: TBSpacing.lg),
        // Actions grid skeleton
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 5,
          crossAxisSpacing: TBSpacing.xs,
          mainAxisSpacing: TBSpacing.sm,
          childAspectRatio: 0.7,
          children: List.generate(5, (index) => Container(
            decoration: BoxDecoration(
              color: TBColors.grey200,
              borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
            ),
          )),
        ),
        const SizedBox(height: TBSpacing.lg),
        // Transactions skeleton
        ...List.generate(2, (index) => Padding(
          padding: const EdgeInsets.only(bottom: TBSpacing.sm),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: TBColors.grey200,
              borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
            ),
          ),
        )),
      ],
    );
  }
}