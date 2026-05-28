import 'package:flutter_test/flutter_test.dart';
import 'package:trustbank/models/user_permissions.dart';

void main() {
  group('UserPermissions', () {
    group('fromJson', () {
      test('parses full API response correctly', () {
        final json = {
          'moduleCode': 'LEADS',
          'actions': {
            'ASSIGN_ADVISOR': true,
            'UNASSIGN_ADVISOR': true,
            'IMPORT_EXCEL': false,
            'EXPORT_EXCEL': true,
            'EDIT_LEADS': false,
            'DELETE_LEADS': false,
          },
          'visibleCampaignIds': [1, 3, 5],
        };

        final permissions = UserPermissions.fromJson(json);

        expect(permissions.actionPermissions['ASSIGN_ADVISOR'], true);
        expect(permissions.actionPermissions['UNASSIGN_ADVISOR'], true);
        expect(permissions.actionPermissions['IMPORT_EXCEL'], false);
        expect(permissions.actionPermissions['EXPORT_EXCEL'], true);
        expect(permissions.actionPermissions['EDIT_LEADS'], false);
        expect(permissions.actionPermissions['DELETE_LEADS'], false);
        expect(permissions.visibleCampaignIds, [1, 3, 5]);
      });

      test('handles missing actions field gracefully', () {
        final json = <String, dynamic>{
          'moduleCode': 'LEADS',
          'visibleCampaignIds': [1],
        };

        final permissions = UserPermissions.fromJson(json);

        expect(permissions.actionPermissions, isEmpty);
        expect(permissions.visibleCampaignIds, [1]);
      });

      test('handles missing visibleCampaignIds field gracefully', () {
        final json = <String, dynamic>{
          'moduleCode': 'LEADS',
          'actions': {'ASSIGN_ADVISOR': true},
        };

        final permissions = UserPermissions.fromJson(json);

        expect(permissions.actionPermissions['ASSIGN_ADVISOR'], true);
        expect(permissions.visibleCampaignIds, isEmpty);
      });

      test('handles empty JSON gracefully', () {
        final json = <String, dynamic>{};

        final permissions = UserPermissions.fromJson(json);

        expect(permissions.actionPermissions, isEmpty);
        expect(permissions.visibleCampaignIds, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes correctly', () {
        const permissions = UserPermissions(
          actionPermissions: {
            'ASSIGN_ADVISOR': true,
            'IMPORT_EXCEL': false,
          },
          visibleCampaignIds: [1, 3],
        );

        final json = permissions.toJson();

        expect(json['actions'], {'ASSIGN_ADVISOR': true, 'IMPORT_EXCEL': false});
        expect(json['visibleCampaignIds'], [1, 3]);
      });
    });

    group('convenience methods', () {
      test('canAssign returns correct value when permission exists', () {
        const permissions = UserPermissions(
          actionPermissions: {'ASSIGN_ADVISOR': false},
          visibleCampaignIds: [],
        );

        expect(permissions.canAssign(), false);
      });

      test('canAssign defaults to true when permission is missing', () {
        const permissions = UserPermissions(
          actionPermissions: {},
          visibleCampaignIds: [],
        );

        expect(permissions.canAssign(), true);
      });

      test('canUnassign returns correct value', () {
        const permissions = UserPermissions(
          actionPermissions: {'UNASSIGN_ADVISOR': false},
          visibleCampaignIds: [],
        );

        expect(permissions.canUnassign(), false);
      });

      test('canUnassign defaults to true when missing', () {
        const permissions = UserPermissions(
          actionPermissions: {},
          visibleCampaignIds: [],
        );

        expect(permissions.canUnassign(), true);
      });

      test('canImport returns correct value', () {
        const permissions = UserPermissions(
          actionPermissions: {'IMPORT_EXCEL': false},
          visibleCampaignIds: [],
        );

        expect(permissions.canImport(), false);
      });

      test('canExport returns correct value', () {
        const permissions = UserPermissions(
          actionPermissions: {'EXPORT_EXCEL': false},
          visibleCampaignIds: [],
        );

        expect(permissions.canExport(), false);
      });

      test('canEdit returns correct value', () {
        const permissions = UserPermissions(
          actionPermissions: {'EDIT_LEADS': false},
          visibleCampaignIds: [],
        );

        expect(permissions.canEdit(), false);
      });

      test('canDelete returns correct value', () {
        const permissions = UserPermissions(
          actionPermissions: {'DELETE_LEADS': false},
          visibleCampaignIds: [],
        );

        expect(permissions.canDelete(), false);
      });

      test('hasUnrestrictedVisibility returns true when no campaigns', () {
        const permissions = UserPermissions(
          actionPermissions: {},
          visibleCampaignIds: [],
        );

        expect(permissions.hasUnrestrictedVisibility(), true);
      });

      test('hasUnrestrictedVisibility returns false when campaigns exist', () {
        const permissions = UserPermissions(
          actionPermissions: {},
          visibleCampaignIds: [1, 2, 3],
        );

        expect(permissions.hasUnrestrictedVisibility(), false);
      });
    });

    group('equality', () {
      test('two instances with same data are equal', () {
        const a = UserPermissions(
          actionPermissions: {'ASSIGN_ADVISOR': true},
          visibleCampaignIds: [1, 2],
        );
        const b = UserPermissions(
          actionPermissions: {'ASSIGN_ADVISOR': true},
          visibleCampaignIds: [1, 2],
        );

        expect(a, equals(b));
      });

      test('two instances with different data are not equal', () {
        const a = UserPermissions(
          actionPermissions: {'ASSIGN_ADVISOR': true},
          visibleCampaignIds: [1],
        );
        const b = UserPermissions(
          actionPermissions: {'ASSIGN_ADVISOR': false},
          visibleCampaignIds: [1],
        );

        expect(a, isNot(equals(b)));
      });
    });
  });
}
