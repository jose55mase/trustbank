import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../models/user_role.dart';
import '../../../widgets/role_guard.dart';
import '../bloc/admin_bloc.dart';

import '../widgets/request_card.dart';
import '../widgets/admin_stats.dart';
import '../widgets/filter_chips.dart';
import 'document_management_screen.dart';
import 'users_management_screen.dart';
import 'document_approval_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredPermission: Permission.viewAdminPanel,
      fallback: Scaffold(
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
      ),
      child: BlocProvider(
        create: (context) => AdminBloc()..add(LoadRequests()),
        child: Scaffold(
          backgroundColor: TBColors.background,
          appBar: AppBar(
            title: Text('Panel Administrador', style: TBTypography.headlineMedium),
            backgroundColor: TBColors.primary,
            foregroundColor: TBColors.white,
            elevation: 0,
            actions: [
              RoleGuard(
                requiredPermission: Permission.manageUsers,
                child: IconButton(
                  icon: const Icon(Icons.people),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UsersManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is AdminError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    TBButton(
                      text: 'Reintentar',
                      onPressed: () => context.read<AdminBloc>().add(LoadRequests()),
                    ),
                  ],
                ),
              );
            }
            
            if (state is AdminLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(TBSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminStats(requests: state.requests),
                    const SizedBox(height: TBSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: TBButton(
                            text: 'Gestionar Documentos',
                            type: TBButtonType.secondary,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DocumentManagementScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: TBSpacing.sm),
                        RoleGuard(
                          requiredPermission: Permission.manageUsers,
                          child: Expanded(
                            child: TBButton(
                              text: 'Gestionar Usuarios',
                              type: TBButtonType.secondary,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UsersManagementScreen(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TBSpacing.sm),
                    TBButton(
                      text: 'Aprobar Documentos de Imágenes',
                      type: TBButtonType.primary,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DocumentApprovalScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: TBSpacing.md),
                    FilterChips(
                      onFilterChanged: (type, status) {
                        context.read<AdminBloc>().add(
                          FilterRequests(type: type, status: status),
                        );
                      },
                    ),
                    const SizedBox(height: TBSpacing.lg),
                    Text('Solicitudes', style: TBTypography.titleLarge),
                    const SizedBox(height: TBSpacing.md),
                    if (state.requests.isEmpty)
                      const Center(
                        child: Text('No hay solicitudes disponibles'),
                      )
                    else
                      ...state.requests.map((request) => RequestCard(
                        request: request,
                        onProcess: (status, notes) {
                          context.read<AdminBloc>().add(
                            ProcessRequest(
                              requestId: request.id,
                              status: status,
                              notes: notes,
                            ),
                          );
                        },
                      )),
                  ],
                ),
              );
            }
            
            return const Center(child: CircularProgressIndicator());
          },
          ),
        ),
      ),
    );
  }
}