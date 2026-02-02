import 'api_service.dart';
import 'auth_service.dart';

class PaymentService {
  /// Registra un pago con la fecha actual del frontend
  static Future<Map<String, dynamic>> registerPayment({
    required int userId,
    required double amount,
    required String paymentMethod,
    required double debtPayment,
    required double interestPayment,
    String? description,
    bool salida = false,
    double? valorRealCuota,
    bool pagoMenorACuota = false,
    DateTime? customDate, // Permite especificar una fecha personalizada
  }) async {
    try {
      final paymentData = {
        'user': {'id': userId},
        'amount': amount,
        'paymentMethod': paymentMethod,
        'description': description ?? 'Pago registrado',
        'debtPayment': debtPayment,
        'interestPayment': interestPayment,
        'paymentDate': (customDate ?? DateTime.now()).toIso8601String(),
        'registered': false,
        'salida': salida,
        'valorRealCuota': valorRealCuota,
        'pagoMenorACuota': pagoMenorACuota,
      };

      final response = await ApiService.createPayment(paymentData);
      
      return {
        'success': true,
        'message': 'Pago registrado exitosamente',
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Registra un pago de entrada (ingreso)
  static Future<Map<String, dynamic>> registerIncome({
    required int userId,
    required double amount,
    required String paymentMethod,
    String? description,
    DateTime? customDate,
  }) async {
    return registerPayment(
      userId: userId,
      amount: amount,
      paymentMethod: paymentMethod,
      debtPayment: 0.0,
      interestPayment: 0.0,
      description: description ?? 'Ingreso registrado',
      salida: false,
      customDate: customDate,
    );
  }

  /// Registra un pago de salida (egreso)
  static Future<Map<String, dynamic>> registerExpense({
    required int userId,
    required double amount,
    required String paymentMethod,
    String? description,
    DateTime? customDate,
  }) async {
    return registerPayment(
      userId: userId,
      amount: amount,
      paymentMethod: paymentMethod,
      debtPayment: amount,
      interestPayment: 0.0,
      description: description ?? 'Gasto registrado',
      salida: true,
      customDate: customDate,
    );
  }

  /// Obtiene todos los pagos del usuario actual
  static Future<List<dynamic>> getCurrentUserPayments() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no encontrado');
      }
      
      return await ApiService.getUserPayments(userId);
    } catch (e) {
      throw Exception('Error al obtener pagos: ${e.toString()}');
    }
  }

  /// Obtiene todos los pagos (solo para administradores)
  static Future<List<dynamic>> getAllPayments() async {
    try {
      return await ApiService.getAllPayments();
    } catch (e) {
      throw Exception('Error al obtener todos los pagos: ${e.toString()}');
    }
  }
}