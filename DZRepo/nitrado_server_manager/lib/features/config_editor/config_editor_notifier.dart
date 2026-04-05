import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/nitrado_api_client.dart';
import '../../core/xml/xml_parser_service.dart';
import '../../core/xml/xml_parser_service_impl.dart';
import '../../shared/models/file_entry.dart';
import '../server_selection/server_selection_notifier.dart';

/// State for the config editor screen.
class ConfigEditorState {
  final List<FileEntry> files;
  final bool isLoadingFiles;
  final String? filesError;

  final String? selectedFilePath;
  final String? fileContent;
  final bool isLoadingContent;
  final String? contentError;

  final bool isUploading;
  final String? uploadError;
  final String? validationError;
  final String? successMessage;

  const ConfigEditorState({
    this.files = const [],
    this.isLoadingFiles = false,
    this.filesError,
    this.selectedFilePath,
    this.fileContent,
    this.isLoadingContent = false,
    this.contentError,
    this.isUploading = false,
    this.uploadError,
    this.validationError,
    this.successMessage,
  });

  ConfigEditorState copyWith({
    List<FileEntry>? files,
    bool? isLoadingFiles,
    Object? filesError = _unset,
    Object? selectedFilePath = _unset,
    Object? fileContent = _unset,
    bool? isLoadingContent,
    Object? contentError = _unset,
    bool? isUploading,
    Object? uploadError = _unset,
    Object? validationError = _unset,
    Object? successMessage = _unset,
  }) {
    return ConfigEditorState(
      files: files ?? this.files,
      isLoadingFiles: isLoadingFiles ?? this.isLoadingFiles,
      filesError:
          filesError == _unset ? this.filesError : filesError as String?,
      selectedFilePath: selectedFilePath == _unset
          ? this.selectedFilePath
          : selectedFilePath as String?,
      fileContent:
          fileContent == _unset ? this.fileContent : fileContent as String?,
      isLoadingContent: isLoadingContent ?? this.isLoadingContent,
      contentError:
          contentError == _unset ? this.contentError : contentError as String?,
      isUploading: isUploading ?? this.isUploading,
      uploadError:
          uploadError == _unset ? this.uploadError : uploadError as String?,
      validationError: validationError == _unset
          ? this.validationError
          : validationError as String?,
      successMessage: successMessage == _unset
          ? this.successMessage
          : successMessage as String?,
    );
  }

  static const Object _unset = Object();
}

/// Determines the file type from its extension.
enum ConfigFileType { xml, json, unknown }

/// Returns the [ConfigFileType] based on the file path extension.
ConfigFileType fileTypeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.xml')) return ConfigFileType.xml;
  if (lower.endsWith('.json')) return ConfigFileType.json;
  return ConfigFileType.unknown;
}

/// Manages config file listing, download, validation, and upload.
///
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6
class ConfigEditorNotifier extends StateNotifier<ConfigEditorState> {
  final NitradoApiClient _apiClient;
  final XmlParserService _xmlParser;
  final Ref _ref;

  ConfigEditorNotifier(this._apiClient, this._xmlParser, this._ref)
      : super(const ConfigEditorState());

  /// Lists config files from the server (Req 5.1).
  Future<void> fetchFiles([String path = '/']) async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isLoadingFiles: true, filesError: null);
    try {
      final files = await _apiClient.listFiles(server.id, path);
      if (!mounted) return;
      state = state.copyWith(files: files, isLoadingFiles: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingFiles: false,
        filesError: 'Error al listar archivos: $e',
      );
    }
  }

  /// Downloads a file's content for editing (Req 5.2).
  Future<void> selectFile(String filePath) async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(
      selectedFilePath: filePath,
      isLoadingContent: true,
      contentError: null,
      validationError: null,
      uploadError: null,
      successMessage: null,
    );
    try {
      final content = await _apiClient.downloadFile(server.id, filePath);
      if (!mounted) return;
      state = state.copyWith(fileContent: content, isLoadingContent: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingContent: false,
        contentError: 'Error al descargar archivo: $e',
      );
    }
  }

  /// Validates syntax and uploads the modified file (Req 5.3, 5.4, 5.5, 5.6).
  Future<void> saveFile(String content) async {
    final server = _ref.read(selectedServerProvider);
    final filePath = state.selectedFilePath;
    if (server == null || filePath == null) return;

    // Validate syntax based on file type.
    final type = fileTypeFromPath(filePath);
    if (type == ConfigFileType.xml && !_xmlParser.isValidXml(content)) {
      state = state.copyWith(
        validationError: 'Error de sintaxis XML: el archivo no es XML válido',
      );
      return;
    }
    if (type == ConfigFileType.json && !_xmlParser.isValidJson(content)) {
      state = state.copyWith(
        validationError: 'Error de sintaxis JSON: el archivo no es JSON válido',
      );
      return;
    }

    state = state.copyWith(
      isUploading: true,
      uploadError: null,
      validationError: null,
      successMessage: null,
    );
    try {
      await _apiClient.uploadFile(server.id, filePath, content);
      if (!mounted) return;
      state = state.copyWith(
        isUploading: false,
        fileContent: content,
        successMessage: 'Archivo guardado correctamente',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isUploading: false,
        uploadError: 'Error al subir archivo: $e',
      );
    }
  }

  /// Clears the selected file and returns to the file list.
  void clearSelection() {
    state = state.copyWith(
      selectedFilePath: null,
      fileContent: null,
      contentError: null,
      validationError: null,
      uploadError: null,
      successMessage: null,
    );
  }

  /// Clears displayed messages.
  void clearMessages() {
    state = state.copyWith(
      successMessage: null,
      uploadError: null,
      validationError: null,
    );
  }
}

/// Provider for [XmlParserService].
final xmlParserServiceProvider = Provider<XmlParserService>((ref) {
  return XmlParserServiceImpl();
});

/// Provider for [ConfigEditorNotifier].
final configEditorNotifierProvider =
    StateNotifierProvider<ConfigEditorNotifier, ConfigEditorState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider);
  final xmlParser = ref.watch(xmlParserServiceProvider);
  return ConfigEditorNotifier(apiClient, xmlParser, ref);
});
