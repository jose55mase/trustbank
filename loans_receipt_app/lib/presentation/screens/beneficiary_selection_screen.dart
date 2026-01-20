import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../molecules/beneficiary_card.dart';

class BeneficiarySelectionScreen extends StatefulWidget {
  const BeneficiarySelectionScreen({super.key});

  @override
  State<BeneficiarySelectionScreen> createState() => _BeneficiarySelectionScreenState();
}

class _BeneficiarySelectionScreenState extends State<BeneficiarySelectionScreen> {
  int? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seleccionar Beneficiario'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Quién recibirá el préstamo?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona una opción para continuar',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            BeneficiaryCard(
              title: 'Beneficiarios de ley',
              description: 'Recibirán la indemnización según la ley (cónyuge, hijos, padres o hermanos)',
              isSelected: selectedOption == 0,
              onTap: () => setState(() => selectedOption = 0),
              onMoreInfo: () {
                _showInfoDialog(
                  'Beneficiarios de ley',
                  'Los beneficiarios de ley son aquellos establecidos por la legislación vigente. En orden de prioridad: cónyuge, hijos, padres y hermanos.',
                );
              },
            ),
            BeneficiaryCard(
              title: 'Beneficiario designado',
              description: 'Persona específica que designes como beneficiario del préstamo',
              isSelected: selectedOption == 1,
              onTap: () => setState(() => selectedOption = 1),
              onMoreInfo: () {
                _showInfoDialog(
                  'Beneficiario designado',
                  'Puedes designar a cualquier persona de tu confianza como beneficiario. Esta persona recibirá el préstamo en caso de fallecimiento.',
                );
              },
            ),
            BeneficiaryCard(
              title: 'Múltiples beneficiarios',
              description: 'Distribuye el préstamo entre varias personas con porcentajes específicos',
              isSelected: selectedOption == 2,
              onTap: () => setState(() => selectedOption = 2),
              onMoreInfo: () {
                _showInfoDialog(
                  'Múltiples beneficiarios',
                  'Puedes designar varios beneficiarios y asignar un porcentaje específico a cada uno. La suma debe ser 100%.',
                );
              },
            ),
            BeneficiaryCard(
              title: 'Sin beneficiario',
              description: 'El préstamo será manejado según las políticas de la institución',
              isSelected: selectedOption == 3,
              onTap: () => setState(() => selectedOption = 3),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedOption != null
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opción ${selectedOption! + 1} seleccionada'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
