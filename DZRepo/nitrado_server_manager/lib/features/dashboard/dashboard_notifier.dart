import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/nitrado_api_client.dart';
import '../../shared/models/game_server.dart';
import '../server_selection/server_selection_notifier.dart';

/// State for the dashboard screen.
class DashboardState {
  final GameServer? server;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    this.server,
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    GameServer? server,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      server: server ?? this.server,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Manages dashboard state: fetches server status and auto-refreshes.
///
/// Requirements: 2.1, 2.2, 2.4
class DashboardNotifier extends StateNotifier<DashboardState> {
  final NitradoApiClient _apiClient;
  final Ref _ref;
  Timer? _refreshTimer;

  /// Auto-refresh interval (Req 2.2).
  static const refreshInterval = Duration(seconds: 30);

  DashboardNotifier(this._apiClient, this._ref)
      : super(const DashboardState()) {
    _startAutoRefresh();
  }

  /// Fetches the latest server status from the API.
  Future<void> fetchStatus() async {
    final selected = _ref.read(selectedServerProvider);
    if (selected == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final server = await _apiClient.getServerStatus(selected.id);
      if (!mounted) return;
      // Also update the selected server provider so other screens see fresh data.
      _ref.read(selectedServerProvider.notifier).state = server;
      state = DashboardState(server: server, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al obtener estado del servidor: $e',
      );
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) => fetchStatus());
  }

  /// Restarts the auto-refresh timer and fetches immediately.
  Future<void> retry() => fetchStatus();

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Provider for [DashboardNotifier].
final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider);
  return DashboardNotifier(apiClient, ref);
});
