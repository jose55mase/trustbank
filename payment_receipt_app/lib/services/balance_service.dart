import 'dart:async';

class BalanceService {
  static final BalanceService _instance = BalanceService._internal();
  factory BalanceService() => _instance;
  BalanceService._internal();

  final _balanceController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get balanceStream => _balanceController.stream;
  
  void updateBalance(int userId, double newBalance) {
    _balanceController.add({
      'userId': userId,
      'balance': newBalance,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  void dispose() {
    _balanceController.close();
  }
}