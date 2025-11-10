import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';
import '../../typography/tb_typography.dart';
import '../../spacing/tb_spacing.dart';

enum TBButtonType { primary, secondary, outline }

class TBButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final TBButtonType type;
  final bool isLoading;
  final bool fullWidth;

  const TBButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = TBButtonType.primary,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getForegroundColor(),
          elevation: type == TBButtonType.primary ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
            side: type == TBButtonType.outline 
                ? const BorderSide(color: TBColors.primary, width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text, style: TBTypography.buttonMedium),
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
    }
  }

  Color _getForegroundColor() {
    switch (type) {
      case TBButtonType.primary:
      case TBButtonType.secondary:
        return TBColors.white;
      case TBButtonType.outline:
        return TBColors.primary;
    }
  }
}