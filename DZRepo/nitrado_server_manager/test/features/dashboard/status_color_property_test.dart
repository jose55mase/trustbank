// Feature: nitrado-server-manager, Property 3: Mapeo estado-color del servidor
// **Validates: Requirements 2.5**

import 'package:flutter/material.dart';
import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/features/dashboard/status_color.dart';

/// Generator for valid server status strings.
final _validStatusGen = any.choose([
  'started',
  'stopped',
  'restarting',
  'installing',
]);

void main() {
  Glados(_validStatusGen, ExploreConfig(numRuns: 100)).test(
    'statusColor maps each valid status to the correct color',
    (String status) {
      final color = statusColor(status);

      switch (status) {
        case 'started':
          expect(color, equals(Colors.green));
          break;
        case 'stopped':
          expect(color, equals(Colors.red));
          break;
        case 'restarting':
          expect(color, equals(Colors.yellow));
          break;
        case 'installing':
          expect(color, equals(Colors.yellow));
          break;
      }
    },
  );

  /// Arbitrary string generator for totality check.
  final arbitraryStringGen = any.nonEmptyStringOf(
    'abcdefghijklmnopqrstuvwxyz0123456789_- ',
  );

  Glados(arbitraryStringGen, ExploreConfig(numRuns: 100)).test(
    'statusColor is total: returns a valid Color for any arbitrary string',
    (String arbitrary) {
      // Must not throw and must return a Color instance
      final color = statusColor(arbitrary);
      expect(color, isA<Color>());
    },
  );
}
