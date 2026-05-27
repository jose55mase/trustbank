import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/user_permissions.dart';
import '../../../../services/permissions_api_service.dart';

part 'permissions_event.dart';
part 'permissions_state.dart';

/// BLoC that manages the current user's granular permissions for the LEADS module.
///
/// Fetches permissions on initialization and caches them for the session.
/// Provides a [RefreshPermissions] event that can be dispatched on navigation
/// to the Leads screen to ensure permissions are up-to-date.
///
/// On fetch failure, defaults to a fail-closed state where all action buttons
/// are hidden (all permissions set to false).
class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  PermissionsBloc() : super(PermissionsInitial()) {
    on<LoadPermissions>(_onLoadPermissions);
    on<RefreshPermissions>(_onRefreshPermissions);
  }

  Future<void> _onLoadPermissions(
    LoadPermissions event,
    Emitter<PermissionsState> emit,
  ) async {
    emit(PermissionsLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefreshPermissions(
    RefreshPermissions event,
    Emitter<PermissionsState> emit,
  ) async {
    // On refresh, keep the current state visible while fetching.
    // Only emit loading if we don't have cached permissions yet.
    if (state is PermissionsInitial || state is PermissionsError) {
      emit(PermissionsLoading());
    }
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<PermissionsState> emit) async {
    try {
      final permissions =
          await PermissionsApiService.fetchUserPermissions('LEADS');
      emit(PermissionsLoaded(permissions: permissions));
    } catch (e) {
      // Fail-closed: on error, default to hiding all action buttons.
      emit(PermissionsError(
        message: 'Error al cargar permisos: ${_parseErrorMessage(e)}',
      ));
    }
  }

  /// Extracts a readable message from the exception.
  String _parseErrorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}
