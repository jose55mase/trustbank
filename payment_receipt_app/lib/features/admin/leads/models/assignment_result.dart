class AssignmentResult {
  final int assignedCount;
  final String advisorName;
  final String advisorEmail;
  final List<int> failedLeadIds;

  AssignmentResult({
    required this.assignedCount,
    required this.advisorName,
    required this.advisorEmail,
    required this.failedLeadIds,
  });

  factory AssignmentResult.fromJson(Map<String, dynamic> json) {
    return AssignmentResult(
      assignedCount: json['assignedCount'] ?? 0,
      advisorName: json['advisorName'] ?? '',
      advisorEmail: json['advisorEmail'] ?? '',
      failedLeadIds: (json['failedLeadIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignedCount': assignedCount,
      'advisorName': advisorName,
      'advisorEmail': advisorEmail,
      'failedLeadIds': failedLeadIds,
    };
  }
}
