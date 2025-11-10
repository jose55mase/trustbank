import 'package:flutter/material.dart';
import '../colors/tb_colors.dart';
import '../typography/tb_typography.dart';
import '../spacing/tb_spacing.dart';

enum TBButtonType { primary, secondary, outline, ghost }
enum TBButtonSize { small, medium, large }

class TBButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final TBButtonType type;
  final TBButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final bool fullWidth;

  const TBButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = TBButtonType.primary,
    this.size = TBButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _getHeight(),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _getButtonStyle(),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_getLoadingColor()),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: TBSpacing.sm),
                  ],
                  Text(text, style: _getTextStyle()),
                ],
              ),
      ),
    );
  }

  double _getHeight() {
    switch (size) {
      case TBButtonSize.small:
        return 36;
      case TBButtonSize.medium:
        return 48;
      case TBButtonSize.large:
        return 56;
    }
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _getBackgroundColor(),
      foregroundColor: _getForegroundColor(),
      elevation: _getElevation(),
      shadowColor: _getShadowColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        side: _getBorderSide(),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(),
        vertical: _getVerticalPadding(),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case TBButtonType.primary:
        return TBColors.primary;
      case TBButtonType.secondary:
        return TBColors.secondary;
      case TBButtonType.outline:
        return Colors.transparent;
      case TBButtonType.ghost:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor() {
    switch (type) {
      case TBButtonType.primary:
      case TBButtonType.secondary:
        return TBColors.white;
      case TBButtonType.outline:
        return TBColors.primary;
      case TBButtonType.ghost:
        return TBColors.grey700;
    }
  }

  double _getElevation() {
    switch (type) {
      case TBButtonType.primary:
      case TBButtonType.secondary:
        return TBSpacing.elevationSm;
      case TBButtonType.outline:
      case TBButtonType.ghost:
        return 0;
    }
  }

  Color _getShadowColor() {
    return TBColors.primary.withOpacity(0.3);
  }

  BorderSide _getBorderSide() {
    switch (type) {
      case TBButtonType.outline:
        return const BorderSide(color: TBColors.primary, width: 1.5);
      default:
        return BorderSide.none;
    }
  }

  double _getHorizontalPadding() {
    switch (size) {
      case TBButtonSize.small:
        return 16;
      case TBButtonSize.medium:
        return 24;
      case TBButtonSize.large:
        return 32;
    }
  }

  double _getVerticalPadding() {
    return 0; // Height is controlled by container
  }

  TextStyle _getTextStyle() {
    TextStyle baseStyle;
    switch (size) {
      case TBButtonSize.small:
        baseStyle = TBTypography.buttonSmall;
        break;
      case TBButtonSize.medium:
        baseStyle = TBTypography.buttonMedium;
        break;
      case TBButtonSize.large:
        baseStyle = TBTypography.buttonLarge;
        break;
    }
    return baseStyle.copyWith(color: _getForegroundColor());
  }

  Color _getLoadingColor() {
    switch (type) {
      case TBButtonType.primary:
      case TBButtonType.secondary:
        return TBColors.white;
      case TBButtonType.outline:
        return TBColors.primary;
      case TBButtonType.ghost:
        return TBColors.grey700;
    }
  }
}