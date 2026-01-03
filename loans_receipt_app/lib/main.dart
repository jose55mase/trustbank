import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/transactions_screen.dart';
import 'presentation/screens/users_screen.dart';
import 'presentation/screens/unregistered_payments_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inversiones Olaya IO',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/transactions': (context) => const TransactionsScreen(),
        '/users': (context) => const UsersScreen(),
        '/unregistered-payments': (context) => const UnregisteredPaymentsScreen(),
      },
    );
  }
}
