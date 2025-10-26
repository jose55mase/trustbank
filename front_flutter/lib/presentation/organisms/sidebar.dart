import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../molecules/sidebar_item.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: const Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 12),
                Text(
                  'Material Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                SidebarItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/dashboard',
                  isSelected: currentRoute == '/dashboard',
                ),
                SidebarItem(
                  icon: Icons.person,
                  title: 'User Profile',
                  route: '/user-profile',
                  isSelected: currentRoute == '/user-profile',
                ),
                SidebarItem(
                  icon: Icons.table_chart,
                  title: 'Table List',
                  route: '/table-list',
                  isSelected: currentRoute == '/table-list',
                ),
                SidebarItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  route: '/notifications',
                  isSelected: currentRoute == '/notifications',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}