/// Pure helper functions for log classification and filtering.
///
/// Used by Property 14: Clasificación de niveles de log
/// and Property 15: Filtrado de logs por texto de búsqueda.

/// Log severity levels.
enum LogLevel { error, warning, info }

/// Classifies a log line into a [LogLevel] based on its content.
///
/// - Contains "ERROR" → [LogLevel.error]
/// - Contains "WARNING" → [LogLevel.warning]
/// - Otherwise → [LogLevel.info]
LogLevel classifyLogLevel(String line) {
  final upper = line.toUpperCase();
  if (upper.contains('ERROR')) return LogLevel.error;
  if (upper.contains('WARNING')) return LogLevel.warning;
  return LogLevel.info;
}

/// Filters [logs] to only entries containing [query] (case-insensitive).
///
/// Returns all logs if [query] is empty.
List<String> filterLogs(List<String> logs, String query) {
  if (query.isEmpty) return logs;
  final lowerQuery = query.toLowerCase();
  return logs.where((line) => line.toLowerCase().contains(lowerQuery)).toList();
}
