part of 'permissions_bloc.dart';

/// States for the PermissionsBloc.
abstract class PermissionsState {
  const PermissionsState();
}

/// Initial state before permissions are loaded.
class PermissionsInitial extends PermissionsState {}

/// Permissions are being fetched from the API.
class PermissionsLoading extends PermissionsState {}

/// Permissions have been successfully loaded and cached.
class PermissionsLoaded extends PermissionsState {
  final UserPermissions permissions;

  const PermissionsLoaded({required this.permissions});
}

/// Permissions fetch failed — fail-closed: all actions disabled.
class PermissionsError extends PermissionsState {
  final String message;
  final UserPermissions permissions;

  PermissionsError({required this.message})
      : permissions = const UserPermissions(
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
}
