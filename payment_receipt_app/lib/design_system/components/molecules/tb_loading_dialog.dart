import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';
import '../../typography/tb_typography.dart';
import '../../spacing/tb_spacing.dart';

class TBLoadingDialog extends StatelessWidget {
  final String message;

  const TBLoadingDialog({
    super.key,
    this.message = 'Cargando...',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
      ),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(TBSpacing.xl),
        decoration: BoxDecoration(
          color: TBColors.surface,
          borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: TBColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TBColors.primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: TBSpacing.lg),
            Text(
              message,
              style: TBTypography.bodyMedium.copyWith(
                color: TBColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TBLoadingDialog(
        message: message ?? 'Cargando...',
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}