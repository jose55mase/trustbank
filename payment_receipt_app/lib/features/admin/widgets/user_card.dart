import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/user_model.dart';

class UserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onTap;

  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: TBSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(TBSpacing.md),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: _getStatusColor().withOpacity(0.2),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: TBTypography.titleLarge.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: TBSpacing.md),
              // Info del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TBTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TBTypography.bodyMedium.copyWith(
                        color: TBColors.grey600,
                      ),
                    ),
                    const SizedBox(height: TBSpacing.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TBSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: TBTypography.labelMedium.copyWith(
                              color: _getStatusColor(),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: TBSpacing.sm),
                        Text(
                          'Saldo: \$${user.balance.toStringAsFixed(2)}',
                          style: TBTypography.labelMedium.copyWith(
                            color: TBColors.grey600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Fecha de registro
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(user.createdAt),
                    style: TBTypography.labelMedium.copyWith(
                      color: TBColors.grey500,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: TBSpacing.xs),
                  Icon(
                    Icons.chevron_right,
                    color: TBColors.grey600,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
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
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Ayer';
    } else if (difference < 30) {
      return 'Hace $difference días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}