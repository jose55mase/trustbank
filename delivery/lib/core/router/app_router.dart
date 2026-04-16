import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/auth.dart';
import '../../providers/auth_providers.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/admin/panel_admin_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/placeholder_screen.dart';
import '../../screens/repartidor/confirmacion_entrega_screen.dart';
import '../../screens/repartidor/detalle_pedido_screen.dart';
import '../../screens/repartidor/panel_repartidor_screen.dart';
import '../../screens/usuario/formulario_pedido_screen.dart';
import '../../screens/usuario/historial_usuario_screen.dart';
import '../../screens/usuario/seguimiento_pedido_screen.dart';

/// Route path constants.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String pedido = '/pedido';
  static const String seguimiento = '/seguimiento';
  static const String historial = '/historial';
  static const String login = '/login';
  static const String repartidor = '/repartidor';
  static const String repartidorDetalle = '/repartidor/detalle/:id';
  static const String repartidorConfirmar = '/repartidor/confirmar/:id';
  static const String admin = '/admin';
}

/// Creates the [GoRouter] instance with all routes and navigation guards.
///
/// Requisitos: 5.2, 5.3, 5.5
GoRouter createAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      // ── Public routes (no auth required) ─────────────────────
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) =>
            const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.pedido,
        name: 'pedido',
        builder: (context, state) => const FormularioPedidoScreen(),
      ),
      GoRoute(
        path: AppRoutes.seguimiento,
        name: 'seguimiento',
        builder: (context, state) {
          final telefono =
              state.uri.queryParameters['telefono'] ?? '';
          return SeguimientoPedidoScreen(telefono: telefono);
        },
      ),
      GoRoute(
        path: AppRoutes.historial,
        name: 'historial',
        builder: (context, state) {
          final telefono =
              state.uri.queryParameters['telefono'] ?? '';
          return HistorialUsuarioScreen(telefono: telefono);
        },
      ),

      // ── Auth route ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Repartidor routes (require repartidor session) ──────
      GoRoute(
        path: AppRoutes.repartidor,
        name: 'repartidor',
        builder: (context, state) => const PanelRepartidorScreen(),
      ),
      GoRoute(
        path: AppRoutes.repartidorDetalle,
        name: 'repartidorDetalle',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return DetallePedidoScreen(pedidoId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.repartidorConfirmar,
        name: 'repartidorConfirmar',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ConfirmacionEntregaScreen(pedidoId: id);
        },
      ),

      // ── Admin routes (require admin session) ────────────────
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        builder: (context, state) =>
            const PanelAdminScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final container = ProviderScope.containerOf(context);
      final sesionAsync = container.read(sesionActivaProvider);

      final isGoingToRepartidor =
          state.matchedLocation.startsWith('/repartidor');
      final isGoingToAdmin = state.matchedLocation.startsWith('/admin');
      final isGoingToLogin = state.matchedLocation == AppRoutes.login;

      // If session data is not yet loaded, allow navigation
      final sesion = sesionAsync.valueOrNull;

      // Guard: repartidor routes require repartidor session
      if (isGoingToRepartidor) {
        if (sesion == null || sesion.tipo != TipoUsuario.repartidor) {
          return AppRoutes.login;
        }
      }

      // Guard: admin routes require admin session
      if (isGoingToAdmin) {
        if (sesion == null || sesion.tipo != TipoUsuario.administrador) {
          return AppRoutes.login;
        }
      }

      // If logged in and going to login, redirect to appropriate panel
      if (isGoingToLogin && sesion != null) {
        return sesion.tipo == TipoUsuario.repartidor
            ? AppRoutes.repartidor
            : AppRoutes.admin;
      }

      return null; // No redirect
    },
    errorBuilder: (context, state) => PlaceholderScreen(
      title: 'Página no encontrada: ${state.uri}',
    ),
  );
}

/// Provider that exposes the GoRouter instance.
/// Depends on a [WidgetRef] so it can read auth state for guards.
/// Use this in app.dart via a [Consumer] or pass the ref.
final appRouterProvider = Provider<GoRouter>((ref) {
  throw UnimplementedError(
    'appRouterProvider must be created with a WidgetRef in app.dart',
  );
});
