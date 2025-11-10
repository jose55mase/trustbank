import 'package:flutter/material.dart';
import '../design_system/colors/tb_colors.dart';
import '../design_system/typography/tb_typography.dart';
import '../design_system/spacing/tb_spacing.dart';
import '../design_system/components/tb_button.dart';
import '../design_system/components/tb_card.dart';
import '../design_system/components/tb_input.dart';
import '../design_system/components/tb_balance_card.dart';
import '../design_system/components/tb_action_button.dart';
import '../design_system/components/tb_transaction_item.dart';

class DesignSystemShowcase extends StatefulWidget {
  const DesignSystemShowcase({super.key});

  @override
  State<DesignSystemShowcase> createState() => _DesignSystemShowcaseState();
}

class _DesignSystemShowcaseState extends State<DesignSystemShowcase> {
  bool _showBalance = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      appBar: AppBar(
        title: Text(
          'TrustBank Design System',
          style: TBTypography.headlineMedium.copyWith(color: TBColors.white),
        ),
        backgroundColor: TBColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TBSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            TBBalanceCard(
              balance: '1,250,000',
              currency: 'COP',
              subtitle: 'Última actualización: Hoy 2:30 PM',
              showBalance: _showBalance,
              onToggleVisibility: () {
                setState(() {
                  _showBalance = !_showBalance;
                });
              },
              actions: [
                TBActionButton(
                  icon: Icons.send,
                  label: 'Enviar',
                  onPressed: () {},
                ),
                TBActionButton(
                  icon: Icons.add,
                  label: 'Recargar',
                  onPressed: () {},
                ),
              ],
            ),
            
            const SizedBox(height: TBSpacing.sectionSpacing),
            
            // Buttons Section
            Text(
              'Botones',
              style: TBTypography.headlineSmall,
            ),
            const SizedBox(height: TBSpacing.md),
            
            Wrap(
              spacing: TBSpacing.md,
              runSpacing: TBSpacing.md,
              children: [
                TBButton(
                  text: 'Primary',
                  onPressed: () {},
                ),
                TBButton(
                  text: 'Secondary',
                  type: TBButtonType.secondary,
                  onPressed: () {},
                ),
                TBButton(
                  text: 'Outline',
                  type: TBButtonType.outline,
                  onPressed: () {},
                ),
                TBButton(
                  text: 'Ghost',
                  type: TBButtonType.ghost,
                  onPressed: () {},
                ),
              ],
            ),
            
            const SizedBox(height: TBSpacing.sectionSpacing),
            
            // Input Section
            Text(
              'Campos de entrada',
              style: TBTypography.headlineSmall,
            ),
            const SizedBox(height: TBSpacing.md),
            
            const TBInput(
              label: 'Email',
              hint: 'Ingresa tu email',
              prefixIcon: Icon(Icons.email),
            ),
            
            const SizedBox(height: TBSpacing.md),
            
            const TBInput(
              label: 'Contraseña',
              hint: 'Ingresa tu contraseña',
              obscureText: true,
              prefixIcon: Icon(Icons.lock),
            ),
            
            const SizedBox(height: TBSpacing.sectionSpacing),
            
            // Cards Section
            Text(
              'Tarjetas',
              style: TBTypography.headlineSmall,
            ),
            const SizedBox(height: TBSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: TBCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 32,
                          color: TBColors.primary,
                        ),
                        const SizedBox(height: TBSpacing.sm),
                        Text(
                          'Elevated Card',
                          style: TBTypography.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: TBSpacing.md),
                Expanded(
                  child: TBCard(
                    type: TBCardType.outlined,
                    child: Column(
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 32,
                          color: TBColors.secondary,
                        ),
                        const SizedBox(height: TBSpacing.sm),
                        Text(
                          'Outlined Card',
                          style: TBTypography.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: TBSpacing.sectionSpacing),
            
            // Transactions Section
            Text(
              'Transacciones',
              style: TBTypography.headlineSmall,
            ),
            const SizedBox(height: TBSpacing.md),
            
            const TBTransactionItem(
              title: 'Pago recibido',
              subtitle: 'Juan Pérez',
              amount: '150,000',
              date: 'Hoy',
              type: TBTransactionType.income,
              icon: Icons.person,
            ),
            
            const TBTransactionItem(
              title: 'Compra en línea',
              subtitle: 'Amazon',
              amount: '89,500',
              date: 'Ayer',
              type: TBTransactionType.expense,
              icon: Icons.shopping_cart,
            ),
            
            const TBTransactionItem(
              title: 'Transferencia',
              subtitle: 'A María García',
              amount: '50,000',
              date: '2 días',
              type: TBTransactionType.transfer,
              icon: Icons.send,
            ),
          ],
        ),
      ),
    );
  }
}