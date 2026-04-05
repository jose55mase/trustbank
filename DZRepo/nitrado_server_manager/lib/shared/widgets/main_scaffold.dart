import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation item definition for the main scaffold.
class NavItem {
  final String label;
  final IconData icon;
  final String route;

  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// All navigation sections (Req 10.1).
const navItems = <NavItem>[
  NavItem(label: 'Estado', icon: Icons.dashboard, route: '/dashboard'),
  NavItem(label: 'Control', icon: Icons.power_settings_new, route: '/control'),
  NavItem(label: 'Jugadores', icon: Icons.people, route: '/players'),
  NavItem(label: 'Configuración', icon: Icons.settings, route: '/config'),
  NavItem(label: 'Items', icon: Icons.inventory_2, route: '/types'),
  NavItem(label: 'Globals', icon: Icons.tune, route: '/globals'),
  NavItem(label: 'Eventos', icon: Icons.event, route: '/events'),
  NavItem(label: 'Logs', icon: Icons.article, route: '/logs'),
];

/// Returns the selected navigation index based on the current route.
int selectedNavIndex(BuildContext context) {
  final location = GoRouterState.of(context).uri.toString();
  for (var i = 0; i < navItems.length; i++) {
    if (location.startsWith(navItems[i].route)) return i;
  }
  return 0;
}

/// Responsive navigation shell that wraps all post-auth screens.
///
/// - Mobile (<600px): Bottom navigation bar
/// - Tablet (600–1200px): NavigationRail
/// - Desktop (>1200px): Permanent sidebar
///
/// Requirements: 10.1, 10.2, 10.5
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  void _onItemTapped(BuildContext context, int index) {
    context.go(navItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final selectedIndex = selectedNavIndex(context);

    // Desktop (>1200px): permanent sidebar
    if (width > 1200) {
      return Row(
        children: [
          _DesktopSidebar(
            selectedIndex: selectedIndex,
            onItemTapped: (i) => _onItemTapped(context, i),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      );
    }

    // Tablet (600–1200px): NavigationRail
    if (width >= 600) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => _onItemTapped(context, i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: 'Cambiar servidor',
                onPressed: () => context.go('/servers'),
              ),
            ),
            destinations: navItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      );
    }

    // Mobile (<600px): child with its own Scaffold; navigation via drawer
    // The child screens provide their own Scaffold. We wrap with a drawer
    // accessible via the ScaffoldKey inherited widget.
    return _MobileShell(
      selectedIndex: selectedIndex,
      onItemTapped: (i) => _onItemTapped(context, i),
      child: child,
    );
  }
}

/// Mobile shell that provides a drawer alongside the child screen.
///
/// Uses a [ScaffoldKey] InheritedWidget so child screens can open the drawer
/// via `ScaffoldKey.of(context)?.currentState?.openDrawer()`.
class _MobileShell extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final Widget child;

  const _MobileShell({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.child,
  });

  @override
  State<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<_MobileShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MainScaffoldKey(
      scaffoldKey: _scaffoldKey,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _MobileDrawer(
          selectedIndex: widget.selectedIndex,
          onItemTapped: widget.onItemTapped,
          onChangeServer: () {
            Navigator.of(context).pop();
            context.go('/servers');
          },
        ),
        body: widget.child,
      ),
    );
  }
}

/// InheritedWidget that provides the outer scaffold key to child screens
/// so they can open the navigation drawer on mobile.
class MainScaffoldKey extends InheritedWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const MainScaffoldKey({
    super.key,
    required this.scaffoldKey,
    required super.child,
  });

  static GlobalKey<ScaffoldState>? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MainScaffoldKey>()
        ?.scaffoldKey;
  }

  @override
  bool updateShouldNotify(MainScaffoldKey oldWidget) =>
      scaffoldKey != oldWidget.scaffoldKey;
}

/// Permanent sidebar for desktop layout.
class _DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 240,
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nitrado Manager',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: navItems.length,
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  final selected = index == selectedIndex;
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: selected ? colorScheme.primary : null,
                    ),
                    title: Text(
                      item.label,
                      style: selected
                          ? TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            )
                          : null,
                    ),
                    selected: selected,
                    selectedTileColor:
                        colorScheme.primaryContainer.withOpacity(0.3),
                    onTap: () => onItemTapped(index),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Cambiar servidor'),
              onTap: () => context.go('/servers'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Drawer for mobile layout.
class _MobileDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback onChangeServer;

  const _MobileDrawer({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onChangeServer,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh),
            child: const Center(
              child: Text(
                'Nitrado Manager',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final selected = index == selectedIndex;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: selected ? colorScheme.primary : null,
                  ),
                  title: Text(
                    item.label,
                    style: selected
                        ? TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                  ),
                  selected: selected,
                  selectedTileColor:
                      colorScheme.primaryContainer.withOpacity(0.3),
                  onTap: () {
                    Navigator.of(context).pop(); // close drawer first
                    onItemTapped(index);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Cambiar servidor'),
            onTap: onChangeServer,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
