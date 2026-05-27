import 'package:flutter/material.dart';
import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../../../../design_system/spacing/tb_spacing.dart';
import '../../../../design_system/components/atoms/tb_button.dart';
import '../../../../models/assignment_type.dart';
import '../../../../services/assignment_types_service.dart';

/// Diálogo modal para seleccionar un tipo de asignación al asignar
/// el rol ROLE_ASESOR a un usuario.
///
/// Carga los tipos de asignación activos desde el backend y permite
/// al administrador seleccionar uno antes de confirmar el cambio de rol.
///
/// Retorna el [AssignmentType] seleccionado al confirmar, o null al cancelar.
class RoleAssignmentDialog extends StatefulWidget {
  const RoleAssignmentDialog({super.key});

  /// Muestra el diálogo y retorna el tipo de asignación seleccionado,
  /// o null si se cancela.
  static Future<AssignmentType?> show(BuildContext context) {
    return showDialog<AssignmentType?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RoleAssignmentDialog(),
    );
  }

  @override
  State<RoleAssignmentDialog> createState() => _RoleAssignmentDialogState();
}

class _RoleAssignmentDialogState extends State<RoleAssignmentDialog> {
  List<AssignmentType>? _activeTypes;
  bool _isLoading = true;
  String? _errorMessage;
  AssignmentType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadActiveTypes();
  }

  Future<void> _loadActiveTypes() async {
    try {
      final types = await AssignmentTypesService.getActive();
      if (mounted) {
        setState(() {
          _activeTypes = types;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error cargando tipos de asignación';
          _isLoading = false;
        });
      }
    }
  }

  bool get _hasActiveTypes =>
      _activeTypes != null && _activeTypes!.isNotEmpty;

  bool get _canConfirm => _hasActiveTypes && _selectedType != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
      ),
      child: Container(
        padding: const EdgeInsets.all(TBSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: TBSpacing.md),
            _buildBody(),
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
            Icons.assignment_ind,
            color: TBColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: TBSpacing.md),
        Expanded(
          child: Text(
            'Seleccionar Tipo de Asignación',
            style: TBTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
      return _buildErrorMessage();
    }

    if (!_hasActiveTypes) {
      return _buildEmptyMessage();
    }

    return _buildTypesList();
  }

  Widget _buildErrorMessage() {
    return Container(
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
        ],
      ),
    );
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
              'No hay tipos de asignación activos. Cree uno primero.',
              style: TBTypography.bodyMedium.copyWith(
                color: TBColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypesList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        child: Column(
          children: _activeTypes!.map((type) {
            final isSelected = _selectedType?.id == type.id;
            return _buildTypeOption(type, isSelected);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTypeOption(AssignmentType type, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: TBSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: TBSpacing.md,
          vertical: TBSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? TBColors.primary : TBColors.grey300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
          color: isSelected ? TBColors.primary.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Radio<int>(
              value: type.id,
              groupValue: _selectedType?.id,
              onChanged: (value) {
                setState(() {
                  _selectedType = type;
                });
              },
              activeColor: TBColors.primary,
            ),
            const SizedBox(width: TBSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name,
                    style: TBTypography.titleMedium.copyWith(
                      color: isSelected ? TBColors.primary : TBColors.black,
                    ),
                  ),
                  if (type.description.isNotEmpty)
                    Text(
                      type.description,
                      style: TBTypography.bodySmall.copyWith(
                        color: TBColors.grey600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ),
        const SizedBox(width: TBSpacing.sm),
        Expanded(
          child: TBButton(
            text: 'Confirmar',
            onPressed: _canConfirm
                ? () => Navigator.of(context).pop(_selectedType)
                : null,
          ),
        ),
      ],
    );
  }
}
