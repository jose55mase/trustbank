import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nitrado_server_manager/core/api/nitrado_api_client.dart';
import 'package:nitrado_server_manager/core/api/api_provider.dart';
import 'package:nitrado_server_manager/features/server_selection/server_selection_screen.dart';
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

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        nitradoApiClientProvider.overrideWithValue(mockApiClient),
      ],
      child: const MaterialApp(home: ServerSelectionScreen()),
    );
  }

  group('ServerSelectionScreen', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      final completer = Completer<List<GameServer>>();
      when(() => mockApiClient.getServers())
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('shows server list on success', (tester) async {
      when(() => mockApiClient.getServers())
          .thenAnswer((_) async => sampleServers);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('DayZ Server #1'), findsOneWidget);
      expect(find.text('DayZ Server #2'), findsOneWidget);
      expect(find.textContaining('10/60'), findsOneWidget);
      expect(find.textContaining('0/40'), findsOneWidget);
    });

    testWidgets('shows empty message when no servers', (tester) async {
      when(() => mockApiClient.getServers()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.text('No se encontraron servidores DayZ activos'),
        findsOneWidget,
      );
    });

    testWidgets('shows error with retry button on failure', (tester) async {
      when(() => mockApiClient.getServers())
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('Error al obtener servidores'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('retry button re-fetches servers', (tester) async {
      // First call fails
      when(() => mockApiClient.getServers())
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Second call succeeds
      when(() => mockApiClient.getServers())
          .thenAnswer((_) async => sampleServers);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('DayZ Server #1'), findsOneWidget);
    });

    testWidgets('selecting a server updates selectedServerProvider',
        (tester) async {
      when(() => mockApiClient.getServers())
          .thenAnswer((_) async => sampleServers);

      late ProviderContainer container;

      final router = GoRouter(
        initialLocation: '/servers',
        routes: [
          GoRoute(
            path: '/servers',
            builder: (context, state) => const ServerSelectionScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) =>
                const Scaffold(body: Text('Dashboard')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nitradoApiClientProvider.overrideWithValue(mockApiClient),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('DayZ Server #1'));
      await tester.pumpAndSettle();

      expect(
        container.read(selectedServerProvider),
        equals(sampleServers[0]),
      );
    });

    testWidgets('displays app bar with correct title', (tester) async {
      when(() => mockApiClient.getServers()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Selección de Servidor'), findsOneWidget);
    });
  });
}
