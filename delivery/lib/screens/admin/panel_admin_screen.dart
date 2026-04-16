import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import 'cola_pedidos_screen.dart';
import 'gestion_repartidores_screen.dart';
import 'historial_pedidos_screen.dart';
import 'reportes_ganancias_screen.dart';

/// Panel principal del administrador con navegación por tabs.
///
/// Tabs: Cola de Pedidos, Repartidores, Historial, Ganancias.
/// Requisitos: 2.1, 4.1, 6.1, 9.3
class PanelAdminScreen extends ConsumerStatefulWidget {
  const PanelAdminScreen({super.key});

  @override
  ConsumerState<PanelAdminScreen> createState() => _PanelAdminScreenState();
}

class _PanelAdminScreenState extends ConsumerState<PanelAdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final repo = ref.read(authRepositoryProvider);
              await repo.logout();
              ref.invalidate(sesionActivaProvider);
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Pedidos'),
            Tab(icon: Icon(Icons.delivery_dining), text: 'Repartidores'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Ganancias'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ColaPedidosScreen(),
          GestionRepartidoresScreen(),
          HistorialPedidosScreen(),
          ReportesGananciasScreen(),
        ],
      ),
    );
  }
}
