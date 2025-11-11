abstract class HomeEvent {}

class LoadUserData extends HomeEvent {}

class LoadUserTransactions extends HomeEvent {}

class RefreshData extends HomeEvent {}

class RefreshBalance extends HomeEvent {}

class UpdateBalanceFromStream extends HomeEvent {
  final Map<String, dynamic> balanceUpdate;
  UpdateBalanceFromStream(this.balanceUpdate);
}