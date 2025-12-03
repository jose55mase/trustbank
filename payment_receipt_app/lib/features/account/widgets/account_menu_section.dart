import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/account_model.dart';
import '../widgets/documents_section.dart';
import '../../../services/user_service.dart';
import '../../../services/image_storage_service.dart';

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
  int imageCount = 0;
  bool isLoadingDocs = true;

  @override
  void initState() {
    super.initState();
    _loadUserDocuments();
    _loadImageCount();
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

  Future<void> _loadImageCount() async {
    try {
      int count = 0;
      if (await ImageStorageService.getDocumentFront() != null) count++;
      if (await ImageStorageService.getDocumentBack() != null) count++;
      if (await ImageStorageService.getClientPhoto() != null) count++;
      
      if (mounted) {
        setState(() {
          imageCount = count;
        });
      }
    } catch (e) {
      // Error loading image count
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
            subtitle: isLoadingDocs ? 'Cargando...' : '${userDocuments.length} docs, $imageCount imágenes',
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
      return const Icon(Icons.warning_amber, color: Colors.orange, size: 20);
    }
    
    final approvedDocs = userDocuments.where((doc) => doc['status']?.toString().toUpperCase() == 'APPROVED').length;
    final totalDocs = userDocuments.length;
    
    if (approvedDocs == totalDocs) {
      return const Icon(Icons.check_circle, color: TBColors.success, size: 20);
    } else {
      return const Icon(Icons.pending, color: Colors.orange, size: 20);
    }
  }

  Widget _getVerificationIcon() {
    final status = widget.account.accountStatus?.toUpperCase();
    switch (status) {
      case 'ACTIVE':
        return const Icon(Icons.verified, color: TBColors.success, size: 20);
      case 'PENDING':
        return const Icon(Icons.pending, color: Colors.orange, size: 20);
      case 'REJECTED':
        return const Icon(Icons.cancel, color: TBColors.error, size: 20);
      case 'SUSPENDED':
        return Icon(Icons.block, color: Colors.red.shade700, size: 20);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey, size: 20);
    }
  }

  void _showDocuments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DocumentsSection(),
    ).then((_) => _loadImageCount());
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
        child: const Padding(
          padding: EdgeInsets.all(TBSpacing.lg),
          child: Center(
            child: Text('Historial de cuenta - Próximamente'),
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
                'Estado de Verificación',
                style: TBTypography.headlineSmall,
              ),
              const SizedBox(height: TBSpacing.md),
              Text(
                'Estado actual: ${widget.account.statusLabel}',
                style: TBTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}