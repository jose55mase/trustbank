import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';

class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({super.key});

  @override
  State<DocumentManagementScreen> createState() => _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  final List<Map<String, dynamic>> _pendingDocuments = [
    {
      'id': '2',
      'type': 'proofOfAddress',
      'fileName': 'recibo_luz.pdf',
      'filePath': '/documents/recibo_luz.pdf',
      'status': 'pending',
      'uploadedAt': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'id': '3',
      'type': 'incomeProof',
      'fileName': 'certificado_ingresos.pdf',
      'filePath': '/documents/certificado_ingresos.pdf',
      'status': 'pending',
      'uploadedAt': DateTime.now().subtract(const Duration(hours: 2)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      appBar: AppBar(
        title: Text('Gestión Documentos', style: TBTypography.headlineMedium),
        backgroundColor: TBColors.primary,
        foregroundColor: TBColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TBSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documentos pendientes', style: TBTypography.titleLarge),
            const SizedBox(height: TBSpacing.md),
            ..._pendingDocuments.map((doc) => _buildDocumentCard(doc)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
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
              _buildDocumentIcon(document['type']),
              const SizedBox(width: TBSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getTypeLabel(document['type']), style: TBTypography.titleLarge),
                    Text(document['fileName'], style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600)),
                    Text('Subido: ${_formatDate(document['uploadedAt'])}', style: TBTypography.labelMedium.copyWith(color: TBColors.grey600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TBSpacing.md),
          Row(
            children: [
              Expanded(
                child: TBButton(
                  text: 'Aprobar',
                  onPressed: () => _processDocument(document, 'approved'),
                ),
              ),
              const SizedBox(width: TBSpacing.sm),
              Expanded(
                child: TBButton(
                  text: 'Rechazar',
                  type: TBButtonType.outline,
                  onPressed: () => _showRejectDialog(document),
                ),
              ),
            ],
          ),
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
        color = TBColors.primary;
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

  void _processDocument(Map<String, dynamic> document, String status) {
    setState(() {
      _pendingDocuments.removeWhere((d) => d['id'] == document['id']);
    });
    final isApproved = status == 'approved';
    TBDialogHelper.showSuccess(
      context,
      title: isApproved ? 'Documento aprobado' : 'Documento procesado',
      message: isApproved 
        ? 'El documento ha sido aprobado exitosamente.'
        : 'El documento ha sido procesado.',
    );
  }

  void _showRejectDialog(Map<String, dynamic> document) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rechazar documento', style: TBTypography.titleLarge),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TBButton(
            text: 'Rechazar',
            onPressed: () {
              setState(() {
                _pendingDocuments.removeWhere((d) => d['id'] == document['id']);
              });
              Navigator.pop(context);
              TBDialogHelper.showInfo(
                context,
                title: 'Documento rechazado',
                message: 'El documento ha sido rechazado. El usuario recibirá una notificación con los detalles.',
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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