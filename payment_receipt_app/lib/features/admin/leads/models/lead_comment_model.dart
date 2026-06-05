class LeadCommentModel {
  final int? id;
  final int leadId;
  final int? userId;
  final String? authorName;
  final String text;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isLegacy;

  LeadCommentModel({
    this.id,
    required this.leadId,
    this.userId,
    this.authorName,
    required this.text,
    required this.createdAt,
    this.editedAt,
    this.isLegacy = false,
  });

  factory LeadCommentModel.fromJson(Map<String, dynamic> json) {
    return LeadCommentModel(
      id: json['id'] as int?,
      leadId: json['leadId'] as int? ?? 0,
      userId: json['userId'] as int?,
      authorName: json['authorName'] as String?,
      text: json['text'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      editedAt: _parseDate(json['editedAt']),
      isLegacy: json['isLegacy'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leadId': leadId,
      'userId': userId,
      'authorName': authorName,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isLegacy': isLegacy,
    };
  }

  LeadCommentModel copyWith({
    int? id,
    int? leadId,
    int? userId,
    String? authorName,
    String? text,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isLegacy,
  }) {
    return LeadCommentModel(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isLegacy: isLegacy ?? this.isLegacy,
    );
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      return null;
    }
  }
}
