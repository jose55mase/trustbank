import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../models/request_model.dart';
import 'request_detail_dialog.dart';

class RequestCard extends StatelessWidget {
  final AdminRequest request;
  final Function(RequestStatus, String?) onProcess;

  const RequestCard({
    super.key,
    required this.request,
    required this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
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
              _buildTypeIcon(),
              const SizedBox(width: TBSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.typeLabel, style: TBTypography.titleLarge),
                    Text(request.userName, style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600)),
                  ],
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: TBSpacing.sm),
          Row(
            children: [
              Text('Monto: ', style: TBTypography.labelMedium),
              Text('\$${request.amount.toStringAsFixed(2)}', style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: TBSpacing.xs),
          Text(request.details, style: TBTypography.labelMedium.copyWith(color: TBColors.grey600)),
          const SizedBox(height: TBSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TBButton(
                  text: 'Ver detalles',
                  type: TBButtonType.outline,
                  onPressed: () => _showDetails(context),
                ),
              ),
              if (request.status == RequestStatus.pending) ...[
                const SizedBox(width: TBSpacing.sm),
                Expanded(
                  child: TBButton(
                    text: 'Procesar',
                    onPressed: () => _showProcessDialog(context),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;
    
    switch (request.type) {
      case RequestType.sendMoney:
        icon = Icons.send;
        color = TBColors.primary;
        break;
      case RequestType.recharge:
        icon = Icons.add_circle;
        color = TBColors.secondary;
        break;
      case RequestType.credit:
        icon = Icons.credit_card;
        color = Colors.orange;
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

  Widget _buildStatusChip() {
    Color color;
    
    switch (request.status) {
      case RequestStatus.pending:
        color = TBColors.primary;
        break;
      case RequestStatus.approved:
        color = TBColors.success;
        break;
      case RequestStatus.rejected:
        color = TBColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.sm, vertical: TBSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      ),
      child: Text(
        request.statusLabel,
        style: TBTypography.labelMedium.copyWith(color: color, fontSize: 10),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RequestDetailDialog(request: request),
    );
  }

  void _showProcessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ProcessDialog(
        request: request,
        onProcess: onProcess,
      ),
    );
  }
}

class _ProcessDialog extends StatefulWidget {
  final AdminRequest request;
  final Function(RequestStatus, String?) onProcess;

  const _ProcessDialog({required this.request, required this.onProcess});

  @override
  State<_ProcessDialog> createState() => _ProcessDialogState();
}

class _ProcessDialogState extends State<_ProcessDialog> {
  final _notesController = TextEditingController();
  RequestStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Procesar solicitud', style: TBTypography.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.request.typeLabel} - \$${widget.request.amount.toStringAsFixed(2)}'),
          const SizedBox(height: TBSpacing.md),
          DropdownButtonFormField<RequestStatus>(
            decoration: const InputDecoration(labelText: 'Decisión'),
            items: [
              DropdownMenuItem(value: RequestStatus.approved, child: Text('Aprobar')),
              DropdownMenuItem(value: RequestStatus.rejected, child: Text('Rechazar')),
            ],
            onChanged: (value) => setState(() => _selectedStatus = value),
          ),
          const SizedBox(height: TBSpacing.md),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TBButton(
          text: 'Procesar',
          onPressed: _selectedStatus != null ? () {
            widget.onProcess(_selectedStatus!, _notesController.text.isEmpty ? null : _notesController.text);
            Navigator.pop(context);
          } : null,
        ),
      ],
    );
  }
}