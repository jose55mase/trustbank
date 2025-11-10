import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';
import '../../typography/tb_typography.dart';
import '../../spacing/tb_spacing.dart';
import '../atoms/tb_button.dart';

enum TBDialogType { success, error, warning, info }

class TBDialog extends StatelessWidget {
  final TBDialogType type;
  final String title;
  final String message;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;

  const TBDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
      ),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(TBSpacing.lg),
        decoration: BoxDecoration(
          color: TBColors.surface,
          borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: TBSpacing.md),
            Text(
              title,
              style: TBTypography.titleLarge.copyWith(
                color: _getColor(),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TBSpacing.sm),
            Text(
              message,
              style: TBTypography.bodyMedium.copyWith(
                color: TBColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TBSpacing.lg),
            _buildButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getIcon(),
        color: _getColor(),
        size: 30,
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    if (primaryButtonText == null && secondaryButtonText == null) {
      return TBButton(
        text: 'Aceptar',
        onPressed: () => Navigator.of(context).pop(),
        fullWidth: true,
      );
    }

    return Row(
      children: [
        if (secondaryButtonText != null) ...[
          Expanded(
            child: TBButton(
              text: secondaryButtonText!,
              type: TBButtonType.outline,
              onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: TBSpacing.sm),
        ],
        Expanded(
          child: TBButton(
            text: primaryButtonText ?? 'Aceptar',
            onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Color _getColor() {
    switch (type) {
      case TBDialogType.success:
        return TBColors.success;
      case TBDialogType.error:
        return TBColors.error;
      case TBDialogType.warning:
        return Colors.orange;
      case TBDialogType.info:
        return TBColors.primary;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case TBDialogType.success:
        return Icons.check_circle;
      case TBDialogType.error:
        return Icons.error;
      case TBDialogType.warning:
        return Icons.warning;
      case TBDialogType.info:
        return Icons.info;
    }
  }
}

class TBDialogHelper {
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => TBDialog(
        type: TBDialogType.success,
        title: title,
        message: message,
        primaryButtonText: buttonText,
        onPrimaryPressed: onPressed,
      ),
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => TBDialog(
        type: TBDialogType.error,
        title: title,
        message: message,
        primaryButtonText: buttonText,
        onPrimaryPressed: onPressed,
      ),
    );
  }

  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => TBDialog(
        type: TBDialogType.warning,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
      ),
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => TBDialog(
        type: TBDialogType.info,
        title: title,
        message: message,
        primaryButtonText: buttonText,
        onPrimaryPressed: onPressed,
      ),
    );
  }
}