import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nitrado_server_manager/core/api/api_provider.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client.dart';
import 'package:nitrado_server_manager/features/players/players_notifier.dart';
import 'package:nitrado_server_manager/features/server_selection/server_selection_notifier.dart';
import 'package:nitrado_server_manager/shared/models/banned_player.dart';
import 'package:nitrado_server_manager/shared/models/game_server.dart';
import 'package:nitrado_server_manager/shared/models/player.dart';

class MockNitradoApiClient extends Mock implements NitradoApiClient {}

GameServer _server() => const GameServer(
      id: 1,
      name: 'Test Server',
      ip: '1.2.3.4',
      port: 2302,
      status: 'started',
      currentPlayers: 5,
      maxPlayers: 60,
      map: 'chernarusplus',
      gameVersion: '1.24',
    );

void main() {
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

  // ── PlayersNotifier ──────────────────────────────────────────

  group('PlayersNotifier', () {
    test('initial state is empty with no loading', () {
      final state = container.read(playersNotifierProvider);
      expect(state.players, isEmpty);
      expect(state.bannedPlayers, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isBanListLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
    });

    test('fetchPlayers populates player list on success', () async {
      final players = [
        const Player(id: 'p1', name: 'Alice', online: true),
        const Player(id: 'p2', name: 'Bob', online: true),
      ];
      when(() => mockApi.getPlayers(1)).thenAnswer((_) async => players);

      await container
          .read(playersNotifierProvider.notifier)
          .fetchPlayers();

      final state = container.read(playersNotifierProvider);
      expect(state.players, equals(players));
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('fetchPlayers sets error when API fails (Req 4.5)', () async {
      when(() => mockApi.getPlayers(1))
          .thenThrow(Exception('Server offline'));

      await container
          .read(playersNotifierProvider.notifier)
          .fetchPlayers();

      final state = container.read(playersNotifierProvider);
      expect(state.players, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('offline'));
    });

    test('fetchBanList populates banned players on success', () async {
      final banned = [
        BannedPlayer(
          id: 'b1',
          name: 'Cheater',
          reason: 'Hacking',
          bannedAt: DateTime(2024, 1, 15),
        ),
      ];
      when(() => mockApi.getBanList(1)).thenAnswer((_) async => banned);

      await container
          .read(playersNotifierProvider.notifier)
          .fetchBanList();

      final state = container.read(playersNotifierProvider);
      expect(state.bannedPlayers, equals(banned));
      expect(state.isBanListLoading, isFalse);
      expect(state.banListError, isNull);
    });

    test('fetchBanList sets error when API fails', () async {
      when(() => mockApi.getBanList(1))
          .thenThrow(Exception('Connection error'));

      await container
          .read(playersNotifierProvider.notifier)
          .fetchBanList();

      final state = container.read(playersNotifierProvider);
      expect(state.bannedPlayers, isEmpty);
      expect(state.isBanListLoading, isFalse);
      expect(state.banListError, isNotNull);
    });

    test('kickPlayer sets success message and refreshes list', () async {
      when(() => mockApi.kickPlayer(1, 'p1')).thenAnswer((_) async {});
      when(() => mockApi.getPlayers(1)).thenAnswer((_) async => []);

      await container
          .read(playersNotifierProvider.notifier)
          .kickPlayer('p1');

      final state = container.read(playersNotifierProvider);
      expect(state.successMessage, 'Jugador expulsado correctamente');
    });

    test('kickPlayer sets error on failure', () async {
      when(() => mockApi.kickPlayer(1, 'p1'))
          .thenThrow(Exception('Kick failed'));

      await container
          .read(playersNotifierProvider.notifier)
          .kickPlayer('p1');

      final state = container.read(playersNotifierProvider);
      expect(state.errorMessage, contains('expulsar'));
    });

    test('banPlayer sets success message and refreshes list', () async {
      when(() => mockApi.banPlayer(1, 'p1', reason: 'Cheating'))
          .thenAnswer((_) async {});
      when(() => mockApi.getPlayers(1)).thenAnswer((_) async => []);

      await container
          .read(playersNotifierProvider.notifier)
          .banPlayer('p1', reason: 'Cheating');

      final state = container.read(playersNotifierProvider);
      expect(state.successMessage, 'Jugador baneado correctamente');
    });

    test('banPlayer without reason works', () async {
      when(() => mockApi.banPlayer(1, 'p1')).thenAnswer((_) async {});
      when(() => mockApi.getPlayers(1)).thenAnswer((_) async => []);

      await container
          .read(playersNotifierProvider.notifier)
          .banPlayer('p1');

      final state = container.read(playersNotifierProvider);
      expect(state.successMessage, 'Jugador baneado correctamente');
    });

    test('banPlayer sets error on failure', () async {
      when(() => mockApi.banPlayer(1, 'p1'))
          .thenThrow(Exception('Ban failed'));

      await container
          .read(playersNotifierProvider.notifier)
          .banPlayer('p1');

      final state = container.read(playersNotifierProvider);
      expect(state.errorMessage, contains('banear'));
    });

    test('unbanPlayer sets success message and refreshes ban list', () async {
      when(() => mockApi.unbanPlayer(1, 'b1')).thenAnswer((_) async {});
      when(() => mockApi.getBanList(1)).thenAnswer((_) async => []);

      await container
          .read(playersNotifierProvider.notifier)
          .unbanPlayer('b1');

      final state = container.read(playersNotifierProvider);
      expect(state.successMessage, 'Jugador desbaneado correctamente');
    });

    test('unbanPlayer sets error on failure', () async {
      when(() => mockApi.unbanPlayer(1, 'b1'))
          .thenThrow(Exception('Unban failed'));

      await container
          .read(playersNotifierProvider.notifier)
          .unbanPlayer('b1');

      final state = container.read(playersNotifierProvider);
      expect(state.banListError, contains('desbanear'));
    });

    test('does nothing when no server is selected', () async {
      final emptyContainer = ProviderContainer(
        overrides: [
          nitradoApiClientProvider.overrideWithValue(mockApi),
        ],
      );

      final notifier =
          emptyContainer.read(playersNotifierProvider.notifier);
      await notifier.fetchPlayers();
      await notifier.fetchBanList();
      await notifier.kickPlayer('p1');
      await notifier.banPlayer('p1');
      await notifier.unbanPlayer('b1');

      final state = emptyContainer.read(playersNotifierProvider);
      expect(state.players, isEmpty);
      expect(state.bannedPlayers, isEmpty);
      expect(state.isLoading, isFalse);

      emptyContainer.dispose();
    });

    test('clearMessages resets success and error messages', () async {
      when(() => mockApi.kickPlayer(1, 'p1')).thenAnswer((_) async {});
      when(() => mockApi.getPlayers(1)).thenAnswer((_) async => []);

      final notifier =
          container.read(playersNotifierProvider.notifier);
      await notifier.kickPlayer('p1');
      expect(
        container.read(playersNotifierProvider).successMessage,
        isNotNull,
      );

      notifier.clearMessages();
      final state = container.read(playersNotifierProvider);
      expect(state.successMessage, isNull);
      expect(state.errorMessage, isNull);
    });
  });
}
