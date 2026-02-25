import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/user.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/expense_category.dart';
import '../../domain/models/expense_model.dart';
import '../../services/auth_service.dart';

class ApiService {
  //static const String baseUrl = 'http://localhost:8082/api';
  static const String baseUrl = 'https://guardianstrustbank.com:8084/api';

  static Future<Map<String, String>> getLoanNotesByUserId(String userId) async {
    final url = Uri.parse('$baseUrl/loans/user/$userId/notes');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data.map((key, value) => MapEntry(key, value.toString()));
    } else {
      return {};
    }
  }
  
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
    String? referenceName,
    String? referencePhone,
    DateTime? registrationDate,
  }) async {
    final url = Uri.parse('$baseUrl/users');
    
    final requestBody = {
      'name': name,
      'userCode': userCode,
      'phone': phone,
      'direccion': direccion,
    };
    
    if (referenceName != null && referenceName.isNotEmpty) {
      requestBody['referenceName'] = referenceName;
    }
    
    if (referencePhone != null && referencePhone.isNotEmpty) {
      requestBody['referencePhone'] = referencePhone;
    }
    
    if (registrationDate != null) {
      requestBody['registrationDate'] = registrationDate.toIso8601String();
    }
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      // Extraer el mensaje de error del JSON
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al crear usuario';
        throw Exception(errorMessage);
      } catch (e) {
        // Si falla el parseo del JSON, lanzar error genérico
        if (e.toString().startsWith('Exception: ')) {
          rethrow;
        }
        throw Exception('Error al crear usuario: ${response.statusCode}');
      }
    }
  }
  
  static Future<List<User>> getUsers() async {
    final url = Uri.parse('$baseUrl/users');
    
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
  
  static Future<User> updateUser({
    required String userId,
    required String userCode,
    required String name,
    required String phone,
    required String direccion,
    String? referenceName,
    String? referencePhone,
    String? originalUserCode,
  }) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    
    final requestBody = {
      'userCode': userCode,
      'name': name,
      'phone': phone,
      'direccion': direccion,
    };
    
    if (referenceName != null && referenceName.isNotEmpty) {
      requestBody['referenceName'] = referenceName;
    }
    
    if (referencePhone != null && referencePhone.isNotEmpty) {
      requestBody['referencePhone'] = referencePhone;
    }
    
    if (originalUserCode != null) {
      requestBody['originalUserCode'] = originalUserCode;
    }
    
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al actualizar usuario';
        throw Exception(errorMessage);
      } catch (e) {
        if (e.toString().startsWith('Exception: ')) {
          rethrow;
        }
        throw Exception('Error al actualizar usuario: ${response.statusCode}');
      }
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
  
  static Future<List<Loan>> getLoansByUserIdAsModels(String userId) async {
    final url = Uri.parse('$baseUrl/loans/user/$userId');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Loan.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener préstamos del usuario: ${response.statusCode}');
    }
  }
  
  static Future<dynamic> createLoan({
    required String userId,
    required double amount,
    required double interestRate,
    required int installments,
    String? loanType,
    String? paymentFrequency,
    DateTime? startDate,
    double? valorRealCuota,
    double? capital,
    bool sinCuotas = false,
  }) async {
    final url = Uri.parse('$baseUrl/loans');
    
    final requestBody = {
      'user': {'id': int.parse(userId)},
      'amount': amount,
      'interestRate': interestRate,
      'installments': installments,
      'loanType': loanType,
      'paymentFrequency': paymentFrequency,
      'sinCuotas': sinCuotas,
    };
    
    if (startDate != null) {
      requestBody['startDate'] = startDate.toIso8601String();
    }
    
    if (valorRealCuota != null) {
      requestBody['valorRealCuota'] = valorRealCuota;
    }
    
    if (capital != null) {
      requestBody['capital'] = capital;
    }
    
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al crear préstamo: ${response.statusCode}');
    }
  }
  
  static Future<void> deleteLoan(String loanId) async {
    final url = Uri.parse('$baseUrl/loans/$loanId');
    
    final response = await http.delete(url);
    
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar préstamo: ${response.statusCode}');
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
  
  static Future<double> getTotalRemainingAmount() async {
    final url = Uri.parse('$baseUrl/loans/total-remaining');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return double.parse(response.body);
    } else {
      throw Exception('Error al obtener total de saldos pendientes: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> recalculateAllBalances() async {
    final url = Uri.parse('$baseUrl/loans/recalculate-balances');
    
    final response = await http.post(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al recalcular saldos: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> debugAllTransactions() async {
    final url = Uri.parse('$baseUrl/transactions/debug/all');
    
    
    final response = await http.get(url);
    
    
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result;
    } else {
      throw Exception('Error al obtener debug de transacciones: ${response.statusCode}');
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
  
  static Future<List<Loan>> getActiveAndOverdueLoans() async {
    final url = Uri.parse('$baseUrl/loans/active-and-overdue');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Loan.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener préstamos activos y vencidos: ${response.statusCode}');
    }
  }
  
  static Future<List<Loan>> getActiveAndOverdueLoansByUserId(String userId) async {
    final url = Uri.parse('$baseUrl/loans/user/$userId/active-and-overdue');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Loan.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener préstamos del usuario: ${response.statusCode}');
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
    String? montoRestanteCompletarCuota,
  }) async {
    final url = Uri.parse('$baseUrl/transactions');
    final requestBody = {
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
      'date': DateTime.now().toIso8601String(), // Enviar fecha actual desde Flutter
    };
    
    if (montoRestanteCompletarCuota != null) {
      requestBody['montoRestanteCompletarCuota'] = montoRestanteCompletarCuota;
    }
    
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final result = jsonDecode(response.body);
      return result;
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
      final List<dynamic> transactions = jsonDecode(response.body);
      
      for (int i = 0; i < transactions.length && i < 5; i++) {
        final t = transactions[i];
      }
      
      return transactions;
    } else {
      throw Exception('Error al obtener transacciones: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>?> getLastCapitalPayment(String loanId) async {
    final url = Uri.parse('$baseUrl/transactions/loan/$loanId');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> transactions = jsonDecode(response.body);
      
      // Filtrar transacciones que tengan principalAmount > 0 y ordenar por fecha descendente
      final capitalTransactions = transactions
          .where((t) => t['principalAmount'] != null && (t['principalAmount'] as num) > 0)
          .toList();
      
      if (capitalTransactions.isNotEmpty) {
        // Ordenar por fecha descendente y tomar la más reciente
        capitalTransactions.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
        return capitalTransactions.first;
      }
    }
    
    return null;
  }
  static Future<List<dynamic>> getTransactionsByLoanId(String loanId) async {
    final url = Uri.parse('$baseUrl/transactions/loan/$loanId');
    
    
    final response = await http.get(url);
    
    
    if (response.statusCode == 200) {
      final List<dynamic> transactions = jsonDecode(response.body);
      
      double totalPrincipal = 0.0;
      for (var t in transactions) {
        if (t['principalAmount'] != null) {
          totalPrincipal += (t['principalAmount'] as num).toDouble();
        }
      }
      
      return transactions;
    } else {
      throw Exception('Error al obtener transacciones del préstamo: ${response.statusCode}');
    }
  }
  
  static Future<void> deleteTransaction(String transactionId) async {
    final url = Uri.parse('$baseUrl/transactions/$transactionId');
    
    final response = await http.delete(url);
    
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar transacción: ${response.statusCode}');
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
  
  static Future<ExpenseCategory> updateExpenseCategory({
    required int categoryId,
    required String name,
    required String iconName,
    required String colorValue,
  }) async {
    final url = Uri.parse('$baseUrl/expense-categories/$categoryId');
    
    final response = await http.put(
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
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ExpenseCategory.fromJson(data);
    } else {
      throw Exception('Error al actualizar categoría: ${response.statusCode}');
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
    
    // Si la descripción está vacía o es null, usar "Sin descripción"
    final finalDescription = description.trim().isEmpty ? 'Sin descripción' : description.trim();
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'category': {'id': categoryId},
        'amount': amount,
        'description': finalDescription,
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
  
  static Future<ExpenseModel> updateExpense({
    required int expenseId,
    required int categoryId,
    required double amount,
    required String description,
    required DateTime expenseDate,
  }) async {
    final url = Uri.parse('$baseUrl/expenses/$expenseId');
    
    // Si la descripción está vacía o es null, usar "Sin descripción"
    final finalDescription = description.trim().isEmpty ? 'Sin descripción' : description.trim();
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'category': {'id': categoryId},
        'amount': amount,
        'description': finalDescription,
        'expenseDate': expenseDate.toIso8601String(),
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ExpenseModel.fromJson(data);
    } else {
      throw Exception('Error al actualizar gasto: ${response.statusCode}');
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
    required double amount,
    required double interestRate,
    required int installments,
    required String loanType,
    required String paymentFrequency,
    double? valorRealCuota,
    bool? sinCuotas,
    DateTime? startDate,
  }) async {
    final url = Uri.parse('$baseUrl/loans/$loanId');
    
    final currentLoan = await getLoanById(loanId);
    currentLoan['amount'] = amount;
    currentLoan['interestRate'] = interestRate;
    currentLoan['installments'] = installments;
    currentLoan['loanType'] = loanType;
    currentLoan['paymentFrequency'] = paymentFrequency;
    
    if (valorRealCuota != null) {
      currentLoan['valorRealCuota'] = valorRealCuota;
    }
    
    if (sinCuotas != null) {
      currentLoan['sinCuotas'] = sinCuotas;
    }
    
    if (startDate != null) {
      currentLoan['startDate'] = startDate.toIso8601String();
    }
    
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
    double? valorRealCuota,
    bool salida = false,
    bool pagoMenorACuota = false,
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
      'pagoMenorACuota': pagoMenorACuota,
    };
    
    if (valorRealCuota != null) {
      requestBody['valorRealCuota'] = valorRealCuota;
    }
    
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    
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
  
  static Future<void> deletePayment(String paymentId) async {
    final url = Uri.parse('$baseUrl/payments/$paymentId');
    
    final response = await http.delete(url);
    
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar pago: ${response.statusCode}');
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

  // Métodos para permisos
  static Future<List<dynamic>> getAuthUsers() async {
    final url = Uri.parse('$baseUrl/auth/users');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener usuarios: ${response.statusCode}');
    }
  }
  
  static Future<List<dynamic>> getAllPermissions() async {
    final url = Uri.parse('$baseUrl/permissions');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener permisos: ${response.statusCode}');
    }
  }
  
  static Future<List<dynamic>> getUserPermissions(int userId) async {
    final url = Uri.parse('$baseUrl/permissions/user/$userId');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener permisos del usuario: ${response.statusCode}');
    }
  }
  
  static Future<void> updateUserPermissions(int userId, List<Map<String, dynamic>> permissions) async {
    final url = Uri.parse('$baseUrl/permissions/user/$userId');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(permissions),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar permisos: ${response.statusCode}');
    }
  }
  
  static Future<void> initializePermissions() async {
    final url = Uri.parse('$baseUrl/permissions/init');
    
    final response = await http.post(url);
    
    if (response.statusCode != 200) {
      throw Exception('Error al inicializar permisos: ${response.statusCode}');
    }
  }
  
  static Future<void> deleteAuthUser(int userId) async {
    final url = Uri.parse('$baseUrl/auth/users/$userId');
    
    final response = await http.delete(url);
    
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar usuario: ${response.statusCode}');
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