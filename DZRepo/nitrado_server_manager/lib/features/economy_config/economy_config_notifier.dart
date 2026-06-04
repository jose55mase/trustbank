import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/backend_api_client.dart';
import 'models/economy_config_model.dart';

/// State for the economy configuration screen.
class EconomyConfigState {
  final EconomyConfigModel? config;
  final bool isLoading;
  final String? errorMessage;
  final bool isSaving;

  const EconomyConfigState({
    this.config,
    this.isLoading = false,
    this.errorMessage,
    this.isSaving = false,
  });

  EconomyConfigState copyWith({
    EconomyConfigModel? config,
    bool? isLoading,
    String? errorMessage,
    bool? isSaving,
  }) {
    return EconomyConfigState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Manages economy configuration state: fetches and updates config.
///
/// Requirements: 11.1, 11.2, 12.4
class EconomyConfigNotifier extends StateNotifier<EconomyConfigState> {
  final BackendApiClient _apiClient;

  EconomyConfigNotifier(this._apiClient)
      : super(const EconomyConfigState());

  /// Fetches the economy configuration for the given guild.
  Future<void> fetchConfig(String guildId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final config = await _apiClient.getEconomyConfig(guildId);
      if (!mounted) return;
      state = EconomyConfigState(config: config, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al obtener configuración de economía: $e',
      );
    }
  }

  /// Updates the economy configuration for the given guild.
  Future<void> updateConfig(String guildId, EconomyConfigModel config) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final updated = await _apiClient.updateEconomyConfig(guildId, config);
      if (!mounted) return;
      state = EconomyConfigState(config: updated, isSaving: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al actualizar configuración de economía: $e',
      );
    }
  }
}

/// Provider for [EconomyConfigNotifier].
final economyConfigNotifierProvider =
    StateNotifierProvider<EconomyConfigNotifier, EconomyConfigState>((ref) {
  final apiClient = ref.watch(nitradoApiClientProvider) as BackendApiClient;
  return EconomyConfigNotifier(apiClient);
});
