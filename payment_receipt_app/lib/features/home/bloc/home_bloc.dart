import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<LoadUserData>(_onLoadUserData);
    on<LoadUserTransactions>(_onLoadUserTransactions);
    on<RefreshData>(_onRefreshData);
    on<RefreshBalance>(_onRefreshBalance);
  }

  Future<void> _onLoadUserData(LoadUserData event, Emitter<HomeState> emit) async {
    try {
      emit(HomeLoading());
      
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        emit(HomeLoaded(
          user: user,
          transactions: [],
          balance: user['moneyclean']?.toDouble() ?? user['balance']?.toDouble() ?? 0.0,
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
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        // Obtener datos actualizados del usuario
        final updatedUser = await ApiService.getUserByEmail(user['email']);
        
        // Actualizar datos guardados
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(updatedUser));
        
        add(LoadUserData());
      }
    } catch (e) {
      add(LoadUserData());
    }
  }
  
  Future<void> _onRefreshBalance(RefreshBalance event, Emitter<HomeState> emit) async {
    add(RefreshData());
  }
}