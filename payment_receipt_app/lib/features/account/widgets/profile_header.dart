import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/account_model.dart';
import '../../../services/user_service.dart';

class ProfileHeader extends StatefulWidget {
  final Map<String, dynamic> user;
  final UserAccount account;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.account,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserService.getUserProfile();
      if (mounted) {
        setState(() {
          userProfile = profile;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = userProfile ?? widget.user;
    final userName = profile['firstName'] ?? profile['name'] ?? profile['username'] ?? 'Usuario';
    final userEmail = profile['email'] ?? 'email@ejemplo.com';
    final userPhone = profile['phone'] ?? profile['phoneNumber'] ?? 'No disponible';
    final userRole = UserService.formatUserRole(profile['role']);
    final accountStatus = UserService.formatAccountStatus(profile['accountStatus']);
    final createdAt = profile['createdAt'] ?? profile['registrationDate'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: TBColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TBSpacing.lg),
        child: Column(
          children: [
            // Avatar y estado
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: TBColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: TBColors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: TBColors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(width: TBSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TBTypography.headlineSmall.copyWith(
                          color: TBColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getAccountStatusColor(profile['accountStatus']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              accountStatus,
                              style: TBTypography.labelSmall.copyWith(
                                color: TBColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: TBColors.secondary.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              userRole,
                              style: TBTypography.labelSmall.copyWith(
                                color: TBColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditProfile(context),
                  icon: Icon(
                    Icons.info_outline,
                    color: TBColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TBSpacing.lg),
            // Información de contacto
            if (isLoading)
              Container(
                padding: const EdgeInsets.all(TBSpacing.md),
                decoration: BoxDecoration(
                  color: TBColors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(TBColors.white),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(TBSpacing.md),
                decoration: BoxDecoration(
                  color: TBColors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TBColors.white.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.email_outlined, userEmail),
                    const SizedBox(height: TBSpacing.sm),
                    _buildInfoRow(Icons.phone_outlined, userPhone),
                    const SizedBox(height: TBSpacing.sm),
                    _buildInfoRow(
                      Icons.calendar_today_outlined,
                      'Miembro desde ${UserService.formatDate(createdAt)}',
                    ),
                    if (profile['lastLogin'] != null) ...[
                      const SizedBox(height: TBSpacing.sm),
                      _buildInfoRow(
                        Icons.access_time,
                        'Último acceso: ${UserService.formatDate(profile['lastLogin'])}',
                      ),
                    ],
                    if (profile['balance'] != null) ...[
                      const SizedBox(height: TBSpacing.sm),
                      _buildInfoRow(
                        Icons.account_balance_wallet,
                        'Saldo: \$${(profile['balance'] ?? 0.0).toStringAsFixed(2)}',
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: TBColors.white.withOpacity(0.8),
        ),
        const SizedBox(width: TBSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TBTypography.bodySmall.copyWith(
              color: TBColors.white.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }

  Color _getAccountStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'VERIFIED':
        return TBColors.success;
      case 'PENDING':
        return Colors.orange;
      case 'INACTIVE':
      case 'REJECTED':
        return TBColors.error;
      case 'SUSPENDED':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  void _showEditProfile(BuildContext context) {
    final profile = userProfile ?? widget.user;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: TBColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TBSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TBColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: TBSpacing.lg),
              Text(
                'Información del Perfil',
                style: TBTypography.headlineSmall,
              ),
              const SizedBox(height: TBSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileField('ID de Usuario', profile['id']?.toString() ?? 'N/A'),
                      _buildProfileField('Nombre', profile['firstName'] ?? 'N/A'),
                      _buildProfileField('Apellido', profile['lastName'] ?? 'N/A'),
                      _buildProfileField('Email', profile['email'] ?? 'N/A'),
                      _buildProfileField('Teléfono', profile['phone'] ?? profile['phoneNumber'] ?? 'N/A'),
                      _buildProfileField('Rol', UserService.formatUserRole(profile['role'])),
                      _buildProfileField('Estado', UserService.formatAccountStatus(profile['accountStatus'])),
                      _buildProfileField('Fecha de Registro', UserService.formatDate(profile['createdAt'] ?? profile['registrationDate'])),
                      if (profile['lastLogin'] != null)
                        _buildProfileField('Último Acceso', UserService.formatDate(profile['lastLogin'])),
                      if (profile['balance'] != null)
                        _buildProfileField('Saldo Actual', '\$${(profile['balance'] ?? 0.0).toStringAsFixed(2)}'),
                      if (profile['address'] != null)
                        _buildProfileField('Dirección', profile['address']),
                      if (profile['dateOfBirth'] != null)
                        _buildProfileField('Fecha de Nacimiento', UserService.formatDate(profile['dateOfBirth'])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.md),
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TBColors.grey300.withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TBTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: TBColors.grey600,
              ),
            ),
          ),
          const SizedBox(width: TBSpacing.md),
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
}