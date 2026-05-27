import 'dart:async';

import '../models/user_permissions.dart';
import 'permissions_api_service.dart';

/// Singleton provider that fetches and caches the current user's granular
/// permissions for the LEADS module during the session.
///
/// Usage:
/// ```dart
/// final provider = PermissionsProvider();
/// await provider.loadPermissions(); // on login / navigation to Leads
/// final perms = provider.permissions;
/// if (perms.canAssign()) { /* show button */ }
/// ```
///
/// Fail-closed behavior: if the fetch fails, all action buttons are hidden
/// (permissions default to all-disabled).
class PermissionsProvider {
  static final PermissionsProvider _instance = PermissionsProvider._();
  factory PermissionsProvider() => _instance;
  PermissionsProvider._();

  /// The default module code for leads permissions.
  static const String _moduleCode = 'LEADS';

  /// Cached permissions for the current session.
  UserPermissions? _permissions;

  /// Whether a fetch is currently in progress (prevents duplicate calls).
  bool _isLoading = false;

  /// The last error encountered during fetch, if any.
  String? _lastError;

  /// Stream controller to notify listeners when permissions change.
  final _permissionsController = StreamController<UserPermissions>.broadcast();

  /// Stream of permission updates. Widgets can listen to this for reactive updates.
  Stream<UserPermissions> get permissionsStream => _permissionsController.stream;

  /// Returns the cached [UserPermissions], or a fail-closed default if not loaded.
  ///
  /// Fail-closed: when permissions haven't been loaded or fetch failed,
  /// all actions are disabled (hidden) and no campaigns are visible.
  UserPermissions get permissions => _permissions ?? _failClosedPermissions;

  /// Whether permissions have been successfully loaded at least once.
  bool get isLoaded => _permissions != null;

  /// Whether a fetch is currently in progress.
  bool get isLoading => _isLoading;

  /// The last error message, or null if the last fetch succeeded.
  String? get lastError => _lastError;

  /// Fail-closed permissions: all actions disabled, no campaign visibility.
  static const UserPermissions _failClosedPermissions = UserPermissions(
    actionPermissions: {
      'ASSIGN_ADVISOR': false,
      'UNASSIGN_ADVISOR': false,
      'IMPORT_EXCEL': false,
      'EXPORT_EXCEL': false,
      'EDIT_LEADS': false,
      'DELETE_LEADS': false,
    },
    visibleCampaignIds: [],
  );

  /// Fetches the current user's permissions from the API and caches them.
  ///
  /// Call this:
  /// - On app startup (after login)
  /// - On navigation to the Leads screen (refresh)
  ///
  /// On failure, the cached permissions are set to fail-closed (all disabled).
  /// A non-blocking error is stored in [lastError] for display as a toast.
  Future<void> loadPermissions() async {
    if (_isLoading) return;
    _isLoading = true;
    _lastError = null;

    try {
      final userPermissions =
          await PermissionsApiService.fetchUserPermissions(_moduleCode);
      _permissions = userPermissions;
      _permissionsController.add(userPermissions);
    } catch (e) {
      // Fail-closed: default to hiding all action buttons
      _permissions = _failClosedPermissions;
      _lastError = e.toString();
      _permissionsController.add(_failClosedPermissions);
    } finally {
      _isLoading = false;
    }
  }

  /// Refreshes permissions. Alias for [loadPermissions] for semantic clarity
  /// when called on navigation to the Leads screen.
  Future<void> refresh() => loadPermissions();

  /// Clears cached permissions. Call on logout.
  void clear() {
    _permissions = null;
    _lastError = null;
    _isLoading = false;
  }

  /// Disposes the stream controller. Call only if the app is being torn down.
  void dispose() {
    _permissionsController.close();
  }
}
