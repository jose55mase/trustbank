import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/user_profile/user_profile_page.dart';
import '../../presentation/pages/table_list/table_list_page.dart';
import '../../presentation/pages/notifications/notifications_page.dart';
import '../../presentation/templates/admin_layout.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/user-profile',
            builder: (context, state) => const UserProfilePage(),
          ),
          GoRoute(
            path: '/table-list',
            builder: (context, state) => const TableListPage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
        ],
      ),
    ],
  );
}