class AdvisorSummary {
  final int advisorId;
  final String advisorName;
  final String advisorEmail;
  final int assignedLeadCount;

  AdvisorSummary({
    required this.advisorId,
    required this.advisorName,
    required this.advisorEmail,
    required this.assignedLeadCount,
  });

  factory AdvisorSummary.fromJson(Map<String, dynamic> json) {
    return AdvisorSummary(
      advisorId: json['advisorId'] ?? 0,
      advisorName: json['advisorName'] ?? '',
      advisorEmail: json['advisorEmail'] ?? '',
      assignedLeadCount: json['assignedLeadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advisorId': advisorId,
      'advisorName': advisorName,
      'advisorEmail': advisorEmail,
      'assignedLeadCount': assignedLeadCount,
    };
  }
}
