class Expense {
  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final String description;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
  });
}

enum ExpenseCategory {
  food,
  clothing,
  transport,
  entertainment,
  health,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get name {
    switch (this) {
      case ExpenseCategory.food:
        return 'Comida';
      case ExpenseCategory.clothing:
        return 'Ropa';
      case ExpenseCategory.transport:
        return 'Transporte';
      case ExpenseCategory.entertainment:
        return 'Entretenimiento';
      case ExpenseCategory.health:
        return 'Salud';
      case ExpenseCategory.other:
        return 'Otros';
    }
  }
}
