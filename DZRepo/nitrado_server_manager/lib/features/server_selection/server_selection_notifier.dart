import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/nitrado_api_client.dart';
import '../../shared/models/game_server.dart';

/// State for the server selection screen.
class ServerSelectionState {
  final List<GameServer> servers;
  final bool isLoading;
  final String? errorMessage;

  const ServerSelectionState({
    this.servers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ServerSelectionState copyWith({
    List<GameServer>? servers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ServerSelectionState(
      servers: servers ?? this.servers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Manages the list of DayZ servers and the currently selected server.
class ServerSelectionNotifier extends StateNotifier<ServerSelectionState> {
  final NitradoApiClient _apiClient;

  ServerSelectionNotifier(this._apiClient)
      : super(const ServerSelectionState());

  /// Fetches the list of DayZ servers from the Nitrado API.
  Future<void> fetchServers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final servers = await _apiClient.getServers();
      state = state.copyWith(servers: servers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al obtener servidores: $e',
      );
    }
  }
}

/// Provider for [ServerSelectionNotifier].
final serverSelectionNotifierProvider =
    StateNotifierProvider<ServerSelectionNotifier, ServerSelectionState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider);
  return ServerSelectionNotifier(apiClient);
});

/// Holds the currently selected [GameServer].
///
/// Accessible from any screen so the user can navigate back to the server
/// list or see which server is active (Req 11.3).
final selectedServerProvider = StateProvider<GameServer?>((ref) => null);
