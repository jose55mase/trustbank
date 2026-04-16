import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/pedido.dart';
import '../../providers/pedido_providers.dart';
import '../../providers/repartidor_providers.dart';

/// Historial de pedidos completados con filtros por fecha, repartidor y usuario.
///
/// Requisitos: 9.1, 9.3, 9.4
class HistorialPedidosScreen extends ConsumerStatefulWidget {
  const HistorialPedidosScreen({super.key});

  @override
  ConsumerState<HistorialPedidosScreen> createState() =>
      _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState
    extends ConsumerState<HistorialPedidosScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _repartidorIdFiltro;
  String? _telefonoUsuarioFiltro;
  List<PedidoHistorial>? _resultados;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _loading = true);
    final repo = ref.read(pedidoRepositoryProvider);
    final data = await repo.obtenerHistorial(
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      repartidorId: _repartidorIdFiltro,
      telefonoUsuario: _telefonoUsuarioFiltro,
    );
    if (mounted) {
      setState(() {
        _resultados = data;
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
      setState(() =>
          _fechaFin = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
      _cargarHistorial();
    }
  }

  void _mostrarFiltroRepartidor() {
    final repartidoresAsync = ref.read(repartidoresProvider);
    repartidoresAsync.when(
      loading: () {},
      error: (_, __) {},
      data: (repartidores) {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppTheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrar por Repartidor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Todos',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  onTap: () {
                    setState(() => _repartidorIdFiltro = null);
                    Navigator.pop(ctx);
                    _cargarHistorial();
                  },
                ),
                ...repartidores.map(
                  (r) => ListTile(
                    title: Text(r.nombreCompleto,
                        style: const TextStyle(color: AppTheme.textPrimary)),
                    trailing: _repartidorIdFiltro == r.id
                        ? const Icon(Icons.check, color: AppTheme.accent)
                        : null,
                    onTap: () {
                      setState(() => _repartidorIdFiltro = r.id);
                      Navigator.pop(ctx);
                      _cargarHistorial();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _repartidorIdFiltro = null;
      _telefonoUsuarioFiltro = null;
    });
    _cargarHistorial();
  }

  bool get _hayFiltrosActivos =>
      _fechaInicio != null ||
      _fechaFin != null ||
      _repartidorIdFiltro != null ||
      _telefonoUsuarioFiltro != null;

  @override
  Widget build(BuildContext context) {
    // Pre-load repartidores for filter
    ref.watch(repartidoresProvider);

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
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
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delivery_dining, size: 16),
                      label: Text(
                        _repartidorIdFiltro != null
                            ? 'Repartidor ✓'
                            : 'Repartidor',
                      ),
                      onPressed: _mostrarFiltroRepartidor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Teléfono usuario',
                        prefixIcon: Icon(Icons.phone, size: 16),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (value) {
                        setState(() {
                          _telefonoUsuarioFiltro =
                              value.trim().isEmpty ? null : value.trim();
                        });
                        _cargarHistorial();
                      },
                    ),
                  ),
                  if (_hayFiltrosActivos)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.error),
                      onPressed: _limpiarFiltros,
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Results
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _resultados == null || _resultados!.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin registros en el historial',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _resultados!.length,
                      itemBuilder: (context, index) {
                        final h = _resultados![index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        h.nombreUsuario,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
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
                                const SizedBox(height: 4),
                                Text(
                                  h.descripcion,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  h.direccionEntrega,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.delivery_dining,
                                        size: 14, color: AppTheme.textHint),
                                    const SizedBox(width: 4),
                                    Text(
                                      h.nombreRepartidor,
                                      style: const TextStyle(
                                        color: AppTheme.textHint,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.access_time,
                                        size: 14, color: AppTheme.textHint),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDateTime(h.fechaCompletacion),
                                      style: const TextStyle(
                                        color: AppTheme.textHint,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
