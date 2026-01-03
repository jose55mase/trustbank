import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../screens/home_screen.dart';
import '../screens/users_screen.dart';
import '../screens/new_loan_screen.dart';
import '../screens/new_user_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/loans_analytics_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/unregistered_payments_screen.dart';
import '../screens/login_screen.dart';
import '../../services/auth_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? userRole;
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getUser();
    if (mounted) {
      setState(() {
        userRole = user?['role'];
        username = user?['username'];
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    String? permission,
  }) {
    return FutureBuilder<bool>(
      future: permission != null ? AuthService.hasPermission(permission) : Future.value(true),
      builder: (context, snapshot) {
        if (snapshot.data == false) return const SizedBox.shrink();
        
        return ListTile(
          leading: Icon(icon, color: iconColor ?? AppColors.primary),
          title: Text(title),
          onTap: onTap,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inversiones Olaya IO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w200,
                    fontFamily: 'Dancing Script',
                    fontStyle: FontStyle.italic,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  username != null ? 'Usuario: $username' : 'Sistema Financiero',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (userRole != null)
                  Text(
                    'Rol: ${userRole == "ADMIN" ? "Administrador" : "Visualizador"}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                    ),
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
          _buildMenuItem(
            icon: Icons.people,
            title: 'Usuarios',
            permission: 'view_users',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.person_add,
            title: 'Registrar Usuario',
            iconColor: AppColors.secondary,
            permission: 'create_user',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewUserScreen()),
              );
            },
          ),
          const Divider(),
          _buildMenuItem(
            icon: Icons.add_circle,
            title: 'Nuevo Préstamo',
            permission: 'create_loan',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewLoanScreen()),
              );
            },
          ),
          const Divider(),
          _buildMenuItem(
            icon: Icons.bar_chart,
            title: 'Análisis',
            iconColor: AppColors.warning,
            permission: 'view_analytics',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          /*_buildMenuItem(
            icon: Icons.analytics,
            title: 'Análisis de Préstamos',
            iconColor: Colors.blue,
            permission: 'view_analytics',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoansAnalyticsScreen()),
              );
            },
          ),*/
          _buildMenuItem(
            icon: Icons.receipt,
            title: 'Gastos Diarios',
            iconColor: AppColors.error,
            permission: 'view_expenses',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpensesScreen()),
              );
            },
          ),
          const Divider(),
          _buildMenuItem(
            icon: Icons.swap_horiz,
            title: 'Transacciones',
            iconColor: Colors.purple,
            permission: 'view_transactions',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransactionsScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.money_off,
            title: 'Entradas y Salidas',
            iconColor: Colors.orange,
            permission: 'view_payments',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UnregisteredPaymentsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
