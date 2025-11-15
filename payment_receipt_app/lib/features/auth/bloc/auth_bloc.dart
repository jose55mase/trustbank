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
        // Simular consulta de usuario con estado
        final accountStatus = _getUserAccountStatus(event.email);
        
        if (accountStatus == 'suspended') {
          emit(const AccountSuspended(
            'Tu cuenta ha sido suspendida. Contacta al administrador para más información.',
          ));
          return;
        }
        
        if (accountStatus == 'inactive') {
          emit(const AuthError('Tu cuenta está inactiva. Contacta al administrador.'));
          return;
        }
        
        // Determinar rol según email (en producción vendría de la base de datos)
        final userRole = _getUserRole(event.email);
        
        emit(AuthAuthenticated(
          user: User(
            id: '1',
            email: event.email,
            name: 'Usuario TrustBank',
            accountStatus: accountStatus,
            role: userRole,
          ),
        ));
      } else {
        emit(const AuthError('Credenciales inválidas'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  String _getUserAccountStatus(String email) {
    // Simular diferentes estados según el email
    if (email.contains('suspended')) return 'suspended';
    if (email.contains('inactive')) return 'inactive';
    return 'active';
  }
  
  String _getUserRole(String email) {
    // Simular roles según email (en producción vendría de la base de datos)
    if (email.contains('superadmin')) return 'SUPER_ADMIN';
    if (email.contains('admin')) return 'ADMIN';
    if (email.contains('moderator')) return 'MODERATOR';
    return 'USER';
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthInitial());
  }
}