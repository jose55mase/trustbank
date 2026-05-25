class ImportResult {
  final int successCount;
  final int errorCount;
  final int duplicateCount;
  final int totalRows;
  final int importId;

  ImportResult({
    required this.successCount,
    required this.errorCount,
    required this.duplicateCount,
    required this.totalRows,
    required this.importId,
  });

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      successCount: json['successCount'] ?? 0,
      errorCount: json['errorCount'] ?? 0,
      duplicateCount: json['duplicateCount'] ?? 0,
      totalRows: json['totalRows'] ?? 0,
      importId: json['importId'] ?? 0,
    );
  }
}
