import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';
import '../../../models/supervisor_assignment.dart';
import '../../../models/user_role.dart';
import '../../../services/supervisor_assignments_service.dart';
import '../models/user_model.dart';
import '../bloc/users_bloc.dart';
import '../screens/adjust_balance_screen.dart';
import '../users/widgets/role_assignment_dialog.dart';

class UserDetailDialog extends StatefulWidget {
  final AdminUser user;

  const UserDetailDialog({super.key, required this.user});

  @override
  State<UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends State<UserDetailDialog> {
  SupervisorAssignment? _assignment;
  bool _isLoadingAssignment = false;

  AdminUser get user => widget.user;

  bool get _isSupervisor => user.hasRole(UserRole.supervisor);

  @override
  void initState() {
    super.initState();
    if (_isSupervisor) {
      _loadAssignment();
    }
  }

  Future<void> _loadAssignment() async {
    setState(() => _isLoadingAssignment = true);
    try {
      final assignments = await SupervisorAssignmentsService.getAll();
      final match = assignments.where((a) => a.userId == user.id).toList();
      if (mounted) {
        setState(() {
          _assignment = match.isNotEmpty ? match.first : null;
          _isLoadingAssignment = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAssignment = false);
      }
    }
  }

  Future<void> _changeAssignmentType() async {
    final newType = await RoleAssignmentDialog.show(context);
    if (newType == null) return;

    try {
      await SupervisorAssignmentsService.update(user.id, newType.id);
      await _loadAssignment();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tipo de asignación actualizado a: ${newType.name}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error actualizando tipo de asignación: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
      ),
      child: Container(
        padding: const EdgeInsets.all(TBSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getStatusColor().withOpacity(0.2),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TBTypography.headlineMedium.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: TBSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TBTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TBTypography.bodyMedium.copyWith(
                          color: TBColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: TBSpacing.lg),
            
            // Información del usuario
            _buildInfoSection('Información Personal', [
              _buildInfoRow('ID', user.id.toString()),
              _buildInfoRow('Teléfono', user.phone ?? 'No especificado'),
              _buildInfoRow('Dirección', user.address ?? 'No especificada'),
              _buildInfoRow('Tipo de documento', user.documentType ?? 'No especificado'),
              _buildInfoRow('Número de documento', user.documentNumber ?? 'No especificado'),
            ]),
            
            const SizedBox(height: TBSpacing.md),
            
            _buildInfoSection('Información de Cuenta', [
              _buildInfoRow('Estado', _getStatusText()),
              _buildInfoRow('Saldo', '\$${user.balance.toStringAsFixed(2)}'),
              _buildInfoRow('Fecha de registro', _formatDate(user.createdAt)),
              if (user.updatedAt != null)
                _buildInfoRow('Última actualización', _formatDate(user.updatedAt!)),
            ]),

            // Supervisor assignment type section
            if (_isSupervisor) ...[
              const SizedBox(height: TBSpacing.md),
              _buildSupervisorAssignmentSection(),
            ],
            
            const SizedBox(height: TBSpacing.lg),
            
            // Acciones
            TBButton(
              text: 'Ajustar Saldo',
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdjustBalanceScreen(user: user.toJson()),
                  ),
                );
              },
            ),
            const SizedBox(height: TBSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TBButton(
                    text: user.accountStatus.toLowerCase() == 'active' ? 'Suspender' : 'Activar',
                    type: user.accountStatus.toLowerCase() == 'active' 
                        ? TBButtonType.secondary 
                        : TBButtonType.primary,
                    onPressed: () => _showConfirmationDialog(context),
                  ),
                ),
                const SizedBox(width: TBSpacing.sm),
                Expanded(
                  child: TBButton(
                    text: 'Cerrar',
                    type: TBButtonType.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TBTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: TBSpacing.sm),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TBSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TBTypography.bodyMedium.copyWith(
                color: TBColors.grey600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TBTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorAssignmentSection() {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_ind,
                size: 18,
                color: Colors.purple,
              ),
              const SizedBox(width: TBSpacing.sm),
              Text(
                'Tipo de Asignación',
                style: TBTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: TBSpacing.sm),
          if (_isLoadingAssignment)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: TBSpacing.sm),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    _assignment?.assignmentTypeName ?? 'Sin asignación',
                    style: TBTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _assignment != null
                          ? Colors.purple
                          : TBColors.grey600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _changeAssignmentType,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Cambiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purple,
                    textStyle: TBTypography.bodySmall,
                    padding: const EdgeInsets.symmetric(
                      horizontal: TBSpacing.sm,
                      vertical: TBSpacing.xs,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (user.accountStatus.toLowerCase()) {
      case 'active':
        return TBColors.success;
      case 'inactive':
        return TBColors.grey600;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return TBColors.error;
      default:
        return TBColors.grey600;
    }
  }

  String _getStatusText() {
    switch (user.accountStatus.toLowerCase()) {
      case 'active':
        return 'Activo';
      case 'inactive':
        return 'Inactivo';
      case 'pending':
        return 'Pendiente';
      case 'suspended':
        return 'Suspendido';
      default:
        return user.accountStatus;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  void _showConfirmationDialog(BuildContext context) {
    final isActive = user.accountStatus.toLowerCase() == 'active';
    final action = isActive ? 'suspender' : 'activar';
    final newStatus = isActive ? UserStatus.suspended : UserStatus.active;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Confirmar acción'),
        content: Text(
          '¿Estás seguro de que deseas $action al usuario ${user.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              
              // Mostrar diálogo de carga
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Actualizando usuario...'),
                    ],
                  ),
                ),
              );
              
              context.read<UsersBloc>().add(UpdateUserStatus(
                userId: user.id,
                status: newStatus,
              ));
              
              // Cerrar diálogos después de un breve delay
              Future.delayed(Duration(seconds: 1), () {
                Navigator.of(context).pop(); // Cerrar loading
                Navigator.of(context).pop(); // Cerrar detail dialog
                
                TBDialogHelper.showSuccess(
                  context,
                  title: 'Usuario actualizado',
                  message: 'El estado del usuario ha sido cambiado exitosamente.',
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? TBColors.error : TBColors.success,
            ),
            child: Text(
              isActive ? 'Suspender' : 'Activar',
              style: TextStyle(color: TBColors.white),
            ),
          ),
        ],
      ),
    );
  }
}