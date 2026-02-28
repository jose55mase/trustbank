import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Inventory App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestión de Inventario',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/dashboard',
                  isSelected: currentRoute == '/dashboard',
                  onTap: () => _navigate(context, '/dashboard'),
                ),
                _DrawerItem(
                  icon: Icons.inventory_2,
                  title: 'Productos',
                  route: '/products',
                  isSelected: currentRoute == '/products',
                  onTap: () => _navigate(context, '/products'),
                ),
                _DrawerItem(
                  icon: Icons.category,
                  title: 'Categorías',
                  route: '/categories',
                  isSelected: currentRoute == '/categories',
                  onTap: () => _navigate(context, '/categories'),
                ),
                _DrawerItem(
                  icon: Icons.shopping_cart,
                  title: 'Ventas',
                  route: '/sales',
                  isSelected: currentRoute == '/sales',
                  onTap: () => _navigate(context, '/sales'),
                ),
                _DrawerItem(
                  icon: Icons.people,
                  title: 'Clientes',
                  route: '/customers',
                  isSelected: currentRoute == '/customers',
                  onTap: () => _navigate(context, '/customers'),
                ),
                const Divider(height: 1),
                _DrawerItem(
                  icon: Icons.analytics,
                  title: 'Reportes',
                  route: '/reports',
                  isSelected: currentRoute == '/reports',
                  onTap: () => _navigate(context, '/reports'),
                ),
                _DrawerItem(
                  icon: Icons.settings,
                  title: 'Configuración',
                  route: '/settings',
                  isSelected: currentRoute == '/settings',
                  onTap: () => _navigate(context, '/settings'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      Text('admin@tienda.com', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context);
    if (currentRoute != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
