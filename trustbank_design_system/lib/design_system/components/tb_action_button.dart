import 'package:flutter/material.dart';
import '../colors/tb_colors.dart';
import '../typography/tb_typography.dart';
import '../spacing/tb_spacing.dart';

class TBActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const TBActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TBSpacing.md,
          vertical: TBSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? TBColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor ?? TBColors.white,
              size: 20,
            ),
            const SizedBox(width: TBSpacing.xs),
            Text(
              label,
              style: TBTypography.labelMedium.copyWith(
                color: textColor ?? TBColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}