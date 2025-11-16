import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/balance_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  late StreamSubscription _balanceSubscription;
  
  HomeBloc() : super(HomeInitial()) {
    on<LoadUserData>(_onLoadUserData);
    on<LoadUserTransactions>(_onLoadUserTransactions);
    on<RefreshData>(_onRefreshData);
    on<RefreshBalance>(_onRefreshBalance);
    on<UpdateBalanceFromStream>(_onUpdateBalanceFromStream);
    
    // Escuchar actualizaciones de saldo en tiempo real
    _balanceSubscription = BalanceService().balanceStream.listen((balanceUpdate) {
      add(UpdateBalanceFromStream(balanceUpdate));
    });
  }
  
  @override
  Future<void> close() {
    _balanceSubscription.cancel();
    return super.close();
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
        final userId = currentState.user['id'];
        
        // Cargar transacciones del backend
        List<dynamic> backendTransactions = [];
        try {
          backendTransactions = await ApiService.getUserTransactions(userId);
        } catch (e) {
          // Backend no disponible, usar transacciones de ejemplo
        }
        
        // Cargar transacciones locales
        final prefs = await SharedPreferences.getInstance();
        final transactionsKey = 'user_transactions_$userId';
        final localTransactionsString = prefs.getString(transactionsKey) ?? '[]';
        final localTransactions = List<dynamic>.from(json.decode(localTransactionsString));
        
        // Si no hay transacciones, agregar ejemplos
        List<dynamic> sampleTransactions = [];
        if (backendTransactions.isEmpty && localTransactions.isEmpty) {
          sampleTransactions = _getSampleTransactions();
        }
        
        // Combinar transacciones (locales primero, luego backend, luego ejemplos)
        final allTransactions = [...localTransactions, ...backendTransactions, ...sampleTransactions];
        
        // Ordenar por fecha descendente
        allTransactions.sort((a, b) {
          final dateA = DateTime.parse(a['date'] ?? DateTime.now().toIso8601String());
          final dateB = DateTime.parse(b['date'] ?? DateTime.now().toIso8601String());
          return dateB.compareTo(dateA);
        });
        
        emit(currentState.copyWith(transactions: allTransactions));
      }
    } catch (e) {
      // Mantener estado actual si falla cargar transacciones
    }
  }
  
  List<dynamic> _getSampleTransactions() {
    final now = DateTime.now();
    return [
      {
        'id': 'sample_1',
        'type': 'INCOME',
        'amount': 500.0,
        'description': 'Recarga aprobada',
        'fromUser': 'TrustBank Admin',
        'toUser': 'Mi Cuenta',
        'date': now.subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'sample_2', 
        'type': 'EXPENSE',
        'amount': 150.0,
        'description': 'Envío de dinero',
        'fromUser': 'Mi Cuenta',
        'toUser': 'Juan Pérez',
        'date': now.subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'id': 'sample_3',
        'type': 'INCOME', 
        'amount': 1000.0,
        'description': 'Depósito inicial',
        'fromUser': 'TrustBank',
        'toUser': 'Mi Cuenta',
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'sample_4',
        'type': 'EXPENSE',
        'amount': 75.0,
        'description': 'Pago de servicios',
        'fromUser': 'Mi Cuenta',
        'toUser': 'Servicios Públicos',
        'date': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'sample_5',
        'type': 'INCOME',
        'amount': 250.0,
        'description': 'Transferencia recibida',
        'fromUser': 'María González',
        'toUser': 'Mi Cuenta',
        'date': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
    ];
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
  
  Future<void> _onUpdateBalanceFromStream(UpdateBalanceFromStream event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final userId = currentState.user['id'];
      if (userId == event.balanceUpdate['userId']) {
        final newBalance = event.balanceUpdate['balance'];
        emit(currentState.copyWith(balance: newBalance));
        print('Balance updated in real-time: $newBalance');
      }
    }
  }
}