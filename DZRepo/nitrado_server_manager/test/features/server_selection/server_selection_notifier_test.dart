import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nitrado_server_manager/core/api/nitrado_api_client.dart';
import 'package:nitrado_server_manager/core/api/api_provider.dart';
import 'package:nitrado_server_manager/features/server_selection/server_selection_notifier.dart';
import 'package:nitrado_server_manager/shared/models/game_server.dart';

class MockNitradoApiClient extends Mock implements NitradoApiClient {}

void main() {
  late MockNitradoApiClient mockApiClient;

  final sampleServers = [
    const GameServer(
      id: 1,
      name: 'DayZ Server #1',
      ip: '192.168.1.1',
      port: 2302,
      status: 'started',
      currentPlayers: 10,
      maxPlayers: 60,
      map: 'chernarusplus',
      gameVersion: '1.24',
    ),
    const GameServer(
      id: 2,
      name: 'DayZ Server #2',
      ip: '192.168.1.2',
      port: 2302,
      status: 'stopped',
      currentPlayers: 0,
      maxPlayers: 40,
      map: 'enoch',
      gameVersion: '1.24',
    ),
  ];

  setUp(() {
    mockApiClient = MockNitradoApiClient();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        nitradoApiClientProvider.overrideWithValue(mockApiClient),
      ],
    );
  }

  group('ServerSelectionNotifier', () {
    test('initial state has empty servers and no loading', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(serverSelectionNotifierProvider);
      expect(state.servers, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('fetchServers populates servers on success', () async {
      when(() => mockApiClient.getServers())
          .thenAnswer((_) async => sampleServers);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(serverSelectionNotifierProvider.notifier)
          .fetchServers();

      final state = container.read(serverSelectionNotifierProvider);
      expect(state.servers, equals(sampleServers));
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('fetchServers sets error on failure', () async {
      when(() => mockApiClient.getServers())
          .thenThrow(Exception('Network error'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(serverSelectionNotifierProvider.notifier)
          .fetchServers();

      final state = container.read(serverSelectionNotifierProvider);
      expect(state.servers, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('Error al obtener servidores'));
    });

    test('fetchServers returns empty list when no servers', () async {
      when(() => mockApiClient.getServers()).thenAnswer((_) async => []);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(serverSelectionNotifierProvider.notifier)
          .fetchServers();

      final state = container.read(serverSelectionNotifierProvider);
      expect(state.servers, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });
  });

  group('selectedServerProvider', () {
    test('initial value is null', () {
      final container = createContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedServerProvider), isNull);
    });

    test('can store and retrieve a selected server', () {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(selectedServerProvider.notifier).state = sampleServers[0];
      expect(container.read(selectedServerProvider), equals(sampleServers[0]));
    });
  });
}
