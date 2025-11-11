abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final Map<String, dynamic> user;
  final List<dynamic> transactions;
  final double balance;

  HomeLoaded({
    required this.user,
    required this.transactions,
    required this.balance,
  });

  HomeLoaded copyWith({
    Map<String, dynamic>? user,
    List<dynamic>? transactions,
    double? balance,
  }) {
    return HomeLoaded(
      user: user ?? this.user,
      transactions: transactions ?? this.transactions,
      balance: balance ?? this.balance,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}