import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/backend_api_client.dart';
import '../server_selection/server_selection_notifier.dart';
import 'models/game_log_category.dart';
import 'models/game_log_event.dart';

/// State for the game logs screen.
///
/// Requirements: 4.1, 4.3, 4.4, 4.5, 5.3, 5.5
class GameLogsState {
  final List<GameLogEvent> events;
  final GameLogCategory? selectedCategory;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const GameLogsState({
    this.events = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  GameLogsState copyWith({
    List<GameLogEvent>? events,
    Object? selectedCategory = _unset,
    String? searchQuery,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return GameLogsState(
      events: events ?? this.events,
      selectedCategory: selectedCategory == _unset
          ? this.selectedCategory
          : selectedCategory as GameLogCategory?,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
    );
  }

  static const Object _unset = Object();
}

/// Manages fetching, filtering, and refreshing game log events.
///
/// Requirements: 4.1, 4.3, 4.4, 4.5, 5.3, 5.5
class GameLogsNotifier extends StateNotifier<GameLogsState> {
  final BackendApiClient _apiClient;
  final Ref _ref;

  GameLogsNotifier(this._apiClient, this._ref) : super(const GameLogsState());

  /// Fetches game events from the backend API.
  Future<void> loadEvents() async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final events = await _apiClient.getGameEvents(server.id);
      if (!mounted) return;
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar eventos: $e',
      );
    }
  }

  /// Sets the selected category filter.
  ///
  /// Pass `null` to show all categories.
  void selectCategory(GameLogCategory? category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Updates the search query for local filtering.
  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Refreshes events from the backend.
  Future<void> refresh() async {
    await loadEvents();
  }

  /// Returns events filtered by the current category and search query.
  ///
  /// Filtering is applied locally on the already-fetched events list.
  /// Category filter: if selectedCategory is non-null, only events matching
  /// that category are included.
  /// Search filter: case-insensitive match on playerName or message.
  List<GameLogEvent> get filteredEvents {
    var result = state.events;

    final category = state.selectedCategory;
    if (category != null) {
      result = result.where((e) => e.category == category).toList();
    }

    final query = state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((e) {
        return e.playerName.toLowerCase().contains(query) ||
            e.message.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }
}

/// Provider for [GameLogsNotifier].
final gameLogsNotifierProvider =
    StateNotifierProvider<GameLogsNotifier, GameLogsState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider) as BackendApiClient;
  return GameLogsNotifier(apiClient, ref);
});
