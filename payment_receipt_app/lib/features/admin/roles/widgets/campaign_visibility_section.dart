import 'package:flutter/material.dart';

import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/spacing/tb_spacing.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../../../../models/assignment_type.dart';
import '../../../../services/assignment_types_service.dart';
import '../../../../services/permissions_api_service.dart';

/// Sección de visibilidad de campañas dentro del panel de permisos.
///
/// Muestra la lista de campañas activas con checkboxes para configurar
/// qué campañas puede ver un rol en el módulo LEADS.
/// Cuando no hay campañas seleccionadas, el rol tiene acceso sin restricciones.
///
/// Requirements: 5.1, 5.2, 5.3, 5.4
class CampaignVisibilitySection extends StatefulWidget {
  /// ID del rol para el cual se configura la visibilidad.
  final int roleId;

  const CampaignVisibilitySection({
    super.key,
    required this.roleId,
  });

  @override
  State<CampaignVisibilitySection> createState() =>
      _CampaignVisibilitySectionState();
}

class _CampaignVisibilitySectionState extends State<CampaignVisibilitySection> {
  /// Lista de campañas activas disponibles.
  List<AssignmentType> _campaigns = [];

  /// IDs de campañas actualmente seleccionadas para el rol.
  Set<int> _selectedCampaignIds = {};

  /// Estado de carga de campañas.
  bool _isLoadingCampaigns = true;

  /// Estado de carga de la visibilidad actual del rol.
  bool _isLoadingVisibility = true;

  /// Indica si se está guardando un cambio.
  bool _isSaving = false;

  /// Mensaje de error, si existe.
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant CampaignVisibilitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roleId != widget.roleId) {
      _loadData();
    }
  }

  /// Carga las campañas activas y la visibilidad actual del rol.
  Future<void> _loadData() async {
    setState(() {
      _isLoadingCampaigns = true;
      _isLoadingVisibility = true;
      _error = null;
    });

    await Future.wait([
      _loadCampaigns(),
      _loadCurrentVisibility(),
    ]);
  }

  /// Carga la lista de campañas activas desde el API de assignment types.
  Future<void> _loadCampaigns() async {
    try {
      final campaigns = await AssignmentTypesService.getActive();
      if (mounted) {
        setState(() {
          _campaigns = campaigns;
          _isLoadingCampaigns = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCampaigns = false;
          _error = 'Error al cargar campañas: ${_parseError(e)}';
        });
      }
    }
  }

  /// Carga la visibilidad de campañas actual del rol.
  Future<void> _loadCurrentVisibility() async {
    try {
      final campaignIds =
          await PermissionsApiService.fetchRoleCampaignVisibility(
        widget.roleId,
      );
      if (mounted) {
        setState(() {
          _selectedCampaignIds = campaignIds.toSet();
          _isLoadingVisibility = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVisibility = false;
          _error = 'Error al cargar visibilidad: ${_parseError(e)}';
        });
      }
    }
  }

  /// Maneja el cambio de selección de una campaña.
  Future<void> _onCampaignToggled(int campaignId, bool selected) async {
    // Guardar estado previo para revertir en caso de error.
    final previousIds = Set<int>.from(_selectedCampaignIds);

    setState(() {
      if (selected) {
        _selectedCampaignIds.add(campaignId);
      } else {
        _selectedCampaignIds.remove(campaignId);
      }
      _isSaving = true;
    });

    try {
      await PermissionsApiService.updateCampaignVisibility(
        widget.roleId,
        _selectedCampaignIds.toList(),
      );
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      // Revertir al estado anterior y mostrar error.
      if (mounted) {
        setState(() {
          _selectedCampaignIds = previousIds;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al actualizar visibilidad: ${_parseError(e)}',
            ),
            backgroundColor: TBColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _parseError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: TBColors.grey300),
        const SizedBox(height: TBSpacing.md),
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TBSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.campaign_outlined,
                color: TBColors.primary,
                size: 20,
              ),
              const SizedBox(width: TBSpacing.sm),
              Text(
                'Visibilidad de campañas',
                style: TBTypography.titleMedium.copyWith(
                  color: TBColors.grey700,
                ),
              ),
              if (_isSaving) ...[
                const SizedBox(width: TBSpacing.sm),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TBColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: TBSpacing.sm),
        // Unrestricted access indicator
        _buildUnrestrictedIndicator(),
        const SizedBox(height: TBSpacing.sm),
        // Content
        _buildContent(),
      ],
    );
  }

  /// Indicador de acceso sin restricciones cuando no hay campañas seleccionadas.
  Widget _buildUnrestrictedIndicator() {
    final isUnrestricted = _selectedCampaignIds.isEmpty;
    if (!isUnrestricted || _isLoadingVisibility) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TBSpacing.md,
          vertical: TBSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: TBColors.secondary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
          border: Border.all(color: TBColors.secondary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.visibility_outlined,
              color: TBColors.secondary,
              size: 18,
            ),
            const SizedBox(width: TBSpacing.sm),
            Expanded(
              child: Text(
                'Acceso sin restricciones — el rol puede ver todos los leads',
                style: TBTypography.bodySmall.copyWith(
                  color: TBColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el contenido principal según el estado de carga.
  Widget _buildContent() {
    if (_isLoadingCampaigns || _isLoadingVisibility) {
      return const Padding(
        padding: EdgeInsets.all(TBSpacing.md),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: TBColors.primary,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(TBSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: TBColors.error, size: 18),
            const SizedBox(width: TBSpacing.sm),
            Expanded(
              child: Text(
                _error!,
                style: TBTypography.bodySmall.copyWith(color: TBColors.error),
              ),
            ),
            TextButton(
              onPressed: _loadData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_campaigns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(TBSpacing.md),
        child: Text(
          'No hay campañas activas configuradas',
          style: TBTypography.bodySmall.copyWith(color: TBColors.grey600),
        ),
      );
    }

    return _buildCampaignList();
  }

  /// Construye la lista de campañas con checkboxes.
  Widget _buildCampaignList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.md),
      child: Column(
        children: _campaigns.map((campaign) {
          final isSelected = _selectedCampaignIds.contains(campaign.id);
          return _buildCampaignCheckbox(campaign, isSelected);
        }).toList(),
      ),
    );
  }

  /// Construye un checkbox individual para una campaña.
  Widget _buildCampaignCheckbox(AssignmentType campaign, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.xs),
      decoration: BoxDecoration(
        color: TBColors.surface,
        borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: _isSaving
            ? null
            : (value) => _onCampaignToggled(campaign.id, value ?? false),
        title: Text(campaign.name, style: TBTypography.bodyMedium),
        subtitle: campaign.filterValue != null && campaign.filterValue!.isNotEmpty
            ? Text(
                campaign.filterValue!,
                style: TBTypography.bodySmall.copyWith(
                  color: TBColors.grey600,
                ),
              )
            : null,
        activeColor: TBColors.primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TBSpacing.md,
          vertical: 0,
        ),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
        ),
      ),
    );
  }
}
