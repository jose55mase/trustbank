import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/user.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/expense_category.dart';
import '../../domain/models/expense_model.dart';
import '../../services/auth_service.dart';

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
      if (data['success'] == true) {
        await AuthService.saveUser(data['user']);
        return true;
      }
      return false;
    } else {
      throw Exception('Credenciales inválidas');
    }
  }
  
  static Future<User> createUser({
    required String name,
    required String userCode,
    required String phone,
    required String direccion,
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
        'direccion': direccion,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('Error al crear usuario: ${response.statusCode}');
    }
  }
  
  static Future<List<User>> getUsers() async {
    final url = Uri.parse('$baseUrl/users?sort=id,asc');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
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
    String? loanType,
    String? paymentFrequency,
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
        'loanType': loanType,
        'paymentFrequency': paymentFrequency,
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
    String? loanType,
    String? paymentFrequency,
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
        'loanType': loanType,
        'paymentFrequency': paymentFrequency,
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
    final uri = Uri.parse('$baseUrl/loans/$loanId/installments').replace(
      queryParameters: {'paidInstallments': paidInstallments.toString()}
    );
    
    final response = await http.put(uri);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al actualizar cuotas pagadas: ${response.statusCode}');
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
      case 'mixto':
        return 'MIXED';
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
    
    final response = await http.get(uri);
    
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
  
  static Future<Map<String, dynamic>> updateLoan({
    required String loanId,
    required double interestRate,
    required int installments,
    required String loanType,
    required String paymentFrequency,
  }) async {
    final url = Uri.parse('$baseUrl/loans/$loanId');
    
    final currentLoan = await getLoanById(loanId);
    currentLoan['interestRate'] = interestRate;
    currentLoan['installments'] = installments;
    currentLoan['loanType'] = loanType;
    currentLoan['paymentFrequency'] = paymentFrequency;
    
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

  static Future<Map<String, dynamic>> updateLoanStatus({
    required String loanId,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/loans/$loanId');
    
    final currentLoan = await getLoanById(loanId);
    currentLoan['status'] = status.toUpperCase();
    
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
      throw Exception('Error al actualizar estado del préstamo: ${response.statusCode}');
    }
  }
  
  static Future<List<Loan>> getOverdueLoans() async {
    final url = Uri.parse('$baseUrl/loans/overdue');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Loan.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener préstamos vencidos: ${response.statusCode}');
    }
  }
  
  static Future<int> getOverdueLoansCount() async {
    final url = Uri.parse('$baseUrl/loans/overdue/count');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Error al contar préstamos vencidos: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> checkOverdueLoans() async {
    final url = Uri.parse('$baseUrl/loans/check-overdue');
    
    final response = await http.post(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al verificar préstamos vencidos: ${response.statusCode}');
    }
  }
  
  // Métodos para pagos
  static Future<List<dynamic>> getAllPayments() async {
    final url = Uri.parse('$baseUrl/payments');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener pagos: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> createPayment({
    required String userId,
    required double amount,
    required String paymentMethod,
    String? description,
    required double debtPayment,
    required double interestPayment,
    bool salida = false,
  }) async {
    final url = Uri.parse('$baseUrl/payments');
    
    final requestBody = {
      'user': {'id': int.parse(userId)},
      'amount': amount,
      'paymentMethod': paymentMethod,
      'description': description,
      'debtPayment': debtPayment,
      'interestPayment': interestPayment,
      'salida': salida,
    };
    
    print('Enviando al backend: ${jsonEncode(requestBody)}');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    print('Respuesta del backend: ${response.statusCode} - ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al crear pago: ${response.statusCode} - ${response.body}');
    }
  }
  
  static Future<List<dynamic>> getPaymentsByUserId(String userId) async {
    final url = Uri.parse('$baseUrl/payments/user/$userId');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener pagos del usuario: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> markPaymentAsRegistered(String paymentId) async {
    final url = Uri.parse('$baseUrl/payments/$paymentId');
    
    // Primero obtener el pago actual
    final getResponse = await http.get(url);
    if (getResponse.statusCode != 200) {
      throw Exception('Pago no encontrado: ${getResponse.statusCode}');
    }
    
    final paymentData = jsonDecode(getResponse.body);
    paymentData['registered'] = true;
    
    // Actualizar el pago
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(paymentData),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al marcar pago como registrado: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> updateTransactionField({
    required String transactionId,
    String? field,
    dynamic value,
  }) async {
    final url = Uri.parse('$baseUrl/transactions/$transactionId');
    
    // Primero obtener la transacción actual
    final getResponse = await http.get(url);
    if (getResponse.statusCode != 200) {
      throw Exception('Transacción no encontrada: ${getResponse.statusCode}');
    }
    
    final transactionData = jsonDecode(getResponse.body);
    
    // Actualizar solo el campo especificado
    if (field != null && value != null) {
      transactionData[field] = value;
      if (field == 'principalAmount') {
        transactionData['amount'] = value; // Sincronizar amount con principalAmount
      }
    }
    
    // Actualizar la transacción
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transactionData),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al actualizar campo: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateTransaction({
    required String transactionId,
    required double principalAmount,
    required double interestAmount,
    required String paymentMethod,
    required String notes,
  }) async {
    final url = Uri.parse('$baseUrl/transactions/$transactionId');
    
    // Primero obtener la transacción actual
    final getResponse = await http.get(url);
    if (getResponse.statusCode != 200) {
      throw Exception('Transacción no encontrada: ${getResponse.statusCode}');
    }
    
    final transactionData = jsonDecode(getResponse.body);
    transactionData['principalAmount'] = principalAmount;
    transactionData['interestAmount'] = interestAmount;
    transactionData['amount'] = principalAmount; // Monto total = solo capital
    transactionData['paymentMethod'] = paymentMethod;
    transactionData['notes'] = notes;
    
    // Actualizar la transacción
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transactionData),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al actualizar transacción: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateTransactionBreakdown({
    required String transactionId,
    required double principalAmount,
    required double interestAmount,
  }) async {
    final url = Uri.parse('$baseUrl/transactions/$transactionId');
    
    // Primero obtener la transacción actual
    final getResponse = await http.get(url);
    if (getResponse.statusCode != 200) {
      throw Exception('Transacción no encontrada: ${getResponse.statusCode}');
    }
    
    final transactionData = jsonDecode(getResponse.body);
    transactionData['principalAmount'] = principalAmount;
    transactionData['interestAmount'] = interestAmount;
    transactionData['amount'] = principalAmount; // Monto total = solo capital
    
    // Actualizar la transacción
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transactionData),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al actualizar desglose: ${response.statusCode}');
    }
  }
}