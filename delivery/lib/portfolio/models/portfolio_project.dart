/// Representa un proyecto del portafolio.
class PortfolioProject {
  final String id;
  final String title; // max 100 chars
  final String description; // max 500 chars
  final String mainImageUrl;
  final List<String> additionalImageUrls; // max 5
  final String? externalLink;
  final List<String> technologies;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PortfolioProject({
    required this.id,
    required this.title,
    required this.description,
    required this.mainImageUrl,
    this.additionalImageUrls = const [],
    this.externalLink,
    this.technologies = const [],
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  PortfolioProject copyWith({
    String? id,
    String? title,
    String? description,
    String? mainImageUrl,
    List<String>? additionalImageUrls,
    String? externalLink,
    List<String>? technologies,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PortfolioProject(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      additionalImageUrls: additionalImageUrls ?? this.additionalImageUrls,
      externalLink: externalLink ?? this.externalLink,
      technologies: technologies ?? this.technologies,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'mainImageUrl': mainImageUrl,
      'additionalImageUrls': additionalImageUrls,
      'externalLink': externalLink,
      'technologies': technologies,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PortfolioProject.fromJson(Map<String, dynamic> json) {
    return PortfolioProject(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      mainImageUrl: json['mainImageUrl'] as String,
      additionalImageUrls:
          (json['additionalImageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      externalLink: json['externalLink'] as String?,
      technologies:
          (json['technologies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isFeatured: json['isFeatured'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PortfolioProject) return false;
    return id == other.id &&
        title == other.title &&
        description == other.description &&
        mainImageUrl == other.mainImageUrl &&
        externalLink == other.externalLink &&
        isFeatured == other.isFeatured;
  }

  @override
  int get hashCode => Object.hash(id, title, description, mainImageUrl);
}
