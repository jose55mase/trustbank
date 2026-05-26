/// Elemento del carrusel interactivo.
class CarouselItem {
  final String projectId;
  final String title; // max 60 chars (display)
  final String description; // max 200 chars (display)
  final String imageUrl;
  final int order;

  const CarouselItem({
    required this.projectId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.order,
  });

  CarouselItem copyWith({
    String? projectId,
    String? title,
    String? description,
    String? imageUrl,
    int? order,
  }) {
    return CarouselItem(
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'order': order,
    };
  }

  factory CarouselItem.fromJson(Map<String, dynamic> json) {
    return CarouselItem(
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      order: json['order'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CarouselItem) return false;
    return projectId == other.projectId &&
        title == other.title &&
        description == other.description &&
        imageUrl == other.imageUrl &&
        order == other.order;
  }

  @override
  int get hashCode => Object.hash(projectId, title, description, imageUrl, order);
}
