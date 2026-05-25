class MappingResult {
  final Map<int, String?> columnMapping; // índice -> campo (null si no mapeado)
  final List<String> headers; // encabezados originales del Excel
  final List<List<String>> previewRows; // primeras 5 filas para vista previa
  final bool hasUnmappedColumns;

  MappingResult({
    required this.columnMapping,
    required this.headers,
    required this.previewRows,
    required this.hasUnmappedColumns,
  });

  factory MappingResult.fromJson(Map<String, dynamic> json) {
    // Parse columnMapping: JSON keys are string indices, convert to int keys
    final rawMapping = json['columnMapping'] as Map<String, dynamic>? ?? {};
    final Map<int, String?> parsedMapping = {};
    for (final entry in rawMapping.entries) {
      final index = int.tryParse(entry.key);
      if (index != null) {
        parsedMapping[index] = entry.value as String?;
      }
    }

    // Parse headers
    final List<String> parsedHeaders = (json['headers'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // Parse previewRows: List<List<String>>
    final List<List<String>> parsedPreviewRows =
        (json['previewRows'] as List<dynamic>?)
                ?.map((row) => (row as List<dynamic>)
                    .map((cell) => cell.toString())
                    .toList())
                .toList() ??
            [];

    return MappingResult(
      columnMapping: parsedMapping,
      headers: parsedHeaders,
      previewRows: parsedPreviewRows,
      hasUnmappedColumns: json['hasUnmappedColumns'] as bool? ?? false,
    );
  }
}
