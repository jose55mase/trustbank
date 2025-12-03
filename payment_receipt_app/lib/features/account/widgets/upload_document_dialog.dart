import 'package:flutter/material.dart';

import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';



import 'upload_document_images_dialog.dart';

class UploadDocumentDialog extends StatefulWidget {
  const UploadDocumentDialog({super.key});

  @override
  State<UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<UploadDocumentDialog> {
  String? _selectedType;
  String _fileName = '';

  final List<String> _documentTypes = [
    'id',
    'proofOfAddress',
    'incomeProof',
    'bankStatement',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Subir documento', style: TBTypography.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TBButton(
                  text: 'Documentos con Fotos',
                  type: TBButtonType.outline,
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => const UploadDocumentImagesDialog(),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: TBSpacing.md),
          const Divider(),
          const SizedBox(height: TBSpacing.md),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Tipo de documento',
              border: OutlineInputBorder(),
            ),
            items: _documentTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getTypeLabel(type)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedType = value),
          ),
          const SizedBox(height: TBSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TBSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: TBColors.grey300),
              borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload, size: 48, color: TBColors.grey500),
                const SizedBox(height: TBSpacing.sm),
                Text(
                  _fileName.isEmpty ? 'Seleccionar archivo' : _fileName,
                  style: TBTypography.bodyMedium.copyWith(
                    color: _fileName.isEmpty ? TBColors.grey600 : TBColors.black,
                  ),
                ),
                const SizedBox(height: TBSpacing.sm),
                TBButton(
                  text: 'Examinar',
                  type: TBButtonType.outline,
                  onPressed: _selectFile,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TBButton(
          text: 'Subir',
          onPressed: _canUpload() ? _uploadDocument : null,
        ),
      ],
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

  void _selectFile() {
    // Simulación de selección de archivo
    setState(() {
      _fileName = 'documento_${DateTime.now().millisecondsSinceEpoch}.pdf';
    });
  }

  bool _canUpload() {
    return _selectedType != null && _fileName.isNotEmpty;
  }

  void _uploadDocument() {
    if (_canUpload()) {
      // Simulate document upload
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Documento $_fileName subido exitosamente')),
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Documento subido exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}