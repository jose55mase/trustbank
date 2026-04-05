// Feature: nitrado-server-manager, Property 5: Deshabilitación de controles durante operaciones en curso
// **Validates: Requirements 3.5**

import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/features/server_control/is_control_enabled.dart';

/// Generator that picks a random status from the valid server status set.
final _statusGen = any.choose(['started', 'stopped', 'restarting', 'installing']);

void main() {
  Glados(_statusGen, ExploreConfig(numRuns: 100)).test(
    'controls are disabled for transitional states and enabled otherwise',
    (String status) {
      final enabled = isControlEnabled(status);

      if (status == 'restarting' || status == 'installing') {
        expect(enabled, isFalse,
            reason: 'Controls must be disabled for "$status"');
      } else {
        expect(enabled, isTrue,
            reason: 'Controls must be enabled for "$status"');
      }
    },
  );
}
