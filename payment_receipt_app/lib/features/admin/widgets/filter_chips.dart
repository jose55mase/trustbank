import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../models/request_model.dart';

class FilterChips extends StatefulWidget {
  final Function(RequestType?, RequestStatus?) onFilterChanged;

  const FilterChips({super.key, required this.onFilterChanged});

  @override
  State<FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<FilterChips> {
  RequestType? selectedType;
  RequestStatus? selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filtrar por tipo:', style: TBTypography.labelMedium),
        const SizedBox(height: TBSpacing.sm),
        Wrap(
          spacing: TBSpacing.sm,
          children: [
            _buildFilterChip('Todos', null, selectedType == null, (selected) {
              setState(() => selectedType = null);
              widget.onFilterChanged(selectedType, selectedStatus);
            }),
            _buildFilterChip('Envíos', RequestType.sendMoney, selectedType == RequestType.sendMoney, (selected) {
              setState(() => selectedType = RequestType.sendMoney);
              widget.onFilterChanged(selectedType, selectedStatus);
            }),
            _buildFilterChip('Recargas', RequestType.recharge, selectedType == RequestType.recharge, (selected) {
              setState(() => selectedType = RequestType.recharge);
              widget.onFilterChanged(selectedType, selectedStatus);
            }),
            _buildFilterChip('Créditos', RequestType.credit, selectedType == RequestType.credit, (selected) {
              setState(() => selectedType = RequestType.credit);
              widget.onFilterChanged(selectedType, selectedStatus);
            }),
          ],
        ),
        const SizedBox(height: TBSpacing.md),
        Text('Filtrar por estado:', style: TBTypography.labelMedium),
        const SizedBox(height: TBSpacing.sm),
        Wrap(
          spacing: TBSpacing.sm,
          children: [
            _buildFilterChip('Todos', null, selectedStatus == null, (selected) {
              setState(() => selectedStatus = null);
              widget.onFilterChanged(selectedType, selectedStatus);
            }),
            _buildFilterChip('Pendientes', RequestStatus.pending, selectedStatus == RequestStatus.pending, (selected) {
              setState(() => selectedStatus = RequestStatus.pending);
              widget.onFilterChanged(selectedType, selectedStatus);
            }),
            _buildFilterChip('Aprobados', RequestStatus.approved, selectedStatus == RequestStatus.approved, (selected) {
              setState(() => selectedStatus = RequestStatus.approved);
              widget.onFilterChanged(selectedType, selectedStatus);
            }),
            _buildFilterChip('Rechazados', RequestStatus.rejected, selectedStatus == RequestStatus.rejected, (selected) {
              setState(() => selectedStatus = RequestStatus.rejected);
              widget.onFilterChanged(selectedType, selectedStatus);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, dynamic value, bool isSelected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: TBColors.primary.withOpacity(0.2),
      checkmarkColor: TBColors.primary,
      labelStyle: TBTypography.labelMedium.copyWith(
        color: isSelected ? TBColors.primary : TBColors.grey600,
      ),
    );
  }
}