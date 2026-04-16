import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/pedido.dart';
import '../../models/repartidor.dart';
import '../../providers/repartidor_providers.dart';

/// Lista de repartidores con nombre, total entregas y estado.
/// Al seleccionar uno, muestra historial de entregas con filtro por fechas.
///
/// Requisitos: 4.1, 4.2, 4.3
class GestionRepartidoresScreen extends ConsumerWidget {
  const GestionRepartidoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repartidoresAsync = ref.watch(repartidoresProvider);

    return repartidoresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (repartidores) {
        if (repartidores.isEmpty) {
          return const Center(
            child: Text(
              'No hay repartidores registrados',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: repartidores.length,
          itemBuilder: (context, index) => _RepartidorCard(
            repartidor: repartidores[index],
          ),
        );
      },
    );
  }
}

class _RepartidorCard extends StatelessWidget {
  final Repartidor repartidor;

  const _RepartidorCard({required this.repartidor});

  String _estadoLabel(EstadoRepartidor estado) {
    switch (estado) {
      case EstadoRepartidor.disponible:
        return 'Disponible';
      case EstadoRepartidor.enEntrega:
        return 'En entrega';
      case EstadoRepartidor.inactivo:
        return 'Inactivo';
    }
  }

  Color _estadoColor(EstadoRepartidor estado) {
    switch (estado) {
      case EstadoRepartidor.disponible:
        return AppTheme.success;
      case EstadoRepartidor.enEntrega:
        return AppTheme.accent;
      case EstadoRepartidor.inactivo:
        return AppTheme.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _HistorialRepartidorScreen(repartidor: repartidor),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primaryDark,
                radius: 24,
                child: Icon(Icons.person, color: AppTheme.textPrimary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repartidor.nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${repartidor.totalEntregas} entregas realizadas',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _estadoColor(repartidor.estado).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _estadoLabel(repartidor.estado),
                  style: TextStyle(
                    color: _estadoColor(repartidor.estado),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla de historial de entregas de un repartidor con filtro por fechas.
class _HistorialRepartidorScreen extends ConsumerStatefulWidget {
  final Repartidor repartidor;

  const _HistorialRepartidorScreen({required this.repartidor});

  @override
  ConsumerState<_HistorialRepartidorScreen> createState() =>
      _HistorialRepartidorScreenState();
}

class _HistorialRepartidorScreenState
    extends ConsumerState<_HistorialRepartidorScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  List<PedidoHistorial>? _historial;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _loading = true);
    final repo = ref.read(repartidorRepositoryProvider);
    final data = await repo.obtenerHistorialRepartidor(
      widget.repartidor.id,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
    );
    if (mounted) {
      setState(() {
        _historial = data;
        _loading = false;
      });
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fechaInicio = picked);
      _cargarHistorial();
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fechaFin = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
      _cargarHistorial();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repartidor.nombreCompleto),
      ),
      body: Column(
        children: [
          // Date filter row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _fechaInicio != null
                          ? _formatDate(_fechaInicio!)
                          : 'Desde',
                    ),
                    onPressed: _seleccionarFechaInicio,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _fechaFin != null ? _formatDate(_fechaFin!) : 'Hasta',
                    ),
                    onPressed: _seleccionarFechaFin,
                  ),
                ),
                if (_fechaInicio != null || _fechaFin != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.error),
                    onPressed: () {
                      setState(() {
                        _fechaInicio = null;
                        _fechaFin = null;
                      });
                      _cargarHistorial();
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // History list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _historial == null || _historial!.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin entregas en este período',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _historial!.length,
                        itemBuilder: (context, index) {
                          final h = _historial![index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          h.nombreUsuario,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(h.fechaCompletacion),
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${h.precioProducto.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
