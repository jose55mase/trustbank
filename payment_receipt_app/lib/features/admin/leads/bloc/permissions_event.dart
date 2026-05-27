part of 'permissions_bloc.dart';

/// Events for the PermissionsBloc.
abstract class PermissionsEvent {}

/// Triggered on initialization to fetch permissions from the API.
class LoadPermissions extends PermissionsEvent {}

/// Triggered on navigation to the Leads screen to refresh cached permissions.
class RefreshPermissions extends PermissionsEvent {}
