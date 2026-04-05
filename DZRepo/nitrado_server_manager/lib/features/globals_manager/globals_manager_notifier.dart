import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/nitrado_api_client.dart';
import '../../core/xml/xml_parser_service.dart';
import '../../shared/models/global_variable.dart';
import '../config_editor/config_editor_notifier.dart';
import '../server_selection/server_selection_notifier.dart';
import 'globals_helpers.dart';

/// Default path for globals.xml on the server.
const defaultGlobalsXmlPath =
    '/dayzxb/mpmissions/dayzOffline.chernarusplus/db/globals.xml';

/// State for the globals manager screen.
class GlobalsManagerState {
  final List<GlobalVariable> globals;
  final bool isLoading;
  final String? error;
  final int? editingIndex;
  final String? editingValue;
  final String? validationError;
  final bool isSaving;
  final String? saveError;
  final String? successMessage;
  final String globalsXmlPath;

  const GlobalsManagerState({
    this.globals = const [],
    this.isLoading = false,
    this.error,
    this.editingIndex,
    this.editingValue,
    this.validationError,
    this.isSaving = false,
    this.saveError,
    this.successMessage,
    this.globalsXmlPath = defaultGlobalsXmlPath,
  });

  GlobalsManagerState copyWith({
    List<GlobalVariable>? globals,
    bool? isLoading,
    Object? error = _unset,
    Object? editingIndex = _unset,
    Object? editingValue = _unset,
    Object? validationError = _unset,
    bool? isSaving,
    Object? saveError = _unset,
    Object? successMessage = _unset,
    String? globalsXmlPath,
  }) {
    return GlobalsManagerState(
      globals: globals ?? this.globals,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
      editingIndex:
          editingIndex == _unset ? this.editingIndex : editingIndex as int?,
      editingValue: editingValue == _unset
          ? this.editingValue
          : editingValue as String?,
      validationError: validationError == _unset
          ? this.validationError
          : validationError as String?,
      isSaving: isSaving ?? this.isSaving,
      saveError: saveError == _unset ? this.saveError : saveError as String?,
      successMessage: successMessage == _unset
          ? this.successMessage
          : successMessage as String?,
      globalsXmlPath: globalsXmlPath ?? this.globalsXmlPath,
    );
  }

  static const Object _unset = Object();
}

/// Manages loading, editing, and saving globals.xml variables.
///
/// Requirements: 7.1, 7.2, 7.3, 7.4
class GlobalsManagerNotifier extends StateNotifier<GlobalsManagerState> {
  final NitradoApiClient _apiClient;
  final XmlParserService _xmlParser;
  final Ref _ref;

  GlobalsManagerNotifier(this._apiClient, this._xmlParser, this._ref)
      : super(const GlobalsManagerState());

  /// Downloads and parses globals.xml from the server (Req 7.1).
  Future<void> loadGlobals() async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final xml =
          await _apiClient.downloadFile(server.id, state.globalsXmlPath);
      final globals = _xmlParser.parseGlobals(xml);
      if (!mounted) return;
      state = state.copyWith(globals: globals, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar globals.xml: $e',
      );
    }
  }

  /// Starts editing a variable at the given index (Req 7.2).
  void startEditing(int index) {
    final variable = state.globals[index];
    state = state.copyWith(
      editingIndex: index,
      editingValue: variable.value,
      validationError: null,
    );
  }

  /// Updates the editing value and validates it (Req 7.3).
  void updateEditingValue(String value) {
    String? validationError;
    if (!isValidNumericValue(value)) {
      validationError = 'El valor debe ser numérico';
    }
    state = state.copyWith(
      editingValue: value,
      validationError: validationError,
    );
  }

  /// Confirms the edit if the value is valid (Req 7.2, 7.3).
  void confirmEdit() {
    final editingIndex = state.editingIndex;
    final editingValue = state.editingValue;
    if (editingIndex == null || editingValue == null) return;

    if (!isValidNumericValue(editingValue)) {
      state = state.copyWith(
        validationError: 'El valor debe ser numérico',
      );
      return;
    }

    final updatedList = List<GlobalVariable>.from(state.globals);
    final original = updatedList[editingIndex];
    updatedList[editingIndex] = GlobalVariable(
      name: original.name,
      type: original.type,
      value: editingValue,
    );
    state = state.copyWith(
      globals: updatedList,
      editingIndex: null,
      editingValue: null,
      validationError: null,
    );
  }

  /// Cancels the current edit.
  void cancelEdit() {
    state = state.copyWith(
      editingIndex: null,
      editingValue: null,
      validationError: null,
    );
  }

  /// Serializes and uploads globals.xml to the server (Req 7.2, 7.4).
  Future<void> saveToServer() async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state =
        state.copyWith(isSaving: true, saveError: null, successMessage: null);
    try {
      final xml = _xmlParser.serializeGlobals(state.globals);
      await _apiClient.uploadFile(server.id, state.globalsXmlPath, xml);
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        successMessage: 'globals.xml guardado correctamente',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        saveError: 'Error al guardar globals.xml: $e',
      );
    }
  }

  /// Clears displayed messages.
  void clearMessages() {
    state = state.copyWith(successMessage: null, saveError: null);
  }
}

/// Provider for [GlobalsManagerNotifier].
final globalsManagerNotifierProvider =
    StateNotifierProvider<GlobalsManagerNotifier, GlobalsManagerState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider);
  final xmlParser = ref.watch(xmlParserServiceProvider);
  return GlobalsManagerNotifier(apiClient, xmlParser, ref);
});
