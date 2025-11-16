enum UserRole {
  user('ROLE_USER'),
  admin('ROLE_ADMIN'),
  superAdmin('ROLE_SUPER_ADMIN'),
  moderator('ROLE_MODERATOR');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    final normalizedValue = value.toUpperCase();
    // Handle both formats: with and without ROLE_ prefix
    final roleValue = normalizedValue.startsWith('ROLE_') ? normalizedValue : 'ROLE_$normalizedValue';
    
    return UserRole.values.firstWhere(
      (role) => role.value == roleValue,
      orElse: () => UserRole.user,
    );
  }
  
  static UserRole fromBackendRoles(List<dynamic> roles) {
    if (roles.isEmpty) return UserRole.user;
    
    // Check for highest privilege role first
    for (final role in roles) {
      final roleName = role['name']?.toString() ?? '';
      if (roleName == 'ROLE_SUPER_ADMIN') return UserRole.superAdmin;
      if (roleName == 'ROLE_ADMIN') return UserRole.admin;
      if (roleName == 'ROLE_MODERATOR') return UserRole.moderator;
    }
    
    return UserRole.user;
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