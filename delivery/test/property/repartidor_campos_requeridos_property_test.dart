// Feature: delivery-app, Property 9: Información de repartidor contiene campos requeridos
// **Validates: Requirements 4.1**
//
// For any Repartidor, its representation in Panel_Admin must include:
// nombre completo, número total de entregas realizadas y estado actual
// (disponible, en entrega, inactivo).

import 'package:delivery_app/models/repartidor.dart';
import 'package:glados/glados.dart';

extension RepartidorGenerators on Any {
  Generator<EstadoRepartidor> get estadoRepartidor =>
      choose(EstadoRepartidor.values);

  Generator<Repartidor> get repartidor => combine3(
        nonEmptyLetterOrDigits, // nombreCompleto
        intInRange(0, 100000), // totalEntregas
        estadoRepartidor, // estado
        (String nombreCompleto, int totalEntregas,
                EstadoRepartidor estado) =>
            Repartidor(
          id: 'repartidor-test',
          nombreCompleto: nombreCompleto,
          totalEntregas: totalEntregas,
          estado: estado,
          usuario: 'user-test',
          password: 'pass-test',
        ),
      );
}

void main() {
  Glados(any.repartidor, ExploreConfig(numRuns: 100)).test(
    'Property 9: Every Repartidor has non-empty nombreCompleto, non-negative totalEntregas, and valid EstadoRepartidor',
    (repartidor) {
      // nombreCompleto must be non-empty
      expect(repartidor.nombreCompleto.isNotEmpty, isTrue,
          reason: 'nombreCompleto must not be empty');

      // totalEntregas must be non-negative
      expect(repartidor.totalEntregas, greaterThanOrEqualTo(0),
          reason: 'totalEntregas must be non-negative');

      // estado must be a valid EstadoRepartidor value
      expect(EstadoRepartidor.values.contains(repartidor.estado), isTrue,
          reason: 'estado must be a valid EstadoRepartidor');
    },
  );
}
