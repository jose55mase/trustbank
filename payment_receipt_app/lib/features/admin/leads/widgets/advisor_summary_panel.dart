import 'package:flutter/material.dart';

import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/spacing/tb_spacing.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../models/advisor_summary.dart';
import '../services/lead_assignment_service.dart';

/// Panel que muestra el resumen de asesores con la cantidad de leads asignados.
///
/// Presenta una tabla con columnas: Nombre, Email, Leads Asignados.
/// Incluye asesores con 0 leads en la lista.
/// Al hacer click en una fila, invoca [onAdvisorSelected] para que el padre
/// pueda filtrar/navegar a los leads de ese asesor.
class AdvisorSummaryPanel extends StatefulWidget {
  /// Callback invocado cuando el usuario selecciona un asesor de la tabla.
  /// Recibe el [AdvisorSummary] del asesor seleccionado.
  final void Function(AdvisorSummary advisor)? onAdvisorSelected;

  const AdvisorSummaryPanel({
    super.key,
    this.onAdvisorSelected,
  });

  @override
  State<AdvisorSummaryPanel> createState() => _AdvisorSummaryPanelState();
}

class _AdvisorSummaryPanelState extends State<AdvisorSummaryPanel> {
  List<AdvisorSummary>? _advisors;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdvisorSummary();
  }

  Future<void> _loadAdvisorSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final advisors = await LeadAssignmentService.getAdvisorSummary();
      if (mounted) {
        setState(() {
          _advisors = advisors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error al cargar el resumen de asesores: ${e.toString().replaceFirst('Exception: ', '')}';
          _isLoading = false;
        });
      }
    }
  }

  int get _totalLeads =>
      _advisors?.fold<int>(0, (sum, a) => sum + a.assignedLeadCount) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TBColors.surface,
        borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
        border: Border.all(color: TBColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: TBColors.grey300),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(TBSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: TBColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group,
              color: TBColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: TBSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de Asesores',
                  style: TBTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_isLoading && _advisors != null)
                  Text(
                    '${_advisors!.length} asesor${_advisors!.length == 1 ? '' : 'es'} · $_totalLeads lead${_totalLeads == 1 ? '' : 's'} asignados',
                    style: TBTypography.bodySmall.copyWith(
                      color: TBColors.grey600,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            color: TBColors.grey600,
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : _loadAdvisorSummary,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: TBSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_advisors == null || _advisors!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTable();
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(TBSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(TBSpacing.md),
        decoration: BoxDecoration(
          color: TBColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: TBColors.error, size: 20),
            const SizedBox(width: TBSpacing.sm),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TBTypography.bodyMedium.copyWith(
                  color: TBColors.error,
                ),
              ),
            ),
            const SizedBox(width: TBSpacing.sm),
            TextButton(
              onPressed: _loadAdvisorSummary,
              child: Text(
                'Reintentar',
                style: TBTypography.buttonMedium.copyWith(
                  color: TBColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(TBSpacing.lg),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 40,
              color: TBColors.grey400,
            ),
            const SizedBox(height: TBSpacing.sm),
            Text(
              'No hay asesores registrados',
              style: TBTypography.bodyMedium.copyWith(
                color: TBColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          TBColors.grey100,
        ),
        headingTextStyle: TBTypography.labelMedium.copyWith(
          color: TBColors.grey700,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: TBTypography.bodyMedium,
        columnSpacing: TBSpacing.lg,
        horizontalMargin: TBSpacing.md,
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Email')),
          DataColumn(
            label: Text('Leads Asignados'),
            numeric: true,
          ),
        ],
        rows: _advisors!.map((advisor) {
          return DataRow(
            onSelectChanged: (_) {
              widget.onAdvisorSelected?.call(advisor);
            },
            cells: [
              DataCell(
                Text(
                  advisor.advisorName,
                  style: TBTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              DataCell(
                Text(
                  advisor.advisorEmail,
                  style: TBTypography.bodyMedium.copyWith(
                    color: TBColors.grey600,
                  ),
                ),
              ),
              DataCell(
                _buildLeadCountBadge(advisor.assignedLeadCount),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeadCountBadge(int count) {
    final Color bgColor;
    final Color textColor;

    if (count == 0) {
      bgColor = TBColors.grey300;
      textColor = TBColors.grey700;
    } else {
      bgColor = TBColors.primary.withOpacity(0.1);
      textColor = TBColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TBSpacing.sm,
        vertical: TBSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
      ),
      child: Text(
        count.toString(),
        style: TBTypography.labelMedium.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
