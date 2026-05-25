import 'package:flutter/material.dart';

import '../services/permission_service.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';

/// Widget que controla el acceso a módulos basado en los permisos del usuario.
/// Reemplaza a [RoleGuard] usando el sistema dinámico de permisos por módulos.
///
/// Si el usuario tiene acceso al módulo requerido, renderiza [child].
/// Si no tiene acceso, renderiza [fallback] o redirige al dashboard
/// con un mensaje de "Acceso denegado".
class ModuleGuard extends StatelessWidget {
  /// Código del módulo requerido (e.g., "LEADS", "DOCUMENTS").
  final String requiredModule;

  /// Widget a mostrar si el usuario tiene acceso al módulo.
  final Widget child;

  /// Widget alternativo a mostrar si el usuario no tiene acceso.
  /// Si es null, se redirige al dashboard con mensaje de "Acceso denegado".
  final Widget? fallback;

  const ModuleGuard({
    super.key,
    required this.requiredModule,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final hasAccess = PermissionService().hasModuleAccess(requiredModule);

    if (hasAccess) {
      return child;
    }

    if (fallback != null) {
      return fallback!;
    }

    // Default fallback: redirect to dashboard with "Acceso denegado" message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso denegado'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          ),
          (route) => false,
        );
      }
    });

    return const SizedBox.shrink();
  }
}
