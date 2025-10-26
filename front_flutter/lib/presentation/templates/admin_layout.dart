import 'package:flutter/material.dart';
import '../organisms/sidebar.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}