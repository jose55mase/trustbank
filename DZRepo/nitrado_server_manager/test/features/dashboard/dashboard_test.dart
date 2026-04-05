import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nitrado_server_manager/core/api/api_provider.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client.dart';
import 'package:nitrado_server_manager/features/dashboard/dashboard_notifier.dart';
import 'package:nitrado_server_manager/features/dashboard/dashboard_screen.dart';
import 'package:nitrado_server_manager/features/dashboard/status_color.dart';
import 'package:nitrado_server_manager/features/server_selection/server_selection_notifier.dart';
import 'package:nitrado_server_manager/shared/models/game_server.dart';

class MockNitradoApiClient extends Mock implements NitradoApiClient {}

GameServer _testServer({
  String status = 'started',
  String name = 'Test Server',
}) {
  return GameServer(
    id: 1,
    name: name,
    ip: '192.168.1.1',
    port: 2302,
    status: status,
    currentPlayers: 10,
    maxPlayers: 60,
    map: 'chernarusplus',
    gameVersion: '1.24',
  );
}

void main() {
  group('statusColor', () {
    test('returns green for started', () {
      expect(statusColor('started'), Colors.green);
    });

    test('returns red for stopped', () {
      expect(statusColor('stopped'), Colors.red);
    });

    test('returns yellow for restarting', () {
      expect(statusColor('restarting'), Colors.yellow);
    });

    test('returns yellow for installing', () {
      expect(statusColor('installing'), Colors.yellow);
    });

    test('returns yellow for unknown status', () {
      expect(statusColor('unknown'), Colors.yellow);
    });
  });

  group('DashboardNotifier', () {
    late MockNitradoApiClient mockApi;

    setUp(() {
      mockApi = MockNitradoApiClient();
    });

    test('fetchStatus updates state with server data', () async {
      final server = _testServer();
      when(() => mockApi.getServerStatus(1)).thenAnswer((_) async => server);

      final container = ProviderContainer(
        overrides: [
          nitradoApiClientProvider.overrideWithValue(mockApi),
          selectedServerProvider.overrideWith((ref) => server),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(dashboardNotifierProvider.notifier);
      await notifier.fetchStatus();

      final state = container.read(dashboardNotifierProvider);
      expect(state.server, server);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });

    test('fetchStatus sets error on API failure', () async {
      final server = _testServer();
      when(() => mockApi.getServerStatus(1))
          .thenThrow(Exception('network error'));

      final container = ProviderContainer(
        overrides: [
          nitradoApiClientProvider.overrideWithValue(mockApi),
          selectedServerProvider.overrideWith((ref) => server),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(dashboardNotifierProvider.notifier);
      await notifier.fetchStatus();

      final state = container.read(dashboardNotifierProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('Error'));
      expect(state.isLoading, false);
    });

    test('fetchStatus does nothing when no server selected', () async {
      final container = ProviderContainer(
        overrides: [
          nitradoApiClientProvider.overrideWithValue(mockApi),
          // selectedServerProvider defaults to null
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(dashboardNotifierProvider.notifier);
      await notifier.fetchStatus();

      final state = container.read(dashboardNotifierProvider);
      expect(state.server, isNull);
      expect(state.isLoading, false);
      verifyNever(() => mockApi.getServerStatus(any()));
    });
  });

  group('DashboardScreen widget', () {
    late MockNitradoApiClient mockApi;

    setUp(() {
      mockApi = MockNitradoApiClient();
    });

    Widget buildApp({GameServer? server}) {
      final s = server ?? _testServer();
      // Stub the API call so the screen can fetch.
      when(() => mockApi.getServerStatus(s.id))
          .thenAnswer((_) async => s);

      return ProviderScope(
        overrides: [
          nitradoApiClientProvider.overrideWithValue(mockApi),
          selectedServerProvider.overrideWith((ref) => s),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      );
    }

    testWidgets('displays server info after fetch', (tester) async {
      final server = _testServer(name: 'My DayZ Server');
      await tester.pumpWidget(buildApp(server: server));
      await tester.pumpAndSettle();

      expect(find.text('My DayZ Server'), findsOneWidget);
      expect(find.text('192.168.1.1'), findsOneWidget);
      expect(find.text('2302'), findsOneWidget);
      expect(find.text('10/60'), findsOneWidget);
      expect(find.text('chernarusplus'), findsOneWidget);
      expect(find.text('1.24'), findsOneWidget);
    });

    testWidgets('shows status label for started', (tester) async {
      await tester.pumpWidget(buildApp(server: _testServer(status: 'started')));
      await tester.pumpAndSettle();

      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('shows status label for stopped', (tester) async {
      await tester.pumpWidget(buildApp(server: _testServer(status: 'stopped')));
      await tester.pumpAndSettle();

      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('shows error view with retry when API fails and no cached server',
        (tester) async {
      when(() => mockApi.getServerStatus(any()))
          .thenThrow(Exception('timeout'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nitradoApiClientProvider.overrideWithValue(mockApi),
            selectedServerProvider.overrideWith((ref) => _testServer()),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Even on error, we still show the selected server data as fallback.
      // The error banner should be visible.
      expect(find.text('Reintentar'), findsWidgets);
    });
  });
}
