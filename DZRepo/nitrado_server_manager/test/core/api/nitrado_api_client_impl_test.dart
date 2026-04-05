import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nitrado_server_manager/core/api/api_exceptions.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client_impl.dart';
import 'package:nitrado_server_manager/shared/models/models.dart';

// ── Mocks ──────────────────────────────────────────────────────────

class MockDio extends Mock implements Dio {}

// ── Helpers ────────────────────────────────────────────────────────

Response<T> _ok<T>(T data) => Response<T>(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
      data: data,
    );

void main() {
  late MockDio dio;
  late NitradoApiClientImpl client;

  setUp(() {
    dio = MockDio();
    client = NitradoApiClientImpl(dio);
  });

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  // ── Error handling (preserved from Task 5.1) ───────────────────

  group('error handling', () {
    late Dio realDio;
    late NitradoApiClientImpl realClient;

    setUp(() {
      realDio = Dio(BaseOptions(baseUrl: 'https://api.nitrado.net'));
      realClient = NitradoApiClientImpl(realDio);
    });

    test('throws UnauthorizedException on 401', () async {
      realDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: <String, dynamic>{'message': 'Invalid token'},
          ),
          type: DioExceptionType.badResponse,
        )),
      ));
      expect(
        () => realClient.request(() => realDio.get<dynamic>('/test')),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws ApiException with API message on 4xx', () async {
      realDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 422,
            data: <String, dynamic>{'message': 'Validation failed'},
          ),
          type: DioExceptionType.badResponse,
        )),
      ));
      try {
        await realClient.request(() => realDio.get<dynamic>('/test'));
        fail('Should have thrown');
      } on ApiException catch (e) {
        expect(e.message, 'Validation failed');
        expect(e.statusCode, 422);
      }
    });

    test('throws ApiException with generic message on 5xx', () async {
      realDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 500,
            data: <String, dynamic>{'message': 'Internal server error'},
          ),
          type: DioExceptionType.badResponse,
        )),
      ));
      try {
        await realClient.request(() => realDio.get<dynamic>('/test'));
        fail('Should have thrown');
      } on ApiException catch (e) {
        expect(
            e.message, 'Error del servidor. Inténtalo de nuevo más tarde.');
        expect(e.statusCode, 500);
      }
    });

    test('throws ApiException on connection error', () async {
      realDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(DioException(
          requestOptions: options,
          message: 'Connection refused',
          type: DioExceptionType.connectionError,
        )),
      ));
      expect(
        () => realClient.request(() => realDio.get<dynamic>('/test')),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── getServers ─────────────────────────────────────────────────

  group('getServers', () {
    test('returns only DayZ servers', () async {
      when(() => dio.get<Map<String, dynamic>>(
            '/services',
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({
                'data': {
                  'services': [
                    {
                      'id': 100,
                      'status': 'started',
                      'details': {
                        'game': 'DayZ',
                        'name': 'My DayZ',
                        'address': '1.2.3.4',
                        'port': 2302,
                        'players_current': 5,
                        'players_max': 60,
                        'map': 'chernarusplus',
                        'version': '1.24',
                      },
                    },
                    {
                      'id': 200,
                      'status': 'started',
                      'details': {
                        'game': 'Minecraft',
                        'name': 'MC Server',
                        'address': '5.6.7.8',
                        'port': 25565,
                      },
                    },
                  ],
                },
              }));

      final servers = await client.getServers();
      expect(servers, hasLength(1));
      expect(servers.first.id, 100);
      expect(servers.first.name, 'My DayZ');
      expect(servers.first.ip, '1.2.3.4');
      expect(servers.first.port, 2302);
      expect(servers.first.currentPlayers, 5);
      expect(servers.first.maxPlayers, 60);
    });

    test('returns empty list when no DayZ servers', () async {
      when(() => dio.get<Map<String, dynamic>>('/services'))
          .thenAnswer((_) async => _ok<Map<String, dynamic>>({
                'data': {
                  'services': <dynamic>[],
                },
              }));

      final servers = await client.getServers();
      expect(servers, isEmpty);
    });
  });

  // ── getServerStatus ────────────────────────────────────────────

  group('getServerStatus', () {
    test('parses gameserver details', () async {
      when(() => dio.get<Map<String, dynamic>>(
            '/services/100/gameservers',
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({
                'data': {
                  'gameserver': {
                    'ip': '1.2.3.4',
                    'port': 2302,
                    'status': 'started',
                    'query': {
                      'server_name': 'My DayZ',
                      'player_current': 10,
                      'player_max': 60,
                      'map': 'chernarusplus',
                      'version': '1.24',
                    },
                  },
                },
              }));

      final server = await client.getServerStatus(100);
      expect(server.id, 100);
      expect(server.name, 'My DayZ');
      expect(server.ip, '1.2.3.4');
      expect(server.port, 2302);
      expect(server.status, 'started');
      expect(server.currentPlayers, 10);
      expect(server.maxPlayers, 60);
      expect(server.map, 'chernarusplus');
      expect(server.gameVersion, '1.24');
    });
  });

  // ── serverAction ───────────────────────────────────────────────

  group('serverAction', () {
    test('restart calls restart endpoint', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/restart',
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({}));

      await client.serverAction(100, ServerAction.restart);
      verify(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/restart',
          )).called(1);
    });

    test('stop calls stop endpoint', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/stop',
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({}));

      await client.serverAction(100, ServerAction.stop);
      verify(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/stop',
          )).called(1);
    });

    test('start calls restart endpoint (Nitrado uses restart for start)',
        () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/restart',
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({}));

      await client.serverAction(100, ServerAction.start);
      verify(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/restart',
          )).called(1);
    });
  });

  // ── getPlayers ─────────────────────────────────────────────────

  group('getPlayers', () {
    test('parses player list', () async {
      when(() => dio.get<Map<String, dynamic>>(
            '/services/100/gameservers/games/players',
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({
                'data': {
                  'players': [
                    {'id': '76561198000000001', 'name': 'Alice', 'online': true},
                    {'id': '76561198000000002', 'name': 'Bob', 'online': false},
                  ],
                },
              }));

      final players = await client.getPlayers(100);
      expect(players, hasLength(2));
      expect(players[0].id, '76561198000000001');
      expect(players[0].name, 'Alice');
      expect(players[0].online, true);
      expect(players[1].name, 'Bob');
      expect(players[1].online, false);
    });
  });

  // ── kickPlayer ─────────────────────────────────────────────────

  group('kickPlayer', () {
    test('sends POST with player_id', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/games/players/kick',
            data: {'player_id': 'p1'},
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({}));

      await client.kickPlayer(100, 'p1');
      verify(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/games/players/kick',
            data: {'player_id': 'p1'},
          )).called(1);
    });
  });

  // ── banPlayer ──────────────────────────────────────────────────

  group('banPlayer', () {
    test('sends POST with player_id and optional reason', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/games/players/ban',
            data: {'player_id': 'p1', 'reason': 'cheating'},
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({}));

      await client.banPlayer(100, 'p1', reason: 'cheating');
      verify(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/games/players/ban',
            data: {'player_id': 'p1', 'reason': 'cheating'},
          )).called(1);
    });

    test('sends POST without reason when null', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/games/players/ban',
            data: {'player_id': 'p1'},
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({}));

      await client.banPlayer(100, 'p1');
      verify(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/games/players/ban',
            data: {'player_id': 'p1'},
          )).called(1);
    });
  });

  // ── getBanList ─────────────────────────────────────────────────

  group('getBanList', () {
    test('parses ban list', () async {
      when(() => dio.get<Map<String, dynamic>>(
            '/services/100/gameservers/games/banlist',
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({
                'data': {
                  'banlist': [
                    {
                      'id': 'p1',
                      'name': 'Cheater',
                      'reason': 'hacking',
                      'banned_at': '2024-01-15T10:30:00Z',
                    },
                    {
                      'id': 'p2',
                      'name': 'Griefer',
                      'reason': null,
                      'banned_at': null,
                    },
                  ],
                },
              }));

      final list = await client.getBanList(100);
      expect(list, hasLength(2));
      expect(list[0].id, 'p1');
      expect(list[0].name, 'Cheater');
      expect(list[0].reason, 'hacking');
      expect(list[0].bannedAt, DateTime.utc(2024, 1, 15, 10, 30));
      expect(list[1].reason, isNull);
      expect(list[1].bannedAt, isNull);
    });
  });

  // ── unbanPlayer ────────────────────────────────────────────────

  group('unbanPlayer', () {
    test('sends DELETE with player_id', () async {
      when(() => dio.delete<Map<String, dynamic>>(
            '/services/100/gameservers/games/banlist',
            data: {'player_id': 'p1'},
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({}));

      await client.unbanPlayer(100, 'p1');
      verify(() => dio.delete<Map<String, dynamic>>(
            '/services/100/gameservers/games/banlist',
            data: {'player_id': 'p1'},
          )).called(1);
    });
  });

  // ── listFiles ──────────────────────────────────────────────────

  group('listFiles', () {
    test('parses file entries', () async {
      when(() => dio.get<Map<String, dynamic>>(
            '/services/100/gameservers/file_server/list',
            queryParameters: {'dir': '/config'},
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({
                'data': {
                  'entries': [
                    {
                      'name': 'types.xml',
                      'path': '/config/types.xml',
                      'type': 'file',
                      'size': 1024,
                    },
                    {
                      'name': 'db',
                      'path': '/config/db',
                      'type': 'dir',
                      'size': null,
                    },
                  ],
                },
              }));

      final files = await client.listFiles(100, '/config');
      expect(files, hasLength(2));
      expect(files[0].name, 'types.xml');
      expect(files[0].type, 'file');
      expect(files[0].size, 1024);
      expect(files[1].type, 'dir');
      expect(files[1].size, isNull);
    });
  });

  // ── uploadFile ─────────────────────────────────────────────────

  group('uploadFile', () {
    test('sends POST with content and path query param', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/file_server/upload',
            queryParameters: {'path': '/config/types.xml'},
            data: '<types/>',
            options: any(named: 'options'),
          )).thenAnswer((_) async => _ok<Map<String, dynamic>>({}));

      await client.uploadFile(100, '/config/types.xml', '<types/>');
      verify(() => dio.post<Map<String, dynamic>>(
            '/services/100/gameservers/file_server/upload',
            queryParameters: {'path': '/config/types.xml'},
            data: '<types/>',
            options: any(named: 'options'),
          )).called(1);
    });
  });

  // ── extractMessage ─────────────────────────────────────────────

  group('extractMessage', () {
    test('extracts message from map response', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: <String, dynamic>{'message': 'Server not found'},
      );
      expect(client.extractMessage(response), 'Server not found');
    });

    test('returns null when no message field', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: <String, dynamic>{'error': 'something'},
      );
      expect(client.extractMessage(response), isNull);
    });

    test('returns null when data is not a map', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: 'plain text',
      );
      expect(client.extractMessage(response), isNull);
    });
  });
}
