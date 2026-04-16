import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/mock/mock_auth_repository.dart';
import 'data/mock/mock_geolocalizacion_repository.dart';
import 'data/mock/mock_notificacion_service.dart';
import 'data/mock/mock_pedido_repository.dart';
import 'data/mock/mock_repartidor_repository.dart';
import 'data/mock/mock_reporte_ganancias_repository.dart';
import 'providers/auth_providers.dart';
import 'providers/geolocalizacion_providers.dart';
import 'providers/pedido_providers.dart';
import 'providers/repartidor_providers.dart';
import 'repositories/notificacion_service.dart';
import 'repositories/reporte_ganancias_repository.dart';

/// Provider for [NotificacionService].
final notificacionServiceProvider = Provider<NotificacionService>((ref) {
  throw UnimplementedError(
    'notificacionServiceProvider must be overridden',
  );
});

/// Provider for [ReporteGananciasRepository].
final reporteGananciasRepositoryProvider =
    Provider<ReporteGananciasRepository>((ref) {
  throw UnimplementedError(
    'reporteGananciasRepositoryProvider must be overridden',
  );
});

/// Creates the [ProviderScope] with all mock repository overrides.
///
/// Requisitos: 10.1, 10.2
ProviderScope createAppProviderScope({required Widget child}) {
  final mockPedidoRepo = MockPedidoRepository();
  final mockAuthRepo = MockAuthRepository();
  final mockRepartidorRepo = MockRepartidorRepository(mockPedidoRepo);
  final mockGeoRepo = MockGeolocalizacionRepository();
  final mockReporteRepo = MockReporteGananciasRepository(mockPedidoRepo);
  final mockNotificacionService = MockNotificacionService();

  return ProviderScope(
    overrides: [
      pedidoRepositoryProvider.overrideWithValue(mockPedidoRepo),
      authRepositoryProvider.overrideWithValue(mockAuthRepo),
      repartidorRepositoryProvider.overrideWithValue(mockRepartidorRepo),
      geolocalizacionRepositoryProvider.overrideWithValue(mockGeoRepo),
      reporteGananciasRepositoryProvider.overrideWithValue(mockReporteRepo),
      notificacionServiceProvider.overrideWithValue(mockNotificacionService),
    ],
    child: child,
  );
}

/// Root widget of the Delivery App.
///
/// Uses [MaterialApp.router] with GoRouter and the dark Nequi theme.
/// Requisitos: 10.1, 10.2, 11.4
class DeliveryApp extends ConsumerStatefulWidget {
  const DeliveryApp({super.key});

  @override
  ConsumerState<DeliveryApp> createState() => _DeliveryAppState();
}

class _DeliveryAppState extends ConsumerState<DeliveryApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(ref);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Domicilios',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
