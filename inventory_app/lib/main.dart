import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/product_bloc.dart';
import 'bloc/product_event.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/product_repository.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/products_screen.dart';
import 'presentation/screens/categories_screen.dart';
import 'presentation/screens/sales_screen.dart';
import 'presentation/screens/customers_screen.dart';
import 'presentation/screens/reports_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductBloc(ProductRepository())..add(LoadProducts()),
      child: MaterialApp(
        title: 'Inventario App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/dashboard',
        routes: {
          '/dashboard': (context) => const DashboardScreen(),
          '/products': (context) => const ProductsScreen(),
          '/categories': (context) => const CategoriesScreen(),
          '/sales': (context) => const SalesScreen(),
          '/customers': (context) => const CustomersScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
