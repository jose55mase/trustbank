import 'package:flutter/material.dart';

import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/components/atoms/tb_button.dart';
import '../../../../design_system/spacing/tb_spacing.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../models/advisor_summary.dart';
import '../models/assignment_result.dart';
import '../services/lead_assignment_service.dart';

/// Diálogo modal para asignar leads seleccionados a un asesor.
///
/// Carga la lista de asesores activos (ROLE_SUPERVISOR) desde el endpoint
/// de resumen de asesores, permite seleccionar uno, y ejecuta la asignación
/// masiva al confirmar.
///
/// Retorna el [AssignmentResult] al completar la asignación, o null al cancelar.
class AssignAdvisorDialog extends StatefulWidget {
  /// IDs de los leads seleccionados para asignar.
  final List<int> selectedLeadIds;

  /// Cantidad de leads que ya tienen un asesor asignado (para mostrar advertencia).
  final int alreadyAssignedCount;

  const AssignAdvisorDialog({
    super.key,
    required this.selectedLeadIds,
    this.alreadyAssignedCount = 0,
  });

  /// Muestra el diálogo y retorna el resultado de la asignación,
  /// o null si se cancela.
  static Future<AssignmentResult?> show(
    BuildContext context, {
    required List<int> selectedLeadIds,
    int alreadyAssignedCount = 0,
  }) {
    return showDialog<AssignmentResult?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssignAdvisorDialog(
        selectedLeadIds: selectedLeadIds,
        alreadyAssignedCount: alreadyAssignedCount,
      ),
    );
  }

  @override
  State<AssignAdvisorDialog> createState() => _AssignAdvisorDialogState();
}

class _AssignAdvisorDialogState extends State<AssignAdvisorDialog> {
  List<AdvisorSummary>? _advisors;
  bool _isLoading = true;
  bool _isAssigning = false;
  String? _errorMessage;
  AdvisorSummary? _selectedAdvisor;

  @override
  void initState() {
    super.initState();
    _loadAdvisors();
  }

  Future<void> _loadAdvisors() async {
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
          _errorMessage = 'Error cargando la lista de asesores';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmAssignment() async {
    if (_selectedAdvisor == null) return;

    setState(() => _isAssigning = true);

    try {
      final result = await LeadAssignmentService.assignLeads(
        leadIds: widget.selectedLeadIds,
        advisorId: _selectedAdvisor!.advisorId,
      );
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al asignar leads: ${e.toString().replaceFirst('Exception: ', '')}';
          _isAssigning = false;
        });
      }
    }
  }

  bool get _hasAdvisors => _advisors != null && _advisors!.isNotEmpty;

  bool get _canConfirm => _hasAdvisors && _selectedAdvisor != null && !_isAssigning;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
      ),
      child: Container(
        padding: const EdgeInsets.all(TBSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: TBSpacing.md),
            _buildLeadCountInfo(),
            if (widget.alreadyAssignedCount > 0) ...[
              const SizedBox(height: TBSpacing.sm),
              _buildReassignWarning(),
            ],
            const SizedBox(height: TBSpacing.md),
            _buildBody(),
            if (_errorMessage != null && !_isLoading) ...[
              const SizedBox(height: TBSpacing.sm),
              _buildErrorMessage(),
            ],
            const SizedBox(height: TBSpacing.lg),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: TBColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add,
            color: TBColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: TBSpacing.md),
        Expanded(
          child: Text(
            'Asignar Leads a Asesor',
            style: TBTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeadCountInfo() {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.sm),
      decoration: BoxDecoration(
        color: TBColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: TBColors.primary, size: 18),
          const SizedBox(width: TBSpacing.sm),
          Text(
            '${widget.selectedLeadIds.length} lead${widget.selectedLeadIds.length == 1 ? '' : 's'} seleccionado${widget.selectedLeadIds.length == 1 ? '' : 's'}',
            style: TBTypography.bodyMedium.copyWith(
              color: TBColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReassignWarning() {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.sm),
      decoration: BoxDecoration(
        color: TBColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: TBColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: TBColors.warning, size: 18),
          const SizedBox(width: TBSpacing.sm),
          Expanded(
            child: Text(
              '${widget.alreadyAssignedCount} lead${widget.alreadyAssignedCount == 1 ? '' : 's'} ya tiene${widget.alreadyAssignedCount == 1 ? '' : 'n'} un asesor asignado y será${widget.alreadyAssignedCount == 1 ? '' : 'n'} reasignado${widget.alreadyAssignedCount == 1 ? '' : 's'}.',
              style: TBTypography.bodySmall.copyWith(
                color: TBColors.grey700,
              ),
            ),
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

    if (!_hasAdvisors && _errorMessage == null) {
      return _buildEmptyMessage();
    }

    if (_errorMessage != null && _advisors == null) {
      return const SizedBox.shrink();
    }

    return _buildAdvisorDropdown();
  }

  Widget _buildEmptyMessage() {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: TBColors.warning, size: 20),
          const SizedBox(width: TBSpacing.sm),
          Expanded(
            child: Text(
              'No hay asesores disponibles. Asegúrese de que existan usuarios con rol SUPERVISOR.',
              style: TBTypography.bodyMedium.copyWith(
                color: TBColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seleccionar asesor',
          style: TBTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: TBColors.grey700,
          ),
        ),
        const SizedBox(height: TBSpacing.xs),
        DropdownButtonFormField<int>(
          value: _selectedAdvisor?.advisorId,
          decoration: InputDecoration(
            hintText: 'Seleccione un asesor...',
            hintStyle: TBTypography.bodyMedium.copyWith(color: TBColors.grey500),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TBSpacing.md,
              vertical: TBSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
              borderSide: const BorderSide(color: TBColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
              borderSide: const BorderSide(color: TBColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
              borderSide: const BorderSide(color: TBColors.primary, width: 2),
            ),
          ),
          isExpanded: true,
          items: _advisors!.map((advisor) {
            return DropdownMenuItem<int>(
              value: advisor.advisorId,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    advisor.advisorName,
                    style: TBTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    advisor.advisorEmail,
                    style: TBTypography.bodySmall.copyWith(
                      color: TBColors.grey600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAdvisor = _advisors!.firstWhere(
                (a) => a.advisorId == value,
              );
            });
          },
          selectedItemBuilder: (context) {
            return _advisors!.map((advisor) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${advisor.advisorName} (${advisor.advisorEmail})',
                  style: TBTypography.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.sm),
      decoration: BoxDecoration(
        color: TBColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: TBColors.error, size: 18),
          const SizedBox(width: TBSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TBTypography.bodySmall.copyWith(
                color: TBColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TBButton(
            text: 'Cancelar',
            type: TBButtonType.outline,
            onPressed: _isAssigning ? null : () => Navigator.of(context).pop(null),
          ),
        ),
        const SizedBox(width: TBSpacing.sm),
        Expanded(
          child: TBButton(
            text: 'Asignar',
            isLoading: _isAssigning,
            onPressed: _canConfirm ? _confirmAssignment : null,
          ),
        ),
      ],
    );
  }
}
