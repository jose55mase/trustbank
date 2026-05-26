/// Tipos de contenido editable.
enum ContentType { text, image, title }

/// Contenido editable de la página pública.
class EditableContent {
  final String id;
  final String section; // e.g., "hero", "about", "footer"
  final String key; // e.g., "title", "subtitle", "description"
  final String value;
  final ContentType type;
  final DateTime updatedAt;

  const EditableContent({
    required this.id,
    required this.section,
    required this.key,
    required this.value,
    required this.type,
    required this.updatedAt,
  });

  EditableContent copyWith({
    String? id,
    String? section,
    String? key,
    String? value,
    ContentType? type,
    DateTime? updatedAt,
  }) {
    return EditableContent(
      id: id ?? this.id,
      section: section ?? this.section,
      key: key ?? this.key,
      value: value ?? this.value,
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section': section,
      'key': key,
      'value': value,
      'type': type.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EditableContent.fromJson(Map<String, dynamic> json) {
    return EditableContent(
      id: json['id'] as String,
      section: json['section'] as String,
      key: json['key'] as String,
      value: json['value'] as String,
      type: ContentType.values.byName(json['type'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditableContent) return false;
    return id == other.id &&
        section == other.section &&
        key == other.key &&
        value == other.value &&
        type == other.type;
  }

  @override
  int get hashCode => Object.hash(id, section, key, value, type);
}
