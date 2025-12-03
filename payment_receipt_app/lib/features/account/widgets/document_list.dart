import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/account_model.dart';

class DocumentList extends StatelessWidget {
  final List<UserDocument> documents;

  const DocumentList({super.key, required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(TBSpacing.lg),
        decoration: BoxDecoration(
          color: TBColors.surface,
          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
          border: Border.all(color: TBColors.grey300),
        ),
        child: Column(
          children: [
            Icon(Icons.upload_file, size: 48, color: TBColors.grey500),
            const SizedBox(height: TBSpacing.sm),
            Text(
              'No hay documentos subidos',
              style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: documents.map((doc) => _buildDocumentCard(doc)).toList(),
    );
  }

  Widget _buildDocumentCard(UserDocument document) {
    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.sm),
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
      child: Row(
        children: [
          _buildDocumentIcon(document.type),
          const SizedBox(width: TBSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getTypeLabel(document.type), style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(document.fileName, style: TBTypography.labelMedium.copyWith(color: TBColors.grey600)),
                if (document.adminNotes != null)
                  Text(document.adminNotes!, style: TBTypography.labelMedium.copyWith(color: TBColors.grey600)),
              ],
            ),
          ),
          _buildStatusChip(document.status),
        ],
      ),
    );
  }

  Widget _buildDocumentIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'id':
        icon = Icons.badge;
        color = TBColors.primary;
        break;
      case 'proofOfAddress':
        icon = Icons.home;
        color = TBColors.secondary;
        break;
      case 'incomeProof':
        icon = Icons.attach_money;
        color = Colors.orange;
        break;
      case 'bankStatement':
        icon = Icons.account_balance;
        color = Colors.purple;
        break;
      default:
        icon = Icons.description;
        color = TBColors.grey500;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    
    switch (status.toLowerCase()) {
      case 'pending':
        color = TBColors.primary;
        break;
      case 'approved':
        color = TBColors.success;
        break;
      case 'rejected':
        color = TBColors.error;
        break;
      default:
        color = TBColors.grey500;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.sm, vertical: TBSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      ),
      child: Text(
        status.toUpperCase(),
        style: TBTypography.labelMedium.copyWith(color: color, fontSize: 10),
      ),
    );
  }
  
  String _getTypeLabel(String type) {
    switch (type) {
      case 'id':
        return 'Cédula/Pasaporte';
      case 'proofOfAddress':
        return 'Comprobante domicilio';
      case 'incomeProof':
        return 'Comprobante ingresos';
      case 'bankStatement':
        return 'Estado de cuenta';
      default:
        return 'Documento';
    }
  }
}