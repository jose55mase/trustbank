import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/transactions_screen.dart';

class NavigationActions extends StatelessWidget {
  final List<Widget>? additionalActions;

  const NavigationActions({super.key, this.additionalActions});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
          tooltip: 'Inicio',
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionsScreen()),
            );
          },
          tooltip: 'Transacciones',
        ),
        if (additionalActions != null) ...additionalActions!,
      ],
    );
  }
}
