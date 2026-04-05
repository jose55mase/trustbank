import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/nitrado_api_client.dart';
import '../../core/xml/xml_parser_service.dart';
import '../../shared/models/dayz_type.dart';
import '../config_editor/config_editor_notifier.dart';
import '../server_selection/server_selection_notifier.dart';
import 'types_helpers.dart';

/// Default path for types.xml on the server.
const defaultTypesXmlPath =
    '/dayzxb/mpmissions/dayzOffline.chernarusplus/db/types.xml';

/// State for the types manager screen.
class TypesManagerState {
  final List<DayzType> allTypes;
  final List<DayzType> filteredTypes;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? categoryFilter;
  final String? usageFilter;
  final DayzType? editingType;
  final int? editingIndex;
  final bool isSaving;
  final String? saveError;
  final String? successMessage;
  final String typesXmlPath;

  const TypesManagerState({
    this.allTypes = const [],
    this.filteredTypes = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.categoryFilter,
    this.usageFilter,
    this.editingType,
    this.editingIndex,
    this.isSaving = false,
    this.saveError,
    this.successMessage,
    this.typesXmlPath = defaultTypesXmlPath,
  });

  TypesManagerState copyWith({
    List<DayzType>? allTypes,
    List<DayzType>? filteredTypes,
    bool? isLoading,
    Object? error = _unset,
    String? searchQuery,
    Object? categoryFilter = _unset,
    Object? usageFilter = _unset,
    Object? editingType = _unset,
    Object? editingIndex = _unset,
    bool? isSaving,
    Object? saveError = _unset,
    Object? successMessage = _unset,
    String? typesXmlPath,
  }) {
    return TypesManagerState(
      allTypes: allTypes ?? this.allTypes,
      filteredTypes: filteredTypes ?? this.filteredTypes,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter == _unset
          ? this.categoryFilter
          : categoryFilter as String?,
      usageFilter:
          usageFilter == _unset ? this.usageFilter : usageFilter as String?,
      editingType:
          editingType == _unset ? this.editingType : editingType as DayzType?,
      editingIndex:
          editingIndex == _unset ? this.editingIndex : editingIndex as int?,
      isSaving: isSaving ?? this.isSaving,
      saveError: saveError == _unset ? this.saveError : saveError as String?,
      successMessage: successMessage == _unset
          ? this.successMessage
          : successMessage as String?,
      typesXmlPath: typesXmlPath ?? this.typesXmlPath,
    );
  }

  static const Object _unset = Object();
}

/// Manages loading, filtering, editing, and saving types.xml items.
///
/// Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6
class TypesManagerNotifier extends StateNotifier<TypesManagerState> {
  final NitradoApiClient _apiClient;
  final XmlParserService _xmlParser;
  final Ref _ref;

  TypesManagerNotifier(this._apiClient, this._xmlParser, this._ref)
      : super(const TypesManagerState());

  /// Downloads and parses types.xml from the server (Req 6.1).
  Future<void> loadTypes() async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final xml =
          await _apiClient.downloadFile(server.id, state.typesXmlPath);
      final types = _xmlParser.parseTypes(xml);
      if (!mounted) return;
      state = state.copyWith(
        allTypes: types,
        isLoading: false,
      );
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar types.xml: $e',
      );
    }
  }

  /// Updates the search query and re-filters (Req 6.1).
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  /// Sets the category filter and re-filters (Req 6.6).
  void setCategoryFilter(String? category) {
    state = state.copyWith(categoryFilter: category);
    _applyFilters();
  }

  /// Sets the usage zone filter and re-filters (Req 6.1).
  void setUsageFilter(String? usage) {
    state = state.copyWith(usageFilter: usage);
    _applyFilters();
  }

  /// Applies search, category, and usage filters to the full list.
  void _applyFilters() {
    var result = state.allTypes;

    // Filter by category using the pure helper.
    if (state.categoryFilter != null) {
      result = filterByCategory(result, state.categoryFilter!);
    }

    // Filter by usage zone.
    if (state.usageFilter != null) {
      final lowerUsage = state.usageFilter!.toLowerCase();
      result = result
          .where((t) =>
              t.usages.any((u) => u.toLowerCase() == lowerUsage))
          .toList();
    }

    // Filter by search query (name).
    if (state.searchQuery.isNotEmpty) {
      final lowerQuery = state.searchQuery.toLowerCase();
      result = result
          .where((t) => t.name.toLowerCase().contains(lowerQuery))
          .toList();
    }

    state = state.copyWith(filteredTypes: result);
  }

  /// Starts editing an item at the given index (Req 6.2).
  void startEditing(int index) {
    final type = state.filteredTypes[index];
    // Find the actual index in allTypes.
    final allIndex = state.allTypes.indexOf(type);
    state = state.copyWith(editingType: type, editingIndex: allIndex);
  }

  /// Updates the currently editing item (Req 6.2).
  void updateEditingType(DayzType updated) {
    state = state.copyWith(editingType: updated);
  }

  /// Confirms the edit and updates the item in the list (Req 6.3).
  void confirmEdit() {
    final editingType = state.editingType;
    final editingIndex = state.editingIndex;
    if (editingType == null || editingIndex == null) return;

    final updatedList = List<DayzType>.from(state.allTypes);
    updatedList[editingIndex] = editingType;
    state = state.copyWith(
      allTypes: updatedList,
      editingType: null,
      editingIndex: null,
    );
    _applyFilters();
  }

  /// Cancels the current edit.
  void cancelEdit() {
    state = state.copyWith(editingType: null, editingIndex: null);
  }

  /// Serializes and uploads types.xml to the server (Req 6.3, 6.4).
  Future<void> saveToServer() async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isSaving: true, saveError: null, successMessage: null);
    try {
      final xml = _xmlParser.serializeTypes(state.allTypes);
      await _apiClient.uploadFile(server.id, state.typesXmlPath, xml);
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        successMessage: 'types.xml guardado correctamente',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        saveError: 'Error al guardar types.xml: $e',
      );
    }
  }

  /// Clears displayed messages.
  void clearMessages() {
    state = state.copyWith(successMessage: null, saveError: null);
  }

  /// Updates the types.xml file path.
  void setTypesXmlPath(String path) {
    state = state.copyWith(typesXmlPath: path);
  }

  /// Collects all unique usage zones from the loaded types.
  List<String> get allUsageZones {
    final zones = <String>{};
    for (final t in state.allTypes) {
      zones.addAll(t.usages);
    }
    final sorted = zones.toList()..sort();
    return sorted;
  }
}

/// Provider for [TypesManagerNotifier].
final typesManagerNotifierProvider =
    StateNotifierProvider<TypesManagerNotifier, TypesManagerState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider);
  final xmlParser = ref.watch(xmlParserServiceProvider);
  return TypesManagerNotifier(apiClient, xmlParser, ref);
});
