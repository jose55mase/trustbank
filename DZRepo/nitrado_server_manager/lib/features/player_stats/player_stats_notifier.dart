import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/backend_api_client.dart';
import 'models/player_stats_model.dart';

/// State for the player statistics screen.
class PlayerStatsState {
  final List<PlayerStatsModel> players;
  final bool isLoading;
  final String? errorMessage;

  const PlayerStatsState({
    this.players = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PlayerStatsState copyWith({
    List<PlayerStatsModel>? players,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PlayerStatsState(
      players: players ?? this.players,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Manages player statistics state: fetches all players and individual stats.
///
/// Requirements: 12.1, 12.2, 12.4
class PlayerStatsNotifier extends StateNotifier<PlayerStatsState> {
  final BackendApiClient _apiClient;

  PlayerStatsNotifier(this._apiClient)
      : super(const PlayerStatsState());

  /// Fetches the list of all linked players with their statistics.
  Future<void> fetchAllPlayers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final players = await _apiClient.getPlayerStats();
      if (!mounted) return;
      state = PlayerStatsState(players: players, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al obtener estadísticas de jugadores: $e',
      );
    }
  }

  /// Fetches statistics for a specific player by Discord ID.
  Future<void> fetchPlayerById(String discordId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final player = await _apiClient.getPlayerStatsById(discordId);
      if (!mounted) return;
      state = PlayerStatsState(players: [player], isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al obtener estadísticas del jugador: $e',
      );
    }
  }
}

/// Provider for [PlayerStatsNotifier].
final playerStatsNotifierProvider =
    StateNotifierProvider<PlayerStatsNotifier, PlayerStatsState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider) as BackendApiClient;
  return PlayerStatsNotifier(apiClient);
});
