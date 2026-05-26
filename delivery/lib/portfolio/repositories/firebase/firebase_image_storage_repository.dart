import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../image_storage_repository.dart';

/// Firebase Storage implementation of [ImageStorageRepository].
///
/// Uses the `portfolio/` path in Firebase Storage.
class FirebaseImageStorageRepository implements ImageStorageRepository {
  final FirebaseStorage _storage;

  static const String _basePath = 'portfolio';
  static const int _maxSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> _allowedExtensions = ['png', 'jpg', 'jpeg', 'webp'];

  FirebaseImageStorageRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final ref = _storage.ref().child('$_basePath/$filename');
    final metadata = SettableMetadata(
      contentType: _getContentType(filename),
    );
    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  @override
  Future<void> deleteImage(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }

  @override
  Future<bool> validateImage(Uint8List bytes, String filename) async {
    if (bytes.length > _maxSizeBytes) return false;

    final extension = filename.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(extension)) return false;

    return true;
  }

  String _getContentType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
