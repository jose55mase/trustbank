import 'file_saver_web.dart' if (dart.library.io) 'file_saver_io.dart'
    as platform_saver;

/// Servicio multiplataforma para guardar archivos.
/// En web usa descarga del navegador, en mobile/desktop usa el filesystem.
class FileSaverService {
  /// Guarda los bytes como archivo y retorna la ruta o nombre del archivo.
  static Future<String> saveFile(List<int> bytes, String fileName) async {
    return platform_saver.saveFile(bytes, fileName);
  }
}
