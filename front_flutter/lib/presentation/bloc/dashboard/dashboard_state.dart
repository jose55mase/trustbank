part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;

  const DashboardLoaded(this.stats);

  @override
  List<Object> get props => [stats];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object> get props => [message];
}

class DashboardStats extends Equatable {
  final int totalUsers;
  final double revenue;
  final int bounceRate;
  final int totalSales;

  const DashboardStats({
    required this.totalUsers,
    required this.revenue,
    required this.bounceRate,
    required this.totalSales,
  });

  @override
  List<Object> get props => [totalUsers, revenue, bounceRate, totalSales];
}