import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';
import '../../typography/tb_typography.dart';
import '../../spacing/tb_spacing.dart';
import '../../utils/tb_responsive.dart';

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
    final columns = TBResponsive.actionGridColumns(context);
    final aspectRatio = TBResponsive.actionGridAspectRatio(context);
    final containerSize = TBResponsive.iconContainerSize(context);
    final iconSz = TBResponsive.iconSize(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: TBSpacing.md,
        mainAxisSpacing: TBSpacing.md,
        childAspectRatio: aspectRatio,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final isAccent = index % 3 == 1;
        final bgColor = isAccent ? TBColors.accent.withOpacity(0.1) : TBColors.primary.withOpacity(0.1);
        final iconColor = isAccent ? TBColors.accentDark : TBColors.primary;
        
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
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                  ),
                  child: Icon(
                    action.icon,
                    color: iconColor,
                    size: iconSz,
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
