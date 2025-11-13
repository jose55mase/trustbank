import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handleFlutterError(FlutterErrorDetails details) {
    final error = details.exception.toString();
    if (kIsWeb && (error.contains('mouse_tracker.dart') || error.contains('width.isFinite'))) {
      return;
    }
    FlutterError.presentError(details);
  }
}