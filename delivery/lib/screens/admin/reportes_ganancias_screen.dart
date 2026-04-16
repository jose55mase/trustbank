import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../models/reporte.dart';

/// Reportes de ganancias con tres vistas: diaria, mensual, anual.
///
/// Requisitos: 6.1, 6.2, 6.3, 6.4, 6.5
class ReportesGananciasScreen extends ConsumerStatefulWidget {
  const ReportesGananciasScreen({super.key});

  @override
  ConsumerState<ReportesGananciasScreen> createState() =>
      _ReportesGananciasScreenState();
}

enum _VistaReporte { diaria, mensual, anual }

class _ReportesGananciasScreenState
    extends ConsumerState<ReportesGananciasScreen> {
  _VistaReporte _vistaActual = _VistaReporte.diaria;
  ReporteGanancias? _reporte;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarReporte();
  }

  Future<void> _cargarReporte() async {
    setState(() => _loading = true);
    final repo = ref.read(reporteGananciasRepositoryProvider);
    ReporteGanancias data;
    switch (_vistaActual) {
      case _VistaReporte.diaria:
        data = await repo.obtenerReporteDiario();
        break;
      case _VistaReporte.mensual:
        data = await repo.obtenerReporteMensual();
        break;
      case _VistaReporte.anual:
        data = await repo.obtenerReporteAnual();
        break;
    }
    if (mounted) {
      setState(() {
        _reporte = data;
        _loading = false;
      });
    }
  }

  String _tituloVista() {
    switch (_vistaActual) {
      case _VistaReporte.diaria:
        return 'Hoy';
      case _VistaReporte.mensual:
        return 'Este mes';
      case _VistaReporte.anual:
        return 'Este año';
    }
  }

  String _subtituloDesglose() {
    switch (_vistaActual) {
      case _VistaReporte.diaria:
        return 'Desglose por día del mes';
      case _VistaReporte.mensual:
        return 'Desglose por mes del año';
      case _VistaReporte.anual:
        return 'Comparativo por año';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // View selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<_VistaReporte>(
            segments: const [
              ButtonSegment(
                value: _VistaReporte.diaria,
                label: Text('Diaria'),
                icon: Icon(Icons.today),
              ),
              ButtonSegment(
                value: _VistaReporte.mensual,
                label: Text('Mensual'),
                icon: Icon(Icons.calendar_month),
              ),
              ButtonSegment(
                value: _VistaReporte.anual,
                label: Text('Anual'),
                icon: Icon(Icons.date_range),
              ),
            ],
            selected: {_vistaActual},
            onSelectionChanged: (selection) {
              setState(() => _vistaActual = selection.first);
              _cargarReporte();
            },
          ),
        ),
        // Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _reporte == null
                  ? const Center(
                      child: Text(
                        'Sin datos disponibles',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Total card
                        Card(
                          color: AppTheme.primaryDark,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(
                                  _tituloVista(),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${_reporte!.totalActual.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Total ganancias',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Breakdown title
                        Text(
                          _subtituloDesglose(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Breakdown list
                        if (_reporte!.desglose.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'Sin datos para este período',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._reporte!.desglose.map(
                            (periodo) => Card(
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
                                            periodo.etiqueta,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${periodo.cantidadPedidos} pedidos',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${periodo.total.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }
}
