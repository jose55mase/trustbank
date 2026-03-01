import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'image_preview_dialog.dart';

class ProductScanner extends StatelessWidget {
  final Function(String imagePath) onImageCaptured;

  const ProductScanner({super.key, required this.onImageCaptured});

  Future<void> _scanProduct(BuildContext context) async {
    final imagePicker = ImagePicker();
    
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => ImagePreviewDialog(
            imagePath: image.path,
            onConfirm: () {
              Navigator.pop(dialogContext);
              onImageCaptured(image.path);
            },
            onRetake: () {
              Navigator.pop(dialogContext);
              _scanProduct(context);
            },
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar imagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _scanProduct(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              'Escanear Producto',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
