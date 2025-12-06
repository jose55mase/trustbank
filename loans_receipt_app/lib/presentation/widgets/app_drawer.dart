import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../screens/home_screen.dart';
import '../screens/users_screen.dart';
import '../screens/new_loan_screen.dart';
import '../screens/new_user_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/expenses_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.account_balance, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Gestión de Préstamos',
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: AppColors.primary),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people, color: AppColors.primary),
            title: const Text('Usuarios'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add, color: AppColors.secondary),
            title: const Text('Registrar Usuario'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewUserScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle, color: AppColors.primary),
            title: const Text('Nuevo Préstamo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewLoanScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: AppColors.warning),
            title: const Text('Análisis de Ganancias'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt, color: AppColors.error),
            title: const Text('Gastos Diarios'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpensesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
