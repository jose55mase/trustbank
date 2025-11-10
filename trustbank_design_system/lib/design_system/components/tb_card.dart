import 'package:flutter/material.dart';
import '../colors/tb_colors.dart';
import '../spacing/tb_spacing.dart';

enum TBCardType { elevated, outlined, filled }

class TBCard extends StatelessWidget {
  final Widget child;
  final TBCardType type;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const TBCard({
    super.key,
    required this.child,
    this.type = TBCardType.elevated,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Material(
        color: _getBackgroundColor(),
        elevation: _getElevation(),
        shadowColor: TBColors.black.withOpacity(0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(TBSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(TBSpacing.radiusMd),
          child: Container(
            decoration: _getDecoration(),
            padding: padding ?? const EdgeInsets.all(TBSpacing.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;
    
    switch (type) {
      case TBCardType.elevated:
        return TBColors.surface;
      case TBCardType.outlined:
        return TBColors.surface;
      case TBCardType.filled:
        return TBColors.surfaceVariant;
    }
  }

  double _getElevation() {
    if (elevation != null) return elevation!;
    
    switch (type) {
      case TBCardType.elevated:
        return TBSpacing.elevationMd;
      case TBCardType.outlined:
      case TBCardType.filled:
        return 0;
    }
  }

  BoxDecoration? _getDecoration() {
    switch (type) {
      case TBCardType.outlined:
        return BoxDecoration(
          border: Border.all(
            color: TBColors.grey300,
            width: 1,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(TBSpacing.radiusMd),
        );
      default:
        return null;
    }
  }
}