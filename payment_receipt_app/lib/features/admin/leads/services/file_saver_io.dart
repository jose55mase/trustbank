import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Implementación mobile/desktop: guarda el archivo en el directorio de documentos.
Future<String> saveFile(List<int> bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  return filePath;
}
