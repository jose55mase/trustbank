import 'package:flutter/material.dart';

import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/request_model.dart';

class RequestDetailDialog extends StatelessWidget {
  final AdminRequest request;

  const RequestDetailDialog({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Detalles de solicitud', style: TBTypography.titleLarge),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('ID', request.id),
            _buildDetailRow('Tipo', request.typeLabel),
            _buildDetailRow('Usuario', request.userName),
            _buildDetailRow('Monto', '\$${request.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Estado', request.statusLabel),
            _buildDetailRow('Detalles', request.details),
            _buildDetailRow('Fecha creación', _formatDate(request.createdAt)),
            if (request.processedAt != null)
              _buildDetailRow('Fecha procesado', _formatDate(request.processedAt!)),
            if (request.adminNotes != null)
              _buildDetailRow('Notas admin', request.adminNotes!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TBSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TBTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: TBTypography.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}