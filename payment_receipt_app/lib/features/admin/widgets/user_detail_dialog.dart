import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../models/user_model.dart';
import '../bloc/users_bloc.dart';

class UserDetailDialog extends StatelessWidget {
  final AdminUser user;

  const UserDetailDialog({super.key, required this.user});

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
            
            const SizedBox(height: TBSpacing.lg),
            
            // Acciones
            Row(
              children: [
                Expanded(
                  child: TBButton(
                    text: user.accountStatus.toLowerCase() == 'active' ? 'Suspender' : 'Activar',
                    type: user.accountStatus.toLowerCase() == 'active' 
                        ? TBButtonType.secondary 
                        : TBButtonType.primary,
                    onPressed: () {
                      final newStatus = user.accountStatus.toLowerCase() == 'active' 
                          ? UserStatus.suspended 
                          : UserStatus.active;
                      
                      context.read<UsersBloc>().add(UpdateUserStatus(
                        userId: user.id,
                        status: newStatus,
                      ));
                      Navigator.of(context).pop();
                    },
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
}