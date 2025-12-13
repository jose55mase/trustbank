import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/user.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/expense_category.dart';
import '../../domain/models/expense_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8082/api';
  
  static Future<bool> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] ?? false;
    } else {
      throw Exception('Credenciales inválidas');
    }
  }
  
  static Future<User> createUser({
    required String name,
    required String userCode,
    required String phone,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/users');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'userCode': userCode,
        'phone': phone,
        'email': email,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User(
        id: data['id'].toString(),
        name: data['name'],
        userCode: data['userCode'] ?? '',
        phone: data['phone'],
        email: data['email'],
        registrationDate: DateTime.parse(data['registrationDate'] ?? DateTime.now().toIso8601String()),
      );
    } else {
      throw Exception('Error al crear usuario: ${response.statusCode}');
    }
  }
  
  static Future<List<User>> getUsers() async {
    final url = Uri.parse('$baseUrl/users');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User(
        id: json['id'].toString(),
        name: json['name'],
        userCode: json['userCode'] ?? '',
        phone: json['phone'],
        email: json['email'],
        registrationDate: DateTime.parse(json['registrationDate'] ?? DateTime.now().toIso8601String()),
      )).toList();
    } else {
      throw Exception('Error al obtener usuarios: ${response.statusCode}');
    }
  }
  
  static Future<void> deleteUser(String userId) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    
    final response = await http.delete(url);
    
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar usuario: ${response.statusCode}');
    }
  }
  
  static Future<List<dynamic>> getLoansByUserId(String userId) async {
    final url = Uri.parse('$baseUrl/loans/user/$userId');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }
  
  static Future<dynamic> createLoan({
    required String userId,
    required double amount,
    required double interestRate,
    required int installments,
  }) async {
    final url = Uri.parse('$baseUrl/loans');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user': {'id': int.parse(userId)},
        'amount': amount,
        'interestRate': interestRate,
        'installments': installments,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al crear préstamo: ${response.statusCode}');
    }
  }
  
  static Future<List<dynamic>> getAllLoans() async {
    final url = Uri.parse('$baseUrl/loans');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener préstamos: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> getLoanById(String loanId) async {
    final url = Uri.parse('$baseUrl/loans/$loanId');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener préstamo: ${response.statusCode}');
    }
  }
  
  static Future<Loan> getLoanByIdAsModel(String loanId) async {
    final url = Uri.parse('$baseUrl/loans/$loanId');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Loan.fromJson(data);
    } else {
      throw Exception('Error al obtener préstamo: ${response.statusCode}');
    }
  }
  
  static Future<List<Loan>> getAllLoansAsModels() async {
    final url = Uri.parse('$baseUrl/loans');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Loan.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener préstamos: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> updatePaymentStatus({
    required String loanId,
    bool? pagoAnterior,
    bool? pagoActual,
  }) async {
    final queryParams = <String, String>{};
    if (pagoAnterior != null) queryParams['pagoAnterior'] = pagoAnterior.toString();
    if (pagoActual != null) queryParams['pagoActual'] = pagoActual.toString();
    
    final uri = Uri.parse('$baseUrl/loans/$loanId/payment-status').replace(queryParameters: queryParams);
    
    final response = await http.put(uri);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al actualizar estado de pago: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> createTransaction({
    required String loanId,
    required double amount,
    required String paymentMethod,
    String? notes,
    double? interestAmount,
    double? principalAmount,
  }) async {
    final url = Uri.parse('$baseUrl/transactions');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': 'PAYMENT',
        'loan': {
          'id': int.parse(loanId)
        },
        'amount': amount,
        'paymentMethod': _mapPaymentMethod(paymentMethod),
        'notes': notes ?? '',
        'interestAmount': interestAmount,
        'principalAmount': principalAmount,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al crear transacción: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> updateLoanInstallments({
    required String loanId,
    required int paidInstallments,
  }) async {
    final url = Uri.parse('$baseUrl/loans/$loanId');
    
    final currentLoan = await getLoanById(loanId);
    currentLoan['paidInstallments'] = paidInstallments;
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(currentLoan),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al actualizar préstamo: ${response.statusCode}');
    }
  }
  
  static Future<List<dynamic>> getAllTransactions() async {
    final url = Uri.parse('$baseUrl/transactions');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener transacciones: ${response.statusCode}');
    }
  }
  
  static Future<List<dynamic>> getTransactionsByLoanId(String loanId) async {
    final url = Uri.parse('$baseUrl/transactions/loan/$loanId');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener transacciones del préstamo: ${response.statusCode}');
    }
  }
  
  static Future<List<dynamic>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final queryParams = {
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
    };
    
    final uri = Uri.parse('$baseUrl/transactions/by-date-range').replace(queryParameters: queryParams);
    
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener transacciones por fecha: ${response.statusCode}');
    }
  }
  
  static String _mapPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'efectivo':
        return 'CASH';
      case 'transferencia':
        return 'TRANSFER';
      case 'cheque':
        return 'CHECK';
      default:
        return 'CASH';
    }
  }
  
  // Métodos para categorías de gastos
  static Future<List<ExpenseCategory>> getAllExpenseCategories() async {
    final url = Uri.parse('$baseUrl/expense-categories');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ExpenseCategory.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener categorías: ${response.statusCode}');
    }
  }
  
  static Future<ExpenseCategory> createExpenseCategory({
    required String name,
    required String iconName,
    required String colorValue,
  }) async {
    final url = Uri.parse('$baseUrl/expense-categories');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'iconName': iconName,
        'colorValue': colorValue,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ExpenseCategory.fromJson(data);
    } else {
      throw Exception('Error al crear categoría: ${response.statusCode}');
    }
  }
  
  static Future<void> deleteExpenseCategory(int categoryId) async {
    final url = Uri.parse('$baseUrl/expense-categories/$categoryId');
    
    final response = await http.delete(url);
    
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar categoría: ${response.statusCode}');
    }
  }
  
  // Métodos para gastos
  static Future<List<ExpenseModel>> getAllExpenses() async {
    final url = Uri.parse('$baseUrl/expenses');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ExpenseModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener gastos: ${response.statusCode}');
    }
  }
  
  static Future<ExpenseModel> createExpense({
    required int categoryId,
    required double amount,
    required String description,
    required DateTime expenseDate,
  }) async {
    final url = Uri.parse('$baseUrl/expenses');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'category': {'id': categoryId},
        'amount': amount,
        'description': description,
        'expenseDate': expenseDate.toIso8601String(),
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ExpenseModel.fromJson(data);
    } else {
      throw Exception('Error al crear gasto: ${response.statusCode}');
    }
  }
  
  static Future<List<ExpenseModel>> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final queryParams = {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
    
    final uri = Uri.parse('$baseUrl/expenses/by-date-range').replace(queryParameters: queryParams);
    
    print('Calling expenses API: $uri');
    
    final response = await http.get(uri);
    
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ExpenseModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener gastos por fecha: ${response.statusCode} - ${response.body}');
    }
  }
  
  static Future<void> deleteExpense(int expenseId) async {
    final url = Uri.parse('$baseUrl/expenses/$expenseId');
    
    final response = await http.delete(url);
    
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar gasto: ${response.statusCode}');
    }
  }
}