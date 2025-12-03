import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  static Future<Uint8List?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return await image.readAsBytes();
    }
    return null;
  }

  static Future<Uint8List?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      return await image.readAsBytes();
    }
    return null;
  }

  static Future<List<Uint8List>> pickMultipleImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    List<Uint8List> imageBytes = [];
    
    for (XFile image in images) {
      final bytes = await image.readAsBytes();
      imageBytes.add(bytes);
    }
    
    return imageBytes;
  }
}