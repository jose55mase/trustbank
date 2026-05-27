import 'package:equatable/equatable.dart';

/// Model representing the current user's granular permissions for a module.
/// Contains action-level permissions and campaign-based visibility restrictions.
class UserPermissions extends Equatable {
  final Map<String, bool> actionPermissions; // actionCode -> enabled
  final List<int> visibleCampaignIds; // empty = unrestricted

  const UserPermissions({
    required this.actionPermissions,
    required this.visibleCampaignIds,
  });

  /// Creates a [UserPermissions] instance from the API response JSON.
  ///
  /// Expected format:
  /// ```json
  /// {
  ///   "moduleCode": "LEADS",
  ///   "actions": {
  ///     "ASSIGN_ADVISOR": true,
  ///     "UNASSIGN_ADVISOR": true,
  ///     "IMPORT_EXCEL": false,
  ///     "EXPORT_EXCEL": true,
  ///     "EDIT_LEADS": false,
  ///     "DELETE_LEADS": false
  ///   },
  ///   "visibleCampaignIds": [1, 3, 5]
  /// }
  /// ```
  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    final actionsMap = (json['actions'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as bool),
        ) ??
        {};

    final campaignIds = (json['visibleCampaignIds'] as List<dynamic>?)
            ?.map((id) => id as int)
            .toList() ??
        [];

    return UserPermissions(
      actionPermissions: actionsMap,
      visibleCampaignIds: campaignIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actions': actionPermissions,
      'visibleCampaignIds': visibleCampaignIds,
    };
  }

  /// Whether the user can assign an advisor to leads.
  bool canAssign() => actionPermissions['ASSIGN_ADVISOR'] ?? true;

  /// Whether the user can unassign an advisor from leads.
  bool canUnassign() => actionPermissions['UNASSIGN_ADVISOR'] ?? true;

  /// Whether the user can import leads from Excel.
  bool canImport() => actionPermissions['IMPORT_EXCEL'] ?? true;

  /// Whether the user can export leads to Excel.
  bool canExport() => actionPermissions['EXPORT_EXCEL'] ?? true;

  /// Whether the user can edit lead details.
  bool canEdit() => actionPermissions['EDIT_LEADS'] ?? true;

  /// Whether the user can delete leads.
  bool canDelete() => actionPermissions['DELETE_LEADS'] ?? true;

  /// Whether the user has unrestricted campaign visibility (can see all leads).
  /// Returns true when no specific campaigns are assigned.
  bool hasUnrestrictedVisibility() => visibleCampaignIds.isEmpty;

  @override
  List<Object> get props => [actionPermissions, visibleCampaignIds];
}
