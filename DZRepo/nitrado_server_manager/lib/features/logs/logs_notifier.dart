import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/nitrado_api_client.dart';
import '../server_selection/server_selection_notifier.dart';
import 'logs_helpers.dart';

/// State for the logs screen.
class LogsState {
  final List<String> allLogs;
  final List<String> filteredLogs;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const LogsState({
    this.allLogs = const [],
    this.filteredLogs = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  LogsState copyWith({
    List<String>? allLogs,
    List<String>? filteredLogs,
    String? searchQuery,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return LogsState(
      allLogs: allLogs ?? this.allLogs,
      filteredLogs: filteredLogs ?? this.filteredLogs,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
    );
  }

  static const Object _unset = Object();
}

/// Manages fetching, searching, and refreshing server logs.
///
/// Requirements: 9.1, 9.2, 9.3, 9.4
class LogsNotifier extends StateNotifier<LogsState> {
  final NitradoApiClient _apiClient;
  final Ref _ref;

  LogsNotifier(this._apiClient, this._ref) : super(const LogsState());

  /// Fetches logs from the server API (Req 9.1).
  Future<void> loadLogs() async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final rawLogs = await _apiClient.getServerLogs(server.id);
      final lines = rawLogs
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      if (!mounted) return;
      final filtered = filterLogs(lines, state.searchQuery);
      state = state.copyWith(
        allLogs: lines,
        filteredLogs: filtered,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar logs: $e',
      );
    }
  }

  /// Updates the search query and filters logs (Req 9.3).
  void updateSearch(String query) {
    final filtered = filterLogs(state.allLogs, query);
    state = state.copyWith(
      searchQuery: query,
      filteredLogs: filtered,
    );
  }

  /// Refreshes logs from the server (Req 9.4).
  Future<void> refresh() async {
    await loadLogs();
  }
}

/// Provider for [LogsNotifier].
final logsNotifierProvider =
    StateNotifierProvider<LogsNotifier, LogsState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider);
  return LogsNotifier(apiClient, ref);
});
