// Feature: delivery-app, Property 14: Filtros de historial retornan solo registros coincidentes
// **Validates: Requirements 4.3, 9.3**
//
// For any combination of filters applied to history, all returned records
// must match all specified filter criteria.

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:glados/glados.dart';

/// Represents a combination of optional filters to apply.
class FilterCombo {
  final bool useDateRange;
  final bool useRepartidor;
  final bool useUsuario;

  const FilterCombo({
    required this.useDateRange,
    required this.useRepartidor,
    required this.useUsuario,
  });

  @override
  String toString() =>
      'FilterCombo(date=$useDateRange, rep=$useRepartidor, user=$useUsuario)';
}

extension FilterGenerators on Any {
  /// At least one filter must be active (mask 1-7)
  Generator<int> get filterMask => intInRange(1, 7);
}

void main() {
  // Known data from mock_data.dart
  const repartidorIds = ['rep-001', 'rep-002', 'rep-003'];
  const phones = ['3101234567', '3209876543', '3154567890'];

  Glados(any.filterMask, ExploreConfig(numRuns: 100)).test(
    'Property 14: History filters return only matching records',
    (mask) async {
      final repo = MockPedidoRepository();

      final useDateRange = (mask & 1) != 0;
      final useRepartidor = (mask & 2) != 0;
      final useUsuario = (mask & 4) != 0;

      // Pick filter values from known data
      final fechaInicio =
          useDateRange ? DateTime(2024, 11, 5) : null;
      final fechaFin =
          useDateRange ? DateTime(2024, 11, 15) : null;
      final repartidorId =
          useRepartidor ? repartidorIds[mask % repartidorIds.length] : null;
      final telefonoUsuario =
          useUsuario ? phones[mask % phones.length] : null;

      final results = await repo.obtenerHistorial(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        repartidorId: repartidorId,
        telefonoUsuario: telefonoUsuario,
      );

      // Every returned record must match ALL active filters
      for (final entry in results) {
        if (useDateRange) {
          expect(
            !entry.fechaCompletacion.isBefore(fechaInicio!),
            isTrue,
            reason:
                'Entry ${entry.id} completacion ${entry.fechaCompletacion} must be >= $fechaInicio',
          );
          expect(
            !entry.fechaCompletacion.isAfter(fechaFin!),
            isTrue,
            reason:
                'Entry ${entry.id} completacion ${entry.fechaCompletacion} must be <= $fechaFin',
          );
        }
        if (useRepartidor) {
          expect(entry.repartidorId, equals(repartidorId),
              reason:
                  'Entry ${entry.id} repartidorId must match filter $repartidorId');
        }
        if (useUsuario) {
          expect(entry.telefonoUsuario, equals(telefonoUsuario),
              reason:
                  'Entry ${entry.id} telefonoUsuario must match filter $telefonoUsuario');
        }
      }
    },
  );
}
