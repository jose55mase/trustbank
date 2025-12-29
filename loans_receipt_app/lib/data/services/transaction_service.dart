import '../../domain/models/transaction.dart';

class TransactionService {
  static final List<Transaction> _transactions = [];

  static List<Transaction> getAllTransactions() => List.from(_transactions);

  static List<Transaction> getTransactionsByLoan(String loanId) =>
      _transactions.where((t) => t.loanId == loanId).toList();

  static void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
  }

  static Transaction createPayment({
    required String loanId,
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
    String? loanType,
  }) {
    final transaction = Transaction(
      id: 'T${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.payment,
      userId: userId,
      loanId: loanId,
      amount: amount,
      date: DateTime.now(),
      paymentMethod: paymentMethod,
      notes: notes,
      loanType: loanType,
    );
    
    addTransaction(transaction);
    return transaction;
  }

  static Transaction createLoan({
    required String loanId,
    required String userId,
    required double amount,
    String? notes,
    String? loanType,
  }) {
    final transaction = Transaction(
      id: 'T${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.loan,
      userId: userId,
      loanId: loanId,
      amount: amount,
      date: DateTime.now(),
      paymentMethod: PaymentMethod.transfer,
      notes: notes,
      loanType: loanType,
    );
    
    addTransaction(transaction);
    return transaction;
  }

  static double getTotalPayments() {
    return _transactions
        .where((t) => t.type == TransactionType.payment)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  static Map<String, double> calculateAccountingSummary(List<Transaction> transactions) {
    double totalLoans = 0;
    double totalPayments = 0;
    double totalInterest = 0;
    double totalPrincipal = 0;

    for (var transaction in transactions) {
      if (transaction.type == TransactionType.loan) {
        totalLoans += transaction.amount;
      } else {
        totalPayments += transaction.amount;
        totalInterest += transaction.interestAmount ?? 0;
        totalPrincipal += transaction.principalAmount ?? 0;
      }
    }

    return {
      'totalLoans': totalLoans,
      'totalPayments': totalPayments,
      'totalInterest': totalInterest,
      'totalPrincipal': totalPrincipal,
      'netCashFlow': totalPayments - totalLoans,
    };
  }
}