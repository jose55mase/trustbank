import 'package:flutter/material.dart';
import '../../colors/tb_colors.dart';
import '../../typography/tb_typography.dart';
import '../../spacing/tb_spacing.dart';

class TBLoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, {String message = 'Procesando...'}) {
    hide(); // Remove any existing overlay
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(TBSpacing.xl),
            margin: const EdgeInsets.symmetric(horizontal: TBSpacing.xl),
            decoration: BoxDecoration(
              color: TBColors.white,
              borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: TBColors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(TBColors.primary),
                  ),
                ),
                const SizedBox(height: TBSpacing.lg),
                Text(
                  message,
                  style: TBTypography.bodyLarge.copyWith(
                    color: TBColors.grey700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static Future<T> showWithDelay<T>(
    BuildContext context,
    Future<T> operation, {
    String message = 'Procesando...',
    int minDelayMs = 1500,
  }) async {
    show(context, message: message);
    
    final results = await Future.wait([
      operation,
      Future.delayed(Duration(milliseconds: minDelayMs)),
    ]);
    
    hide();
    return results[0] as T;
  }
}