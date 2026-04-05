// Feature: nitrado-server-manager, Property 15: Filtrado de logs por texto de búsqueda
// **Validates: Requirements 9.3**

import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/features/logs/logs_helpers.dart';

/// Safe printable characters for generating log lines and search queries.
const _safeChars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 :_-./[]';

/// Generator for a single log line.
final _logLineGen = any.stringOf(_safeChars);

/// Generator for a list of log lines (0–10 entries).
final _logListGen = any.listWithLengthInRange(0, 10, _logLineGen);

/// Generator for a non-empty search query (1–8 chars from safe set).
final _queryGen = any.nonEmptyStringOf(_safeChars);

/// Combined generator: (logs, query).
final _inputGen = any.combine2(
  _logListGen,
  _queryGen,
  (List<String> logs, String query) => _FilterInput(logs, query),
);

void main() {
  Glados(_inputGen, ExploreConfig(numRuns: 100)).test(
    'filterLogs returns exactly the entries containing the query (case-insensitive)',
    (_FilterInput input) {
      final result = filterLogs(input.logs, input.query);
      final lowerQuery = input.query.toLowerCase();

      // 1. Every returned entry must contain the query (case-insensitive)
      for (final entry in result) {
        expect(
          entry.toLowerCase().contains(lowerQuery),
          isTrue,
          reason: 'Returned entry "$entry" does not contain query "${input.query}"',
        );
      }

      // 2. Every original entry that contains the query must be in the result
      final expected = input.logs
          .where((line) => line.toLowerCase().contains(lowerQuery))
          .toList();
      expect(result, equals(expected));
    },
  );
}

/// Helper class to bundle logs and query for the generator.
class _FilterInput {
  final List<String> logs;
  final String query;
  _FilterInput(this.logs, this.query);
}
