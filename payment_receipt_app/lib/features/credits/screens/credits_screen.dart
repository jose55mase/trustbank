import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/credit_option.dart';
import 'credit_simulation_screen.dart';
import 'my_credits_screen.dart';
import '../../../services/api_service.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final creditOptions = [
      CreditOption(
        title: 'Crédito Personal',
        description: 'Para tus proyectos personales',
        minAmount: 500,
        maxAmount: 10000,
        minTermMonths: 6,
        maxTermMonths: 36,
        interestRate: 12.5,
        icon: '👤',
      ),
      CreditOption(
        title: 'Crédito Vehicular',
        description: 'Compra tu vehículo soñado',
        minAmount: 5000,
        maxAmount: 50000,
        minTermMonths: 12,
        maxTermMonths: 72,
        interestRate: 8.9,
        icon: '🚗',
      ),
      CreditOption(
        title: 'Crédito Hipotecario',
        description: 'Tu casa propia te espera',
        minAmount: 20000,
        maxAmount: 300000,
        minTermMonths: 60,
        maxTermMonths: 360,
        interestRate: 6.5,
        icon: '🏠',
      ),
    ];

    return Scaffold(
      backgroundColor: TBColors.background,
      appBar: AppBar(
        title: Text('Créditos TrustBank', style: TBTypography.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyCreditsScreen(),
                ),
              );
            },
            tooltip: 'Mis solicitudes',
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    '💰 Haz realidad tus sueños',
                    style: TBTypography.headlineMedium.copyWith(
                      color: TBColors.white,
                    ),
                  ),
                  const SizedBox(height: TBSpacing.sm),
                  Text(
                    'Encuentra el crédito perfecto para ti con las mejores tasas del mercado',
                    style: TBTypography.bodyMedium.copyWith(
                      color: TBColors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TBSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nuestros productos',
                  style: TBTypography.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyCreditsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history, size: 16),
                  label: Text(
                    'Mis solicitudes',
                    style: TBTypography.labelMedium.copyWith(
                      color: TBColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TBSpacing.md),
            ...creditOptions.map((option) => _buildCreditCard(context, option)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(BuildContext context, CreditOption option) {
    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.md),
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.surface,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
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
              Text(
                option.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: TBSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TBTypography.titleLarge,
                    ),
                    Text(
                      option.description,
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
          Row(
            children: [
              _buildInfoChip('Desde \$${option.minAmount.toInt()}'),
              const SizedBox(width: TBSpacing.sm),
              _buildInfoChip('${option.interestRate}% EA'),
            ],
          ),
          const SizedBox(height: TBSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final response = await ApiService.simulateCredit({
                    'creditType': option.title,
                    'amount': option.minAmount,
                    'termMonths': option.minTermMonths,
                    'interestRate': option.interestRate,
                  });
                  
                  if (response['status'] == 200) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreditSimulationScreen(creditOption: option),
                      ),
                    );
                  } else {
                    TBDialogHelper.showError(
                      context,
                      title: 'Error en simulación',
                      message: response['message'] ?? 'No se pudo simular el crédito',
                    );
                  }
                } catch (e) {
                  TBDialogHelper.showError(
                    context,
                    title: 'Error de conexión',
                    message: e.toString().replaceAll('Exception: ', ''),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TBColors.primary,
                foregroundColor: TBColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                ),
              ),
              child: Text('Simular', style: TBTypography.buttonMedium),
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
        color: TBColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      ),
      child: Text(
        text,
        style: TBTypography.labelMedium.copyWith(
          color: TBColors.primary,
        ),
      ),
    );
  }
}