import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/nitrado_api_client.dart';
import '../../core/xml/xml_parser_service.dart';
import '../../shared/models/spawn_event.dart';
import '../config_editor/config_editor_notifier.dart';
import '../server_selection/server_selection_notifier.dart';

/// Default path for events.xml on the server.
const defaultEventsXmlPath =
    '/dayzxb/mpmissions/dayzOffline.chernarusplus/db/events.xml';

/// State for the events manager screen.
class EventsManagerState {
  final List<SpawnEvent> events;
  final bool isLoading;
  final String? error;
  final SpawnEvent? editingEvent;
  final int? editingIndex;
  final bool isSaving;
  final String? saveError;
  final String? successMessage;
  final String eventsXmlPath;

  const EventsManagerState({
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.editingEvent,
    this.editingIndex,
    this.isSaving = false,
    this.saveError,
    this.successMessage,
    this.eventsXmlPath = defaultEventsXmlPath,
  });

  EventsManagerState copyWith({
    List<SpawnEvent>? events,
    bool? isLoading,
    Object? error = _unset,
    Object? editingEvent = _unset,
    Object? editingIndex = _unset,
    bool? isSaving,
    Object? saveError = _unset,
    Object? successMessage = _unset,
    String? eventsXmlPath,
  }) {
    return EventsManagerState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
      editingEvent: editingEvent == _unset
          ? this.editingEvent
          : editingEvent as SpawnEvent?,
      editingIndex:
          editingIndex == _unset ? this.editingIndex : editingIndex as int?,
      isSaving: isSaving ?? this.isSaving,
      saveError: saveError == _unset ? this.saveError : saveError as String?,
      successMessage: successMessage == _unset
          ? this.successMessage
          : successMessage as String?,
      eventsXmlPath: eventsXmlPath ?? this.eventsXmlPath,
    );
  }

  static const Object _unset = Object();
}

/// Manages loading, editing, and saving events.xml spawn events.
///
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5
class EventsManagerNotifier extends StateNotifier<EventsManagerState> {
  final NitradoApiClient _apiClient;
  final XmlParserService _xmlParser;
  final Ref _ref;

  EventsManagerNotifier(this._apiClient, this._xmlParser, this._ref)
      : super(const EventsManagerState());

  /// Downloads and parses events.xml from the server (Req 8.1).
  Future<void> loadEvents() async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final xml =
          await _apiClient.downloadFile(server.id, state.eventsXmlPath);
      final events = _xmlParser.parseEvents(xml);
      if (!mounted) return;
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar events.xml: $e',
      );
    }
  }

  /// Starts editing an event at the given index (Req 8.2).
  void startEditing(int index) {
    final event = state.events[index];
    state = state.copyWith(editingEvent: event, editingIndex: index);
  }

  /// Updates the currently editing event (Req 8.2).
  void updateEditingEvent(SpawnEvent updated) {
    state = state.copyWith(editingEvent: updated);
  }

  /// Confirms the edit and updates the event in the list (Req 8.3).
  void confirmEdit() {
    final editingEvent = state.editingEvent;
    final editingIndex = state.editingIndex;
    if (editingEvent == null || editingIndex == null) return;

    final updatedList = List<SpawnEvent>.from(state.events);
    updatedList[editingIndex] = editingEvent;
    state = state.copyWith(
      events: updatedList,
      editingEvent: null,
      editingIndex: null,
    );
  }

  /// Cancels the current edit.
  void cancelEdit() {
    state = state.copyWith(editingEvent: null, editingIndex: null);
  }

  /// Serializes and uploads events.xml to the server (Req 8.3, 8.5).
  Future<void> saveToServer() async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state =
        state.copyWith(isSaving: true, saveError: null, successMessage: null);
    try {
      final xml = _xmlParser.serializeEvents(state.events);
      await _apiClient.uploadFile(server.id, state.eventsXmlPath, xml);
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        successMessage: 'events.xml guardado correctamente',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        saveError: 'Error al guardar events.xml: $e',
      );
    }
  }

  /// Clears displayed messages.
  void clearMessages() {
    state = state.copyWith(successMessage: null, saveError: null);
  }
}

/// Provider for [EventsManagerNotifier].
final eventsManagerNotifierProvider =
    StateNotifierProvider<EventsManagerNotifier, EventsManagerState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider);
  final xmlParser = ref.watch(xmlParserServiceProvider);
  return EventsManagerNotifier(apiClient, xmlParser, ref);
});
