class ExpenseCategory {
  final int? id;
  final String name;
  final String iconName;
  final String colorValue;
  final DateTime? createdAt;

  ExpenseCategory({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    this.createdAt,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'],
      name: json['name'],
      iconName: json['iconName'],
      colorValue: json['colorValue'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorValue': colorValue,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}