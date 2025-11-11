import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_input.dart';
import '../bloc/users_bloc.dart';
import '../models/user_model.dart';
import '../widgets/user_card.dart';
import '../widgets/user_detail_dialog.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final _searchController = TextEditingController();
  UserStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UsersBloc()..add(LoadUsers()),
      child: Scaffold(
        backgroundColor: TBColors.background,
        appBar: AppBar(
          title: Text('Gestión de Usuarios', style: TBTypography.headlineMedium),
          backgroundColor: TBColors.primary,
          foregroundColor: TBColors.white,
        ),
        body: Column(
          children: [
            // Filtros
            Container(
              padding: const EdgeInsets.all(TBSpacing.md),
              color: TBColors.surface,
              child: Column(
                children: [
                  TBInput(
                    controller: _searchController,
                    hint: 'Buscar por nombre o email',
                    prefixIcon: const Icon(Icons.search),
                    onChanged: (value) {
                      context.read<UsersBloc>().add(FilterUsers(
                        searchQuery: value,
                        status: _selectedStatus,
                      ));
                    },
                  ),
                  const SizedBox(height: TBSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip('Todos', null),
                        _buildStatusChip('Activos', UserStatus.active),
                        _buildStatusChip('Inactivos', UserStatus.inactive),
                        _buildStatusChip('Pendientes', UserStatus.pending),
                        _buildStatusChip('Suspendidos', UserStatus.suspended),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Lista de usuarios
            Expanded(
              child: BlocBuilder<UsersBloc, UsersState>(
                builder: (context, state) {
                  if (state is UsersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (state is UsersError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: TBColors.error),
                          const SizedBox(height: TBSpacing.md),
                          Text(
                            'Error al cargar usuarios',
                            style: TBTypography.titleLarge,
                          ),
                          Text(
                            state.message,
                            style: TBTypography.bodyMedium.copyWith(
                              color: TBColors.grey600,
                            ),
                          ),
                          const SizedBox(height: TBSpacing.md),
                          ElevatedButton(
                            onPressed: () {
                              context.read<UsersBloc>().add(LoadUsers());
                            },
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (state is UsersLoaded) {
                    if (state.users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: TBColors.grey600),
                            const SizedBox(height: TBSpacing.md),
                            Text(
                              'No hay usuarios',
                              style: TBTypography.titleLarge,
                            ),
                            Text(
                              'No se encontraron usuarios con los filtros aplicados',
                              style: TBTypography.bodyMedium.copyWith(
                                color: TBColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(TBSpacing.md),
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        final user = state.users[index];
                        return UserCard(
                          user: user,
                          onTap: () => _showUserDetail(context, user),
                        );
                      },
                    );
                  }
                  
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, UserStatus? status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: TBSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = selected ? status : null;
          });
          context.read<UsersBloc>().add(FilterUsers(
            searchQuery: _searchController.text,
            status: _selectedStatus,
          ));
        },
        selectedColor: TBColors.primary.withOpacity(0.2),
        checkmarkColor: TBColors.primary,
      ),
    );
  }

  void _showUserDetail(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailDialog(user: user),
    );
  }
}