import 'dart:typed_data';

/// Abstract repository interface for image storage operations.
abstract class ImageStorageRepository {
  /// Uploads an image and returns the download URL.
  ///
  /// [bytes] is the raw image data.
  /// [filename] is the desired filename (used for path and content type detection).
  Future<String> uploadImage(Uint8List bytes, String filename);

  /// Deletes an image by its download URL.
  Future<void> deleteImage(String url);

  /// Validates an image file before upload.
  ///
  /// Returns true if the file format is PNG, JPG, or WebP
  /// and the size does not exceed 5 MB.
  Future<bool> validateImage(Uint8List bytes, String filename);
}
