// Feature: delivery-app, Property 2: Campos vacíos son rechazados con validación
// **Validates: Requirements 1.3**
//
// For any combination of required fields where at least one is empty or
// whitespace-only, the system must reject order creation with a validation
// message listing the missing fields.

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

/// Generates a string that is either empty, whitespace-only, or valid.
Generator<String> fieldValue(bool shouldBeEmpty) {
  if (shouldBeEmpty) {
    return any.choose(['', '   ', '  \t  ']);
  }
  return any.nonEmptyLetterOrDigits;
}

extension EmptyFieldGenerators on Any {
  /// Generates a bitmask (1-31) where each bit indicates if a field is empty.
  /// At least one bit must be set (value > 0).
  Generator<int> get emptyFieldMask => intInRange(1, 31);

  Generator<TipoEntrega> get tipoEntrega => choose(TipoEntrega.values);
}

void main() {
  Glados(any.emptyFieldMask, ExploreConfig(numRuns: 100)).test(
    'Property 2: Requests with at least one empty required field are rejected',
    (mask) async {
      final repo = MockPedidoRepository();

      // Bits: 1=direccion, 2=nombre, 4=telefono, 8=descripcion, 16=precio
      final direccionEmpty = (mask & 1) != 0;
      final nombreEmpty = (mask & 2) != 0;
      final telefonoEmpty = (mask & 4) != 0;
      final descripcionEmpty = (mask & 8) != 0;
      final precioZero = (mask & 16) != 0;

      final request = CrearPedidoRequest(
        direccionEntrega: direccionEmpty ? '   ' : 'Calle 45 #12-34',
        nombreUsuario: nombreEmpty ? '' : 'Juan Pérez',
        telefonoUsuario: telefonoEmpty ? '  ' : '3001234567',
        descripcion: descripcionEmpty ? '' : 'Paquete de prueba',
        precioProducto: precioZero ? 0.0 : 25000.0,
        tipoEntrega: TipoEntrega.estandar,
      );

      // Must throw an exception with validation message
      try {
        await repo.crearPedido(request);
        fail('Should have thrown an exception for empty fields');
      } on Exception catch (e) {
        final message = e.toString();
        expect(message.contains('Campos obligatorios faltantes'), isTrue,
            reason: 'Error message must mention missing fields');

        // Verify each empty field is mentioned
        if (direccionEmpty) {
          expect(message.contains('direccionEntrega'), isTrue,
              reason: 'Must mention direccionEntrega');
        }
        if (nombreEmpty) {
          expect(message.contains('nombreUsuario'), isTrue,
              reason: 'Must mention nombreUsuario');
        }
        if (telefonoEmpty) {
          expect(message.contains('telefonoUsuario'), isTrue,
              reason: 'Must mention telefonoUsuario');
        }
        if (descripcionEmpty) {
          expect(message.contains('descripcion'), isTrue,
              reason: 'Must mention descripcion');
        }
        if (precioZero) {
          expect(message.contains('precioProducto'), isTrue,
              reason: 'Must mention precioProducto');
        }
      }
    },
  );
}
