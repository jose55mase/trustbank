enum UserRole {
  user('USER'),
  admin('ADMIN'),
  superAdmin('SUPER_ADMIN'),
  moderator('MODERATOR');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value.toUpperCase(),
      orElse: () => UserRole.user,
    );
  }
}

enum Permission {
  // Permisos de usuario básico
  viewBalance('VIEW_BALANCE'),
  sendMoney('SEND_MONEY'),
  receivePayments('RECEIVE_PAYMENTS'),
  
  // Permisos administrativos
  viewAdminPanel('VIEW_ADMIN_PANEL'),
  manageUsers('MANAGE_USERS'),
  approveTransactions('APPROVE_TRANSACTIONS'),
  viewReports('VIEW_REPORTS'),
  manageRoles('MANAGE_ROLES'),
  
  // Permisos de super admin
  systemSettings('SYSTEM_SETTINGS'),
  deleteUsers('DELETE_USERS'),
  viewAuditLogs('VIEW_AUDIT_LOGS');

  const Permission(this.value);
  final String value;
}

class RolePermissions {
  static const Map<UserRole, List<Permission>> _rolePermissions = {
    UserRole.user: [
      Permission.viewBalance,
      Permission.sendMoney,
      Permission.receivePayments,
    ],
    UserRole.moderator: [
      Permission.viewBalance,
      Permission.sendMoney,
      Permission.receivePayments,
      Permission.viewAdminPanel,
      Permission.viewReports,
    ],
    UserRole.admin: [
      Permission.viewBalance,
      Permission.sendMoney,
      Permission.receivePayments,
      Permission.viewAdminPanel,
      Permission.manageUsers,
      Permission.approveTransactions,
      Permission.viewReports,
    ],
    UserRole.superAdmin: [
      Permission.viewBalance,
      Permission.sendMoney,
      Permission.receivePayments,
      Permission.viewAdminPanel,
      Permission.manageUsers,
      Permission.approveTransactions,
      Permission.viewReports,
      Permission.manageRoles,
      Permission.systemSettings,
      Permission.deleteUsers,
      Permission.viewAuditLogs,
    ],
  };

  static List<Permission> getPermissions(UserRole role) {
    return _rolePermissions[role] ?? [];
  }

  static bool hasPermission(UserRole role, Permission permission) {
    return getPermissions(role).contains(permission);
  }
}