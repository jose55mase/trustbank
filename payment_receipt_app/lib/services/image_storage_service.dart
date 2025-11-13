import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ImageStorageService {
  static const String _keyDocumentFront = 'document_front_image';
  static const String _keyDocumentBack = 'document_back_image';
  static const String _keyClientPhoto = 'client_photo_image';
  static const String _keyDocumentFrontStatus = 'document_front_status';
  static const String _keyDocumentBackStatus = 'document_back_status';
  static const String _keyClientPhotoStatus = 'client_photo_status';

  static Future<void> saveImage(String key, Uint8List imageBytes) async {
    final prefs = await SharedPreferences.getInstance();
    final base64String = base64Encode(imageBytes);
    await prefs.setString(key, base64String);
  }

  static Future<Uint8List?> getImage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final base64String = prefs.getString(key);
    if (base64String != null) {
      return base64Decode(base64String);
    }
    return null;
  }

  static Future<void> saveDocumentFront(Uint8List imageBytes) async {
    await saveImage(_keyDocumentFront, imageBytes);
  }

  static Future<void> saveDocumentBack(Uint8List imageBytes) async {
    await saveImage(_keyDocumentBack, imageBytes);
  }

  static Future<void> saveClientPhoto(Uint8List imageBytes) async {
    await saveImage(_keyClientPhoto, imageBytes);
  }

  static Future<Uint8List?> getDocumentFront() async {
    return await getImage(_keyDocumentFront);
  }

  static Future<Uint8List?> getDocumentBack() async {
    return await getImage(_keyDocumentBack);
  }

  static Future<Uint8List?> getClientPhoto() async {
    return await getImage(_keyClientPhoto);
  }

  static Future<void> setDocumentStatus(String key, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, status);
  }

  static Future<String> getDocumentStatus(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? 'PENDING';
  }

  static Future<void> setDocumentFrontStatus(String status) async {
    await setDocumentStatus(_keyDocumentFrontStatus, status);
  }

  static Future<void> setDocumentBackStatus(String status) async {
    await setDocumentStatus(_keyDocumentBackStatus, status);
  }

  static Future<void> setClientPhotoStatus(String status) async {
    await setDocumentStatus(_keyClientPhotoStatus, status);
  }

  static Future<String> getDocumentFrontStatus() async {
    return await getDocumentStatus(_keyDocumentFrontStatus);
  }

  static Future<String> getDocumentBackStatus() async {
    return await getDocumentStatus(_keyDocumentBackStatus);
  }

  static Future<String> getClientPhotoStatus() async {
    return await getDocumentStatus(_keyClientPhotoStatus);
  }
}