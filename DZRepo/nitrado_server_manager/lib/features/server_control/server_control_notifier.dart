import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/nitrado_api_client.dart';
import '../../shared/models/server_action.dart';
import '../server_selection/server_selection_notifier.dart';

/// State for the server control screen.
class ServerControlState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ServerControlState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ServerControlState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return ServerControlState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Manages server control actions (start, stop, restart).
///
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5
class ServerControlNotifier extends StateNotifier<ServerControlState> {
  final NitradoApiClient _apiClient;
  final Ref _ref;

  ServerControlNotifier(this._apiClient, this._ref)
      : super(const ServerControlState());

  /// Executes a server control [action] on the currently selected server.
  ///
  /// Sets loading state, calls the API, and updates success/error messages.
  Future<void> executeAction(ServerAction action) async {
    final selected = _ref.read(selectedServerProvider);
    if (selected == null) return;

    state = const ServerControlState(isLoading: true);
    try {
      await _apiClient.serverAction(selected.id, action);
      if (!mounted) return;
      state = ServerControlState(
        successMessage: _successLabel(action),
      );
    } catch (e) {
      if (!mounted) return;
      state = ServerControlState(
        errorMessage: '$e',
      );
    }
  }

  /// Clears any displayed error or success message.
  void clearMessages() {
    state = const ServerControlState();
  }

  String _successLabel(ServerAction action) {
    switch (action) {
      case ServerAction.start:
        return 'Servidor iniciado correctamente';
      case ServerAction.stop:
        return 'Servidor detenido correctamente';
      case ServerAction.restart:
        return 'Servidor reiniciado correctamente';
    }
  }
}

/// Provider for [ServerControlNotifier].
final serverControlNotifierProvider =
    StateNotifierProvider<ServerControlNotifier, ServerControlState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider);
  return ServerControlNotifier(apiClient, ref);
});
