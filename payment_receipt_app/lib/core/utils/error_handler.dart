import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handleFlutterError(FlutterErrorDetails details) {
    if (kIsWeb && details.exception.toString().contains('mouse_tracker.dart')) {
      return;
    }
    FlutterError.presentError(details);
  }
}