import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB

  static Future<Uint8List?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    return await _processImage(image);
  }

  static Future<Uint8List?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    return await _processImage(image);
  }

  static Future<List<Uint8List>> pickMultipleImages() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    List<Uint8List> imageBytes = [];
    
    for (XFile image in images) {
      final bytes = await _processImage(image);
      if (bytes != null) {
        imageBytes.add(bytes);
      }
    }
    
    return imageBytes;
  }

  static Future<Uint8List?> _processImage(XFile? image) async {
    if (image == null) return null;
    
    final bytes = await image.readAsBytes();
    
    // Validar tamaño del archivo
    if (bytes.length > maxFileSize) {
      throw Exception('La imagen es muy grande. Máximo 5MB permitido.');
    }
    
    // Validar que sea una imagen válida
    final String mimeType = image.mimeType ?? '';
    if (!mimeType.startsWith('image/')) {
      throw Exception('El archivo seleccionado no es una imagen válida.');
    }
    
    return bytes;
  }
}