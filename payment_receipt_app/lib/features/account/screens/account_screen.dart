import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../bloc/account_bloc.dart';
import '../widgets/profile_header.dart';
import '../widgets/account_menu_section.dart';
import '../widgets/security_section.dart';
import '../widgets/support_section.dart';
import '../widgets/document_status_card.dart';
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
          centerTitle: true,
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: AuthService.getCurrentUser(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(TBColors.primary),
                ),
              );
            }
            
            final user = userSnapshot.data!;
            
            return BlocBuilder<AccountBloc, AccountState>(
              builder: (context, state) {
                if (state is AccountLoaded) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        ProfileHeader(user: user, account: state.account),
                        const SizedBox(height: TBSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: TBSpacing.screenPadding),
                          child: DocumentStatusCard(
                            fotoStatus: state.account.fotoStatus,
                            documentFromStatus: state.account.documentFromStatus,
                            documentBackStatus: state.account.documentBackStatus,
                          ),
                        ),
                        const SizedBox(height: TBSpacing.md),
                        AccountMenuSection(account: state.account),
                        const SizedBox(height: TBSpacing.md),
                        const SecuritySection(),
                        const SizedBox(height: TBSpacing.md),
                        const SupportSection(),
                        const SizedBox(height: TBSpacing.xl),
                      ],
                    ),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(TBColors.primary),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}