import 'package:flutter/material.dart';

import 'main_scaffold.dart';

/// A menu button for the AppBar that opens the navigation drawer on mobile.
///
/// On tablet/desktop (where the navigation rail/sidebar is always visible),
/// this returns null so the AppBar shows no leading widget.
class NavMenuButton extends StatelessWidget {
  const NavMenuButton({super.key});

  /// Returns a menu button widget if on mobile (drawer available),
  /// or null if navigation is already visible (tablet/desktop).
  static Widget? maybeOf(BuildContext context) {
    final scaffoldKey = MainScaffoldKey.of(context);
    if (scaffoldKey != null) {
      return NavMenuButton(key: ValueKey(scaffoldKey));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Menú de navegación',
      onPressed: () {
        final key = MainScaffoldKey.of(context);
        key?.currentState?.openDrawer();
      },
    );
  }
}
