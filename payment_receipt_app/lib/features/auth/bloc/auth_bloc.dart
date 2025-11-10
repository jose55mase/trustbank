import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      if (event.email.isNotEmpty && event.password.length >= 6) {
        emit(AuthAuthenticated(
          user: User(
            id: '1',
            email: event.email,
            name: 'Usuario TrustBank',
          ),
        ));
      } else {
        emit(const AuthError('Credenciales inválidas'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthInitial());
  }
}