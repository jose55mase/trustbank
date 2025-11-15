import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

class RoleGuard extends StatefulWidget {
  final Permission requiredPermission;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.requiredPermission,
    required this.child,
    this.fallback,
  });

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await AuthService.hasPermission(widget.requiredPermission);
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_hasPermission) {
      return widget.child;
    }

    return widget.fallback ?? const SizedBox.shrink();
  }
}

class MultiRoleGuard extends StatefulWidget {
  final List<Permission> requiredPermissions;
  final Widget child;
  final Widget? fallback;
  final bool requireAll; // true = AND, false = OR

  const MultiRoleGuard({
    super.key,
    required this.requiredPermissions,
    required this.child,
    this.fallback,
    this.requireAll = false,
  });

  @override
  State<MultiRoleGuard> createState() => _MultiRoleGuardState();
}

class _MultiRoleGuardState extends State<MultiRoleGuard> {
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final userPermissions = await AuthService.getCurrentUserPermissions();
    
    bool hasAccess;
    if (widget.requireAll) {
      // Requiere TODOS los permisos
      hasAccess = widget.requiredPermissions.every(
        (permission) => userPermissions.contains(permission),
      );
    } else {
      // Requiere AL MENOS UNO de los permisos
      hasAccess = widget.requiredPermissions.any(
        (permission) => userPermissions.contains(permission),
      );
    }

    if (mounted) {
      setState(() {
        _hasPermission = hasAccess;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_hasPermission) {
      return widget.child;
    }

    return widget.fallback ?? const SizedBox.shrink();
  }
}