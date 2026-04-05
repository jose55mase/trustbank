// Feature: nitrado-server-manager, Property 14: Clasificación de niveles de log
// **Validates: Requirements 9.2**

import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/features/logs/logs_helpers.dart';

/// Generator for random printable strings (log context around the keyword).
final _safeChars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 :_-./[]';
final _contextGen = any.stringOf(_safeChars);

/// Builds a log line by inserting a keyword at a random position within context.
Generator<String> _logLineWith(String keyword) {
  return any.combine2(
    _contextGen,
    _contextGen,
    (String prefix, String suffix) => '$prefix $keyword $suffix',
  );
}

/// Generator for log lines containing "ERROR".
final _errorLineGen = _logLineWith('ERROR');

/// Generator for log lines containing "WARNING" but NOT "ERROR".
final _warningLineGen = _logLineWith('WARNING');

/// Generator for log lines that contain neither "ERROR" nor "WARNING"
/// (using only lowercase letters and digits to avoid accidental matches).
final _infoSafeChars = 'abcdfghijklmnopqstuvxyz0123456789 :_-./[]';
final _infoLineGen = any.stringOf(_infoSafeChars);

void main() {
  // Property 14: Lines containing "ERROR" → LogLevel.error
  Glados(_errorLineGen, ExploreConfig(numRuns: 100)).test(
    'lines containing ERROR are classified as LogLevel.error',
    (String line) {
      expect(classifyLogLevel(line), equals(LogLevel.error));
    },
  );

  // Property 14: Lines containing "WARNING" (no "ERROR") → LogLevel.warning
  Glados(_warningLineGen, ExploreConfig(numRuns: 100)).test(
    'lines containing WARNING (without ERROR) are classified as LogLevel.warning',
    (String line) {
      // Ensure no accidental ERROR in the generated context
      final clean =
          line.replaceAll(RegExp(r'error', caseSensitive: false), 'xxxxx');
      // Re-insert WARNING to guarantee it's present
      final testLine = clean.contains('WARNING') ? clean : '$clean WARNING';
      expect(classifyLogLevel(testLine), equals(LogLevel.warning));
    },
  );

  // Property 14: Lines with neither "ERROR" nor "WARNING" → LogLevel.info
  Glados(_infoLineGen, ExploreConfig(numRuns: 100)).test(
    'lines without ERROR or WARNING are classified as LogLevel.info',
    (String line) {
      // The safe charset excludes letters that could form ERROR/WARNING
      expect(classifyLogLevel(line), equals(LogLevel.info));
    },
  );
}
