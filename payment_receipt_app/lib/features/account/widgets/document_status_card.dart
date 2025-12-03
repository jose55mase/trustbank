import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';

class DocumentStatusCard extends StatelessWidget {
  final String? fotoStatus;
  final String? documentFromStatus;
  final String? documentBackStatus;

  const DocumentStatusCard({
    Key? key,
    this.fotoStatus,
    this.documentFromStatus,
    this.documentBackStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user, color: TBColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Estado de Documentos',
                  style: TBTypography.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDocumentRow('Foto de perfil', fotoStatus),
            const SizedBox(height: 8),
            _buildDocumentRow('Documento frontal', documentFromStatus),
            const SizedBox(height: 8),
            _buildDocumentRow('Documento trasero', documentBackStatus),
            const SizedBox(height: 16),
            _buildOverallStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(String title, String? status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status?.toUpperCase()) {
      case 'APPROVED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Aprobado';
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rechazado';
        break;
      case 'PENDING':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pendiente';
        break;
    }

    return Row(
      children: [
        Expanded(
          child: Text(title, style: TBTypography.bodyMedium),
        ),
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TBTypography.bodySmall.copyWith(color: statusColor),
        ),
      ],
    );
  }

  Widget _buildOverallStatus() {
    final allApproved = _isApproved(fotoStatus) && 
                      _isApproved(documentFromStatus) && 
                      _isApproved(documentBackStatus);
    
    final hasRejected = _isRejected(fotoStatus) || 
                       _isRejected(documentFromStatus) || 
                       _isRejected(documentBackStatus);

    Color backgroundColor;
    Color textColor;
    String message;
    IconData icon;

    if (allApproved) {
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      message = '✓ Todos los documentos han sido aprobados';
      icon = Icons.check_circle;
    } else if (hasRejected) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      message = '⚠ Algunos documentos fueron rechazados. Sube nuevos documentos.';
      icon = Icons.warning;
    } else {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      message = '⏳ Documentos en revisión. Te notificaremos cuando sean aprobados.';
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TBTypography.bodySmall.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  bool _isApproved(String? status) => status?.toUpperCase() == 'APPROVED';
  bool _isRejected(String? status) => status?.toUpperCase() == 'REJECTED';
}