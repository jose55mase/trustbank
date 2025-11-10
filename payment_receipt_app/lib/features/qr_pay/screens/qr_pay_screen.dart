import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';

class QRPayScreen extends StatelessWidget {
  const QRPayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      appBar: AppBar(
        title: Text('Pagar con QR', style: TBTypography.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(TBSpacing.screenPadding),
        child: Column(
          children: [
            const SizedBox(height: TBSpacing.xl),
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: TBColors.surface,
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: TBColors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 120,
                    color: TBColors.primary,
                  ),
                  const SizedBox(height: TBSpacing.md),
                  Text(
                    'Código QR',
                    style: TBTypography.titleLarge.copyWith(
                      color: TBColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TBSpacing.xl),
            Text(
              'Escanea el código QR del comercio\no muestra tu código para recibir pagos',
              style: TBTypography.bodyLarge.copyWith(
                color: TBColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            TBButton(
              text: 'Escanear QR',
              fullWidth: true,
              onPressed: () {
                TBDialogHelper.showInfo(
                  context,
                  title: 'Próximamente',
                  message: 'La funcionalidad de escaneo QR estará disponible en una próxima actualización.',
                );
              },
            ),
            const SizedBox(height: TBSpacing.md),
            TBButton(
              text: 'Mi código QR',
              type: TBButtonType.outline,
              fullWidth: true,
              onPressed: () {
                TBDialogHelper.showInfo(
                  context,
                  title: 'Próximamente',
                  message: 'Tu código QR personal estará disponible en una próxima actualización.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}