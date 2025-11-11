import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../bloc/account_bloc.dart';

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
                        AccountStatusCard(account: state.account, userData: user),
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