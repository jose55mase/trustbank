import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<LoadUserData>(_onLoadUserData);
    on<LoadUserTransactions>(_onLoadUserTransactions);
    on<RefreshData>(_onRefreshData);
  }

  Future<void> _onLoadUserData(LoadUserData event, Emitter<HomeState> emit) async {
    try {
      emit(HomeLoading());
      
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        emit(HomeLoaded(
          user: user,
          transactions: [],
          balance: user['balance']?.toDouble() ?? 0.0,
        ));
        
        // Cargar transacciones automáticamente
        add(LoadUserTransactions());
      } else {
        emit(HomeError('Usuario no encontrado'));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onLoadUserTransactions(LoadUserTransactions event, Emitter<HomeState> emit) async {
    try {
      final currentState = state;
      if (currentState is HomeLoaded) {
        final transactions = await ApiService.getUserTransactions(currentState.user['id']);
        emit(currentState.copyWith(transactions: transactions));
      }
    } catch (e) {
      // Mantener estado actual si falla cargar transacciones
    }
  }

  Future<void> _onRefreshData(RefreshData event, Emitter<HomeState> emit) async {
    add(LoadUserData());
  }
}