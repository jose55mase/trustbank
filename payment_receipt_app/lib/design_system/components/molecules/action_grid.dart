import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';
import '../../typography/tb_typography.dart';
import '../../spacing/tb_spacing.dart';

class ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class ActionGrid extends StatelessWidget {
  final List<ActionItem> actions;

  const ActionGrid({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: TBSpacing.md,
        mainAxisSpacing: TBSpacing.md,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: action.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: TBColors.surface,
              borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: TBColors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: TBColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                  ),
                  child: Icon(
                    action.icon,
                    color: TBColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: TBSpacing.sm),
                Text(
                  action.label,
                  style: TBTypography.labelMedium.copyWith(
                    color: TBColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}