import '../domain/models/user.dart';
import '../domain/models/loan.dart';
import '../domain/models/expense.dart';

class DummyData {
  static final List<User> users = [
    User(
      id: '1',
      name: 'Juan Pérez',
      phone: '+1234567890',
      email: 'juan.perez@email.com',
      registrationDate: DateTime(2024, 1, 15),
    ),
    User(
      id: '2',
      name: 'María García',
      phone: '+1234567891',
      email: 'maria.garcia@email.com',
      registrationDate: DateTime(2024, 2, 10),
    ),
    User(
      id: '3',
      name: 'Carlos Rodríguez',
      phone: '+1234567892',
      email: 'carlos.rodriguez@email.com',
      registrationDate: DateTime(2024, 3, 5),
    ),
    User(
      id: '4',
      name: 'Ana Martínez',
      phone: '+1234567893',
      email: 'ana.martinez@email.com',
      registrationDate: DateTime(2024, 1, 20),
    ),
    User(
      id: '5',
      name: 'Luis Fernández',
      phone: '+1234567894',
      email: 'luis.fernandez@email.com',
      registrationDate: DateTime(2024, 2, 28),
    ),
  ];

  static final List<Loan> loans = [
    Loan(
      id: 'L001',
      userId: '1',
      amount: 5000000,
      interestRate: 15,
      installments: 12,
      paidInstallments: 5,
      startDate: DateTime(2024, 2, 1),
      status: LoanStatus.active,
    ),
    Loan(
      id: 'L002',
      userId: '2',
      amount: 10000000,
      interestRate: 12,
      installments: 24,
      paidInstallments: 10,
      startDate: DateTime(2024, 1, 15),
      status: LoanStatus.active,
    ),
    Loan(
      id: 'L003',
      userId: '3',
      amount: 3000000,
      interestRate: 18,
      installments: 6,
      paidInstallments: 6,
      startDate: DateTime(2023, 12, 1),
      status: LoanStatus.completed,
    ),
    Loan(
      id: 'L004',
      userId: '1',
      amount: 7500000,
      interestRate: 14,
      installments: 18,
      paidInstallments: 8,
      startDate: DateTime(2024, 3, 1),
      status: LoanStatus.active,
    ),
    Loan(
      id: 'L005',
      userId: '4',
      amount: 15000000,
      interestRate: 10,
      installments: 36,
      paidInstallments: 12,
      startDate: DateTime(2024, 1, 1),
      status: LoanStatus.active,
    ),
    Loan(
      id: 'L006',
      userId: '5',
      amount: 2000000,
      interestRate: 20,
      installments: 4,
      paidInstallments: 2,
      startDate: DateTime(2024, 4, 1),
      status: LoanStatus.active,
    ),
  ];

  static User getUserById(String userId) {
    return users.firstWhere((user) => user.id == userId);
  }

  static List<Loan> getLoansByUserId(String userId) {
    return loans.where((loan) => loan.userId == userId).toList();
  }

  static List<Expense> getExpensesByPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Día':
        return expenses.where((e) => 
          e.date.year == now.year && 
          e.date.month == now.month && 
          e.date.day == now.day
        ).toList();
      case 'Mes':
        return expenses.where((e) => 
          e.date.year == now.year && 
          e.date.month == now.month
        ).toList();
      default:
        return expenses;
    }
  }

  static final List<Expense> expenses = [
    Expense(
      id: 'E001',
      category: 'Comida',
      amount: 50000,
      date: DateTime.now(),
      description: 'Almuerzo',
    ),
    Expense(
      id: 'E002',
      category: 'Transporte',
      amount: 30000,
      date: DateTime.now(),
      description: 'Taxi',
    ),
    Expense(
      id: 'E003',
      category: 'Ropa',
      amount: 150000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      description: 'Camisa',
    ),
    Expense(
      id: 'E004',
      category: 'Comida',
      amount: 80000,
      date: DateTime.now().subtract(const Duration(days: 5)),
      description: 'Cena',
    ),
    Expense(
      id: 'E005',
      category: 'Entretenimiento',
      amount: 40000,
      date: DateTime.now().subtract(const Duration(days: 8)),
      description: 'Cine',
    ),
    Expense(
      id: 'E006',
      category: 'Salud',
      amount: 120000,
      date: DateTime.now(),
      description: 'Farmacia',
    ),
  ];
}
