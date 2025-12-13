import 'expense_category.dart';

class ExpenseModel {
  final int? id;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final DateTime expenseDate;
  final DateTime? createdAt;

  ExpenseModel({
    this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.expenseDate,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      category: ExpenseCategory.fromJson(json['category']),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      expenseDate: DateTime.parse(json['expenseDate']),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': {'id': category.id},
      'amount': amount,
      'description': description,
      'expenseDate': expenseDate.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}