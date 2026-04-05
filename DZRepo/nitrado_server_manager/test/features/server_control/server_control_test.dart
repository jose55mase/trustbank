import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nitrado_server_manager/core/api/api_provider.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client.dart';
import 'package:nitrado_server_manager/features/server_control/is_control_enabled.dart';
import 'package:nitrado_server_manager/features/server_control/server_control_notifier.dart';
import 'package:nitrado_server_manager/features/server_selection/server_selection_notifier.dart';
import 'package:nitrado_server_manager/shared/models/game_server.dart';
import 'package:nitrado_server_manager/shared/models/server_action.dart';

class MockNitradoApiClient extends Mock implements NitradoApiClient {}

GameServer _server({String status = 'started'}) => GameServer(
      id: 1,
      name: 'Test',
      ip: '1.2.3.4',
      port: 2302,
      status: status,
      currentPlayers: 5,
      maxPlayers: 60,
      map: 'chernarusplus',
      gameVersion: '1.24',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(ServerAction.restart);
  });

  // ── isControlEnabled ─────────────────────────────────────────

  group('isControlEnabled', () {
    test('returns true for "started"', () {
      expect(isControlEnabled('started'), isTrue);
    });

    test('returns true for "stopped"', () {
      expect(isControlEnabled('stopped'), isTrue);
    });

    test('returns false for "restarting"', () {
      expect(isControlEnabled('restarting'), isFalse);
    });

    test('returns false for "installing"', () {
      expect(isControlEnabled('installing'), isFalse);
    });

    test('returns false for unknown status', () {
      expect(isControlEnabled('unknown'), isFalse);
    });
  });

  // ── ServerControlNotifier ────────────────────────────────────

  group('ServerControlNotifier', () {
    late MockNitradoApiClient mockApi;
    late ProviderContainer container;

    setUp(() {
      mockApi = MockNitradoApiClient();
      container = ProviderContainer(
        overrides: [
          nitradoApiClientProvider.overrideWithValue(mockApi),
          selectedServerProvider.overrideWith((ref) => _server()),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('initial state has no loading, no messages', () {
      final state = container.read(serverControlNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
    });

    test('executeAction sets success message on success', () async {
      when(() => mockApi.serverAction(1, ServerAction.restart))
          .thenAnswer((_) async {});

      final notifier =
          container.read(serverControlNotifierProvider.notifier);
      await notifier.executeAction(ServerAction.restart);

      final state = container.read(serverControlNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.successMessage, 'Servidor reiniciado correctamente');
      expect(state.errorMessage, isNull);
    });

    test('executeAction sets error message on failure', () async {
      when(() => mockApi.serverAction(1, ServerAction.stop))
          .thenThrow(Exception('API error'));

      final notifier =
          container.read(serverControlNotifierProvider.notifier);
      await notifier.executeAction(ServerAction.stop);

      final state = container.read(serverControlNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('API error'));
      expect(state.successMessage, isNull);
    });

    test('clearMessages resets state', () async {
      when(() => mockApi.serverAction(1, ServerAction.start))
          .thenAnswer((_) async {});

      final notifier =
          container.read(serverControlNotifierProvider.notifier);
      await notifier.executeAction(ServerAction.start);
      notifier.clearMessages();

      final state = container.read(serverControlNotifierProvider);
      expect(state.successMessage, isNull);
      expect(state.errorMessage, isNull);
    });

    test('does nothing when no server is selected', () async {
      final emptyContainer = ProviderContainer(
        overrides: [
          nitradoApiClientProvider.overrideWithValue(mockApi),
          // selectedServerProvider defaults to null
        ],
      );

      final notifier =
          emptyContainer.read(serverControlNotifierProvider.notifier);
      await notifier.executeAction(ServerAction.restart);

      final state = emptyContainer.read(serverControlNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.successMessage, isNull);
      expect(state.errorMessage, isNull);

      emptyContainer.dispose();
    });

    test('success message varies by action type', () async {
      when(() => mockApi.serverAction(1, any()))
          .thenAnswer((_) async {});

      final notifier =
          container.read(serverControlNotifierProvider.notifier);

      await notifier.executeAction(ServerAction.start);
      expect(
        container.read(serverControlNotifierProvider).successMessage,
        'Servidor iniciado correctamente',
      );

      await notifier.executeAction(ServerAction.stop);
      expect(
        container.read(serverControlNotifierProvider).successMessage,
        'Servidor detenido correctamente',
      );

      await notifier.executeAction(ServerAction.restart);
      expect(
        container.read(serverControlNotifierProvider).successMessage,
        'Servidor reiniciado correctamente',
      );
    });
  });
}
