import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/credit_application.dart';
import '../bloc/credits_bloc.dart';
import '../bloc/credits_event.dart';
import '../bloc/credits_state.dart';
import 'credit_status_screen.dart';
import '../../../utils/currency_formatter.dart';

class MyCreditsScreen extends StatefulWidget {
  const MyCreditsScreen({super.key});

  @override
  State<MyCreditsScreen> createState() => _MyCreditsScreenState();
}

class _MyCreditsScreenState extends State<MyCreditsScreen> {
  late CreditsBloc _creditsBloc;

  @override
  void initState() {
    super.initState();
    _creditsBloc = CreditsBloc();
    _creditsBloc.add(LoadCreditApplications());
  }

  @override
  void dispose() {
    _creditsBloc.close();
    super.dispose();
  }

  Color _getStatusColor(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
      case CreditStatus.underReview:
        return TBColors.warning;
      case CreditStatus.approved:
      case CreditStatus.disbursed:
        return TBColors.success;
      case CreditStatus.rejected:
        return TBColors.error;
    }
  }

  IconData _getStatusIcon(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
        return Icons.schedule;
      case CreditStatus.underReview:
        return Icons.search;
      case CreditStatus.approved:
        return Icons.check_circle;
      case CreditStatus.rejected:
        return Icons.cancel;
      case CreditStatus.disbursed:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildCreditCard(CreditApplication application) {
    final statusColor = _getStatusColor(application.status);
    final statusIcon = _getStatusIcon(application.status);

    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.md),
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.surface,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: TBColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: TBSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.creditType,
                      style: TBTypography.titleMedium,
                    ),
                    Text(
                      application.statusText,
                      style: TBTypography.labelMedium.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(application.amount),
                style: TBTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: TBSpacing.md),
          Row(
            children: [
              _buildInfoChip('${application.termMonths} meses'),
              const SizedBox(width: TBSpacing.sm),
              _buildInfoChip('${application.interestRate}% EA'),
              const SizedBox(width: TBSpacing.sm),
              _buildInfoChip(_formatDate(application.applicationDate)),
            ],
          ),
          const SizedBox(height: TBSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreditStatusScreen(application: application),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: TBColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                ),
              ),
              child: Text('Ver detalles', style: TBTypography.buttonMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TBSpacing.sm,
        vertical: TBSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: TBColors.grey100,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      ),
      child: Text(
        text,
        style: TBTypography.labelSmall.copyWith(
          color: TBColors.grey600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _creditsBloc,
      child: Scaffold(
        backgroundColor: TBColors.background,
        appBar: AppBar(
          title: Text('Mis Créditos', style: TBTypography.headlineMedium),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _creditsBloc.add(LoadCreditApplications());
              },
            ),
          ],
        ),
        body: BlocBuilder<CreditsBloc, CreditsState>(
          builder: (context, state) {
            if (state is CreditsLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            if (state is CreditsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: TBColors.error,
                    ),
                    const SizedBox(height: TBSpacing.md),
                    Text(
                      'Error al cargar créditos',
                      style: TBTypography.titleLarge,
                    ),
                    const SizedBox(height: TBSpacing.sm),
                    Text(
                      state.message,
                      style: TBTypography.bodyMedium.copyWith(
                        color: TBColors.grey600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: TBSpacing.lg),
                    ElevatedButton(
                      onPressed: () {
                        _creditsBloc.add(LoadCreditApplications());
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            
            if (state is CreditsLoaded) {
              if (state.applications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card_off,
                        size: 64,
                        color: TBColors.grey400,
                      ),
                      const SizedBox(height: TBSpacing.md),
                      Text(
                        'No tienes créditos',
                        style: TBTypography.titleLarge,
                      ),
                      const SizedBox(height: TBSpacing.sm),
                      Text(
                        'Solicita tu primer crédito desde la pantalla principal',
                        style: TBTypography.bodyMedium.copyWith(
                          color: TBColors.grey600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(TBSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(TBSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: TBColors.primaryGradient,
                        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 Resumen de créditos',
                            style: TBTypography.headlineMedium.copyWith(
                              color: TBColors.white,
                            ),
                          ),
                          const SizedBox(height: TBSpacing.sm),
                          Text(
                            'Total de solicitudes: ${state.applications.length}',
                            style: TBTypography.bodyMedium.copyWith(
                              color: TBColors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TBSpacing.xl),
                    Text(
                      'Tus solicitudes',
                      style: TBTypography.titleLarge,
                    ),
                    const SizedBox(height: TBSpacing.md),
                    ...state.applications.map((application) => _buildCreditCard(application)),
                  ],
                ),
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}