import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../services/document_service.dart';
import '../../../services/auth_service.dart';

class UploadDocumentImagesDialog extends StatefulWidget {
  const UploadDocumentImagesDialog({super.key});

  @override
  State<UploadDocumentImagesDialog> createState() => _UploadDocumentImagesDialogState();
}

class _UploadDocumentImagesDialogState extends State<UploadDocumentImagesDialog> {
  XFile? _documentFront;
  XFile? _documentBack;
  XFile? _clientPhoto;
  Uint8List? _documentFrontBytes;
  Uint8List? _documentBackBytes;
  Uint8List? _clientPhotoBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Subir Documentos', style: TBTypography.titleLarge),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageUpload(
              'Documento Frontal',
              _documentFront,
              () => _pickImage('front'),
              Icons.credit_card,
            ),
            const SizedBox(height: TBSpacing.md),
            _buildImageUpload(
              'Documento Reverso',
              _documentBack,
              () => _pickImage('back'),
              Icons.flip_to_back,
            ),
            const SizedBox(height: TBSpacing.md),
            _buildImageUpload(
              'Foto del Cliente',
              _clientPhoto,
              () => _pickImage('photo'),
              Icons.person,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TBButton(
          text: 'Subir',
          onPressed: _canUpload() ? _uploadDocuments : null,
        ),
      ],
    );
  }

  Widget _buildImageUpload(String title, XFile? image, VoidCallback onTap, IconData icon) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: TBColors.grey300),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        child: image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                    child: _buildImageWidget(title),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: TBColors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: TBColors.white, size: 16),
                        onPressed: () => _removeImage(title),
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: TBColors.grey500),
                  const SizedBox(height: TBSpacing.xs),
                  Text(
                    title,
                    style: TBTypography.bodySmall.copyWith(color: TBColors.grey600),
                  ),
                  Text(
                    'Toca para seleccionar',
                    style: TBTypography.labelSmall.copyWith(color: TBColors.grey500),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        switch (type) {
          case 'front':
            _documentFront = image;
            _documentFrontBytes = bytes;
            break;
          case 'back':
            _documentBack = image;
            _documentBackBytes = bytes;
            break;
          case 'photo':
            _clientPhoto = image;
            _clientPhotoBytes = bytes;
            break;
        }
      });
    }
  }

  void _removeImage(String title) {
    setState(() {
      if (title == 'Documento Frontal') {
        _documentFront = null;
        _documentFrontBytes = null;
      } else if (title == 'Documento Reverso') {
        _documentBack = null;
        _documentBackBytes = null;
      } else if (title == 'Foto del Cliente') {
        _clientPhoto = null;
        _clientPhotoBytes = null;
      }
    });
  }

  bool _canUpload() {
    return _documentFront != null || _documentBack != null || _clientPhoto != null;
  }

  Widget _buildImageWidget(String title) {
    Uint8List? bytes;
    switch (title) {
      case 'Documento Frontal':
        bytes = _documentFrontBytes;
        break;
      case 'Documento Reverso':
        bytes = _documentBackBytes;
        break;
      case 'Foto del Cliente':
        bytes = _clientPhotoBytes;
        break;
    }
    
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: double.infinity,
        height: 120,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox();
  }

  Future<void> _uploadDocuments() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Usuario no encontrado');
      
      // Simular subida exitosa
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documentos subidos exitosamente'),
            backgroundColor: TBColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: TBColors.error,
          ),
        );
      }
    }
  }
}