import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/nitrado_api_client.dart';
import '../../shared/models/banned_player.dart';
import '../../shared/models/player.dart';
import '../server_selection/server_selection_notifier.dart';

/// State for the players management screen.
class PlayersState {
  final List<Player> players;
  final List<BannedPlayer> bannedPlayers;
  final bool isLoading;
  final bool isBanListLoading;
  final String? errorMessage;
  final String? banListError;
  final String? successMessage;

  const PlayersState({
    this.players = const [],
    this.bannedPlayers = const [],
    this.isLoading = false,
    this.isBanListLoading = false,
    this.errorMessage,
    this.banListError,
    this.successMessage,
  });

  /// Creates a copy of this state with the given fields replaced.
  ///
  /// Nullable fields use a sentinel [_unset] so callers can explicitly
  /// pass `null` to clear them, while omitting the parameter preserves
  /// the current value.
  PlayersState copyWith({
    List<Player>? players,
    List<BannedPlayer>? bannedPlayers,
    bool? isLoading,
    bool? isBanListLoading,
    Object? errorMessage = _unset,
    Object? banListError = _unset,
    Object? successMessage = _unset,
  }) {
    return PlayersState(
      players: players ?? this.players,
      bannedPlayers: bannedPlayers ?? this.bannedPlayers,
      isLoading: isLoading ?? this.isLoading,
      isBanListLoading: isBanListLoading ?? this.isBanListLoading,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      banListError: banListError == _unset
          ? this.banListError
          : banListError as String?,
      successMessage: successMessage == _unset
          ? this.successMessage
          : successMessage as String?,
    );
  }

  static const Object _unset = Object();
}

/// Manages player list fetching, ban list, kick/ban/unban operations.
///
/// Requirements: 4.1, 4.2, 4.3, 4.4, 4.5
class PlayersNotifier extends StateNotifier<PlayersState> {
  final NitradoApiClient _apiClient;
  final Ref _ref;

  PlayersNotifier(this._apiClient, this._ref) : super(const PlayersState());

  /// Fetches the list of connected players (Req 4.1).
  Future<void> fetchPlayers() async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final players = await _apiClient.getPlayers(server.id);
      if (!mounted) return;
      state = state.copyWith(players: players, isLoading: false, errorMessage: null);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'No se pudo obtener la lista de jugadores. '
            'El servidor puede estar offline o la consulta falló.',
      );
    }
  }

  /// Fetches the ban list (Req 4.4).
  Future<void> fetchBanList() async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isBanListLoading: true, banListError: null);
    try {
      final banned = await _apiClient.getBanList(server.id);
      if (!mounted) return;
      state = state.copyWith(bannedPlayers: banned, isBanListLoading: false, banListError: null);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isBanListLoading: false,
        banListError:
            'No se pudo obtener la lista de baneados. '
            'El servidor puede estar offline o la consulta falló.',
      );
    }
  }

  /// Kicks a player from the server (Req 4.2).
  Future<void> kickPlayer(String playerId) async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiClient.kickPlayer(server.id, playerId);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Jugador expulsado correctamente',
      );
      await fetchPlayers();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al expulsar jugador: $e',
      );
    }
  }

  /// Bans a player with an optional reason (Req 4.3).
  Future<void> banPlayer(String playerId, {String? reason}) async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiClient.banPlayer(server.id, playerId, reason: reason);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Jugador baneado correctamente',
      );
      await fetchPlayers();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al banear jugador: $e',
      );
    }
  }

  /// Unbans a player (Req 4.4).
  Future<void> unbanPlayer(String playerId) async {
    final server = _ref.read(selectedServerProvider);
    if (server == null) return;

    state = state.copyWith(isBanListLoading: true, banListError: null);
    try {
      await _apiClient.unbanPlayer(server.id, playerId);
      if (!mounted) return;
      state = state.copyWith(
        isBanListLoading: false,
        successMessage: 'Jugador desbaneado correctamente',
      );
      await fetchBanList();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isBanListLoading: false,
        banListError: 'Error al desbanear jugador: $e',
      );
    }
  }

  /// Clears any displayed success or error messages.
  void clearMessages() {
    state = state.copyWith(
      successMessage: null,
      errorMessage: null,
      banListError: null,
    );
  }
}

/// Provider for [PlayersNotifier].
final playersNotifierProvider =
    StateNotifierProvider<PlayersNotifier, PlayersState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider);
  return PlayersNotifier(apiClient, ref);
});
