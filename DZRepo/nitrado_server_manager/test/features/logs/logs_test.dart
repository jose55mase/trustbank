import 'package:flutter_test/flutter_test.dart';
import 'package:nitrado_server_manager/features/logs/logs_helpers.dart';

void main() {
  group('classifyLogLevel', () {
    test('classifies lines containing ERROR as error', () {
      expect(classifyLogLevel('2024-01-01 ERROR: something failed'),
          LogLevel.error);
    });

    test('classifies lines containing WARNING as warning', () {
      expect(classifyLogLevel('2024-01-01 WARNING: disk space low'),
          LogLevel.warning);
    });

    test('classifies other lines as info', () {
      expect(classifyLogLevel('2024-01-01 Server started successfully'),
          LogLevel.info);
    });

    test('classification is case-insensitive', () {
      expect(classifyLogLevel('error in module'), LogLevel.error);
      expect(classifyLogLevel('Warning: timeout'), LogLevel.warning);
    });

    test('ERROR takes priority over WARNING when both present', () {
      expect(classifyLogLevel('ERROR WARNING mixed'), LogLevel.error);
    });

    test('empty string is classified as info', () {
      expect(classifyLogLevel(''), LogLevel.info);
    });
  });

  group('filterLogs', () {
    final logs = [
      '2024-01-01 ERROR: connection failed',
      '2024-01-01 WARNING: high memory usage',
      '2024-01-01 INFO: server started',
      '2024-01-01 INFO: player joined',
    ];

    test('returns all logs when query is empty', () {
      expect(filterLogs(logs, ''), logs);
    });

    test('filters logs by text case-insensitively', () {
      final result = filterLogs(logs, 'error');
      expect(result, hasLength(1));
      expect(result.first, contains('ERROR'));
    });

    test('returns matching entries for partial text', () {
      final result = filterLogs(logs, 'server');
      expect(result, hasLength(1));
      expect(result.first, contains('server started'));
    });

    test('returns empty list when no matches', () {
      expect(filterLogs(logs, 'nonexistent'), isEmpty);
    });

    test('returns multiple matches', () {
      final result = filterLogs(logs, 'INFO');
      expect(result, hasLength(2));
    });

    test('handles empty log list', () {
      expect(filterLogs([], 'test'), isEmpty);
    });
  });
}
