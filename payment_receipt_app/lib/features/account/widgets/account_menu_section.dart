import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/account_model.dart';
import '../widgets/documents_section.dart';
import '../../../services/user_service.dart';

class AccountMenuSection extends StatefulWidget {
  final UserAccount account;

  const AccountMenuSection({
    super.key,
    required this.account,
  });

  @override
  State<AccountMenuSection> createState() => _AccountMenuSectionState();
}

class _AccountMenuSectionState extends State<AccountMenuSection> {
  List<dynamic> userDocuments = [];
  bool isLoadingDocs = true;

  @override
  void initState() {
    super.initState();
    _loadUserDocuments();
  }

  Future<void> _loadUserDocuments() async {
    try {
      final docs = await UserService.getUserDocuments();
      if (mounted) {
        setState(() {
          userDocuments = docs;
          isLoadingDocs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingDocs = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TBColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(TBSpacing.md),
            child: Text(
              'Mi Información',
              style: TBTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.description_outlined,
            title: 'Documentos',
            subtitle: isLoadingDocs ? 'Cargando...' : '${userDocuments.length} documentos subidos',
            onTap: () => _showDocuments(context),
            trailing: isLoadingDocs ? 
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ) : _getDocumentStatusIcon(),
          ),
          _buildDivider(),
          _buildMenuItem(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Límites de cuenta',
            subtitle: 'Ver límites y restricciones',
            onTap: () => _showLimits(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            context,
            icon: Icons.history,
            title: 'Historial de cuenta',
            subtitle: 'Ver cambios y actualizaciones',
            onTap: () => _showHistory(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            context,
            icon: Icons.verified_user_outlined,
            title: 'Estado de verificación',
            subtitle: widget.account.statusLabel,
            onTap: () => _showVerificationStatus(context),
            trailing: _getVerificationIcon(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TBSpacing.md,
          vertical: TBSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TBColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: TBColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: TBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TBTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TBTypography.bodySmall.copyWith(
                      color: TBColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right,
              color: TBColors.grey500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.md),
      child: Divider(
        height: 1,
        color: TBColors.grey300.withOpacity(0.5),
      ),
    );
  }

  Widget _getDocumentStatusIcon() {
    if (userDocuments.isEmpty) {
      return Icon(Icons.warning_amber, color: Colors.orange, size: 20);
    }
    
    final approvedDocs = userDocuments.where((doc) => doc['status']?.toString().toUpperCase() == 'APPROVED').length;
    final totalDocs = userDocuments.length;
    
    if (approvedDocs == totalDocs) {
      return Icon(Icons.check_circle, color: TBColors.success, size: 20);
    } else {
      return Icon(Icons.pending, color: Colors.orange, size: 20);
    }
  }

  Widget _getVerificationIcon() {
    switch (widget.account.status) {
      case AccountStatus.verified:
        return Icon(Icons.verified, color: TBColors.success, size: 20);
      case AccountStatus.pending:
        return Icon(Icons.pending, color: Colors.orange, size: 20);
      case AccountStatus.rejected:
        return Icon(Icons.cancel, color: TBColors.error, size: 20);
      case AccountStatus.suspended:
        return Icon(Icons.block, color: Colors.red.shade700, size: 20);
    }
  }

  void _showDocuments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DocumentsSection(),
    );
  }



  void _showLimits(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
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
                'Límites de Cuenta',
                style: TBTypography.headlineSmall,
              ),
              const SizedBox(height: TBSpacing.md),
              _buildLimitItem('Envío diario', '\$5,000'),
              _buildLimitItem('Envío mensual', '\$50,000'),
              _buildLimitItem('Recarga diaria', '\$10,000'),
              _buildLimitItem('Saldo máximo', '\$100,000'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLimitItem(String title, String limit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TBSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TBTypography.bodyMedium),
          Text(
            limit,
            style: TBTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: TBColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
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
                'Historial de Cuenta',
                style: TBTypography.headlineSmall,
              ),
              const SizedBox(height: TBSpacing.md),
              Text(
                'Aquí podrás ver todos los cambios y actualizaciones realizadas en tu cuenta.',
                style: TBTypography.bodyMedium.copyWith(
                  color: TBColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerificationStatus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
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
                'Estado de Verificación',
                style: TBTypography.headlineSmall,
              ),
              const SizedBox(height: TBSpacing.md),
              Container(
                padding: const EdgeInsets.all(TBSpacing.md),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.account.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(widget.account.status).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(widget.account.status),
                      color: _getStatusColor(widget.account.status),
                    ),
                    const SizedBox(width: TBSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.account.statusLabel,
                            style: TBTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getStatusDescription(widget.account.status),
                            style: TBTypography.bodySmall.copyWith(
                              color: TBColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AccountStatus status) {
    switch (status) {
      case AccountStatus.verified:
        return TBColors.success;
      case AccountStatus.pending:
        return Colors.orange;
      case AccountStatus.rejected:
        return TBColors.error;
      case AccountStatus.suspended:
        return Colors.red.shade700;
    }
  }

  IconData _getStatusIcon(AccountStatus status) {
    switch (status) {
      case AccountStatus.verified:
        return Icons.verified;
      case AccountStatus.pending:
        return Icons.pending;
      case AccountStatus.rejected:
        return Icons.cancel;
      case AccountStatus.suspended:
        return Icons.block;
    }
  }

  String _getStatusDescription(AccountStatus status) {
    switch (status) {
      case AccountStatus.verified:
        return 'Tu cuenta está completamente verificada';
      case AccountStatus.pending:
        return 'Tu cuenta está en proceso de verificación';
      case AccountStatus.rejected:
        return 'Tu cuenta ha sido rechazada. Contacta soporte';
      case AccountStatus.suspended:
        return 'Tu cuenta está suspendida temporalmente';
    }
  }
}