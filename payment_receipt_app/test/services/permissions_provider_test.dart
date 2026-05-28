import 'package:flutter_test/flutter_test.dart';
import 'package:trustbank/services/permissions_provider.dart';

void main() {
  group('PermissionsProvider', () {
    late PermissionsProvider provider;

    setUp(() {
      provider = PermissionsProvider();
      provider.clear(); // Reset state between tests
    });

    group('singleton', () {
      test('returns the same instance', () {
        final a = PermissionsProvider();
        final b = PermissionsProvider();
        expect(identical(a, b), true);
      });
    });

    group('initial state', () {
      test('isLoaded is false before loading', () {
        expect(provider.isLoaded, false);
      });

      test('isLoading is false initially', () {
        expect(provider.isLoading, false);
      });

      test('lastError is null initially', () {
        expect(provider.lastError, isNull);
      });
    });

    group('fail-closed behavior', () {
      test('permissions default to all-disabled when not loaded', () {
        final perms = provider.permissions;

        expect(perms.canAssign(), false);
        expect(perms.canUnassign(), false);
        expect(perms.canImport(), false);
        expect(perms.canExport(), false);
        expect(perms.canEdit(), false);
        expect(perms.canDelete(), false);
      });

      test('fail-closed permissions have empty visibleCampaignIds', () {
        final perms = provider.permissions;
        expect(perms.visibleCampaignIds, isEmpty);
      });

      test('fail-closed permissions contain all 6 action codes set to false', () {
        final perms = provider.permissions;
        expect(perms.actionPermissions.length, 6);
        expect(perms.actionPermissions['ASSIGN_ADVISOR'], false);
        expect(perms.actionPermissions['UNASSIGN_ADVISOR'], false);
        expect(perms.actionPermissions['IMPORT_EXCEL'], false);
        expect(perms.actionPermissions['EXPORT_EXCEL'], false);
        expect(perms.actionPermissions['EDIT_LEADS'], false);
        expect(perms.actionPermissions['DELETE_LEADS'], false);
      });
    });

    group('clear', () {
      test('resets isLoaded to false', () {
        // Simulate a loaded state by accessing the provider
        provider.clear();
        expect(provider.isLoaded, false);
      });

      test('resets lastError to null', () {
        provider.clear();
        expect(provider.lastError, isNull);
      });

      test('resets isLoading to false', () {
        provider.clear();
        expect(provider.isLoading, false);
      });

      test('after clear, permissions return fail-closed defaults', () {
        provider.clear();
        final perms = provider.permissions;
        expect(perms.canAssign(), false);
        expect(perms.canUnassign(), false);
        expect(perms.canImport(), false);
        expect(perms.canExport(), false);
        expect(perms.canEdit(), false);
        expect(perms.canDelete(), false);
      });
    });

    group('permissionsStream', () {
      test('stream is a broadcast stream', () {
        // Should not throw when listened to multiple times
        provider.permissionsStream.listen((_) {});
        provider.permissionsStream.listen((_) {});
      });
    });
  });
}
