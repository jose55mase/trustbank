import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../bloc/account_bloc.dart';
import '../models/account_model.dart';
import '../widgets/account_status_card.dart';
import '../widgets/document_list.dart';
import '../widgets/upload_document_dialog.dart';
import '../../../services/auth_service.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountBloc()..add(LoadAccount()),
      child: Scaffold(
        backgroundColor: TBColors.background,
        appBar: AppBar(
          title: Text('Mi Cuenta', style: TBTypography.headlineMedium),
          backgroundColor: TBColors.primary,
          foregroundColor: TBColors.white,
          elevation: 0,
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: AuthService.getCurrentUser(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final user = userSnapshot.data!;
            
            return BlocBuilder<AccountBloc, AccountState>(
              builder: (context, state) {
                if (state is AccountLoaded) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(TBSpacing.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserInfoCard(user),
                        const SizedBox(height: TBSpacing.lg),
                        AccountStatusCard(account: state.account),
                        const SizedBox(height: TBSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Documentos', style: TBTypography.titleLarge),
                            TBButton(
                              text: 'Subir documento',
                              type: TBButtonType.outline,
                              onPressed: () => _showUploadDialog(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: TBSpacing.md),
                        DocumentList(documents: state.account.documents),
                      ],
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(Map<String, dynamic> user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(TBSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: TBColors.primary.withOpacity(0.2),
                  child: Text(
                    (user['fistName'] ?? user['firstName'] ?? 'U')[0].toUpperCase(),
                    style: TBTypography.headlineMedium.copyWith(
                      color: TBColors.primary,
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
                        '${user['fistName'] ?? user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
                        style: TBTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user['email'] ?? '',
                        style: TBTypography.bodyMedium.copyWith(
                          color: TBColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TBSpacing.md),
            _buildInfoRow('ID', user['id']?.toString() ?? ''),
            _buildInfoRow('Usuario', user['username'] ?? ''),
            _buildInfoRow('Documento', user['document'] ?? 'No especificado'),
            _buildInfoRow('Estado', _getStatusText(user['accountStatus'])),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TBSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TBTypography.bodyMedium.copyWith(
                color: TBColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TBTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  String _getStatusText(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return 'Activo';
      case 'INACTIVE':
        return 'Inactivo';
      case 'SUSPENDED':
        return 'Suspendido';
      case 'PENDING':
        return 'Pendiente';
      default:
        return status ?? 'No especificado';
    }
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AccountBloc>(),
        child: const UploadDocumentDialog(),
      ),
    );
  }
}