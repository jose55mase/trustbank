import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../models/module_permission.dart';
import '../../../services/permission_service.dart';
import '../bloc/admin_bloc.dart';

import '../widgets/admin_stats.dart';
import 'document_management_screen.dart';
import 'users_management_screen.dart';
import 'document_approval_screen.dart';
import 'role_management_screen.dart';
import '../leads/screens/leads_list_screen.dart';
import '../assignment_types/screens/assignment_types_management_screen.dart';
import '../roles/screens/roles_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService();
    // Only allow access if user has admin-level modules (not just basic LEADS/DOCUMENTS)
    final hasAccess = permissionService.hasModuleAccess('USER_MANAGEMENT') ||
        permissionService.hasModuleAccess('ROLE_MANAGEMENT') ||
        permissionService.hasModuleAccess('DOCUMENT_APPROVAL') ||
        permissionService.hasModuleAccess('SUPERVISOR_ASSIGNMENTS');

    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
          backgroundColor: TBColors.primary,
          foregroundColor: TBColors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'No tienes permisos para acceder al panel administrativo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) => AdminBloc()..add(LoadRequests()),
      child: const _AdminDashboardBody(),
    );
  }
}

class _AdminDashboardBody extends StatelessWidget {
  const _AdminDashboardBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator(color: TBColors.primary));
          }

          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: TBColors.error.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline, size: 48, color: TBColors.error),
                  ),
                  const SizedBox(height: TBSpacing.lg),
                  Text('Error: ${state.message}', style: TBTypography.bodyMedium),
                  const SizedBox(height: TBSpacing.md),
                  TBButton(
                    text: 'Reintentar',
                    onPressed: () => context.read<AdminBloc>().add(LoadRequests()),
                  ),
                ],
              ),
            );
          }

          if (state is AdminLoaded) {
            return CustomScrollView(
              slivers: [
                // Header con gradiente
                SliverToBoxAdapter(child: _buildHeader(context)),
                // Contenido
                SliverPadding(
                  padding: const EdgeInsets.all(TBSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Stats
                      AdminStats(requests: state.requests),
                      const SizedBox(height: TBSpacing.lg),
                      // Acciones rápidas
                      Text('Acciones Rápidas', style: TBTypography.titleLarge),
                      const SizedBox(height: TBSpacing.md),
                      _buildActionGrid(context),
                    ]),
                  ),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator(color: TBColors.primary));
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final permissionService = PermissionService();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(TBSpacing.lg, TBSpacing.xl, TBSpacing.lg, TBSpacing.xl),
      decoration: const BoxDecoration(
        gradient: TBColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(TBSpacing.radiusXl),
          bottomRight: Radius.circular(TBSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: TBSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panel Administrativo',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestiona tu plataforma',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            if (permissionService.hasModuleAccess('USER_MANAGEMENT'))
              Material(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                child: InkWell(
                  borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UsersManagementScreen()),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.people_outline, color: Colors.white, size: 22),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final permissionService = PermissionService();
    final allowedModules = permissionService.allowedModules;

    final List<Widget> actionIcons = [];

    for (final module in allowedModules) {
      final config = _getModuleConfig(module);
      if (config != null) {
        actionIcons.add(
          _buildActionIcon(
            context,
            icon: config.icon,
            label: config.label,
            color: config.color,
            onTap: () => config.onTap(context),
          ),
        );
      }
    }

    // Add "Crear Roles" icon if user has ROLE_MANAGEMENT access
    if (permissionService.hasModuleAccess('ROLE_MANAGEMENT')) {
      actionIcons.add(
        _buildActionIcon(
          context,
          icon: Icons.security_rounded,
          label: 'Crear\nRoles',
          color: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RolesManagementScreen()),
          ),
        ),
      );
    }

    if (actionIcons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: TBSpacing.xl,
      runSpacing: TBSpacing.lg,
      alignment: WrapAlignment.center,
      children: actionIcons,
    );
  }

  _ModuleActionConfig? _getModuleConfig(ModulePermission module) {
    switch (module.code) {
      case 'LEADS':
        return _ModuleActionConfig(
          icon: Icons.leaderboard_rounded,
          label: 'Leads',
          color: TBColors.primary,
          onTap: (context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeadsListScreen()),
          ),
        );
      case 'DOCUMENTS':
        return _ModuleActionConfig(
          icon: Icons.description_rounded,
          label: 'Documentos',
          color: TBColors.secondary,
          onTap: (context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DocumentManagementScreen()),
          ),
        );
      case 'DOCUMENT_APPROVAL':
        return _ModuleActionConfig(
          icon: Icons.verified_rounded,
          label: 'Aprobar',
          color: TBColors.warning,
          onTap: (context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DocumentApprovalScreen()),
          ),
        );
      case 'USER_MANAGEMENT':
        return _ModuleActionConfig(
          icon: Icons.group_rounded,
          label: 'Usuarios',
          color: TBColors.accentDark,
          onTap: (context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UsersManagementScreen()),
          ),
        );
      case 'ROLE_MANAGEMENT':
        return _ModuleActionConfig(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Asignar\nRoles',
          color: TBColors.error,
          onTap: (context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoleManagementScreen()),
          ),
        );
      case 'SUPERVISOR_ASSIGNMENTS':
        return _ModuleActionConfig(
          icon: Icons.campaign_rounded,
          label: 'Campañas',
          color: TBColors.primaryDark,
          onTap: (context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssignmentTypesManagementScreen()),
          ),
        );
      default:
        return null;
    }
  }

  Widget _buildActionIcon(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TBTypography.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

}

/// Helper class to encapsulate module action configuration for the dashboard grid.
class _ModuleActionConfig {
  final IconData icon;
  final String label;
  final Color color;
  final void Function(BuildContext context) onTap;

  const _ModuleActionConfig({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
