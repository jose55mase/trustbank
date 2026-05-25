import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../../../../design_system/spacing/tb_spacing.dart';
import '../bloc/leads_bloc.dart';
import '../models/advisor_summary.dart';
import '../models/lead_model.dart';
import '../services/lead_assignment_service.dart';
import '../services/leads_service.dart';
import '../widgets/assign_advisor_dialog.dart';

class LeadsListScreen extends StatelessWidget {
  const LeadsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LeadsBloc(leadsService: LeadsService())..add(LoadLeads()),
      child: const _LeadsListView(),
    );
  }
}

String _fileNameFromPath(String filePath) {
  return filePath.split('/').last;
}

class _LeadsListView extends StatefulWidget {
  const _LeadsListView();

  @override
  State<_LeadsListView> createState() => _LeadsListViewState();
}

class _LeadsListViewState extends State<_LeadsListView> {
  final _searchController = TextEditingController();
  int _currentPage = 0;
  String? _sortColumn;
  bool _sortAscending = true;
  String _searchTerm = '';
  bool _isExporting = false;
  final Set<int> _selectedLeadIds = {};

  // ─── FILTER STATE ────────────────────────────────────────────────────
  /// Current filter value: 'all', 'unassigned', or advisor ID as string (e.g., '5')
  String _filterValue = 'all';
  /// Loaded advisor list for the filter dropdown
  List<AdvisorSummary> _advisors = [];
  bool _isUnassigning = false;

  /// Returns the set of selected lead IDs for external access (e.g., assignment actions).
  Set<int> get selectedLeadIds => _selectedLeadIds;

  @override
  void initState() {
    super.initState();
    _loadAdvisorsForFilter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads the advisor list for the filter dropdown.
  Future<void> _loadAdvisorsForFilter() async {
    try {
      final advisors = await LeadAssignmentService.getAdvisorSummary();
      if (mounted) {
        setState(() {
          _advisors = advisors;
        });
      }
    } catch (_) {
      // Silently fail — filter will just show "Todos" and "Sin asignar"
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchTerm = value;
      _currentPage = 0;
    });
    context.read<LeadsBloc>().add(SearchLeads(term: value, page: 0));
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _currentPage = 0;
    });
    _loadLeads();
  }

  void _loadLeads() {
    if (_searchTerm.isNotEmpty) {
      context.read<LeadsBloc>().add(SearchLeads(term: _searchTerm, page: _currentPage));
    } else {
      context.read<LeadsBloc>().add(LoadLeads(
        page: _currentPage,
        sortBy: _sortColumn,
        direction: _sortAscending ? 'asc' : 'desc',
        unassigned: _filterValue == 'unassigned' ? true : null,
        advisorId: _filterValue != 'all' && _filterValue != 'unassigned'
            ? int.tryParse(_filterValue)
            : null,
      ));
    }
  }

  void _goToPage(int page) {
    setState(() { _currentPage = page; });
    _loadLeads();
  }

  void _navigateToUpload() {
    Navigator.pushNamed(context, '/admin/leads/upload');
  }

  // ─── MODAL DE DETALLE ───────────────────────────────────────────────
  void _showLeadDetailModal(BuildContext context, LeadModel lead) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TBSpacing.radiusLg)),
        elevation: 16,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TBSpacing.lg),
                decoration: const BoxDecoration(
                  gradient: TBColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(TBSpacing.radiusLg),
                    topRight: Radius.circular(TBSpacing.radiusLg),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white24,
                      child: Text(
                        '${lead.nombre.isNotEmpty ? lead.nombre[0].toUpperCase() : ''}${lead.apellido.isNotEmpty ? lead.apellido[0].toUpperCase() : ''}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: TBSpacing.sm),
                    Text(
                      '${lead.nombre} ${lead.apellido}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    if (lead.lastCallStatus.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          lead.lastCallStatus,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Contenido
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(TBSpacing.lg),
                  child: Column(
                    children: [
                      _buildInfoTile(Icons.phone_outlined, 'Teléfono', lead.telefono),
                      _buildInfoTile(Icons.email_outlined, 'Email', lead.email),
                      _buildInfoTile(Icons.public_outlined, 'País', lead.pais),
                      _buildInfoTile(Icons.campaign_outlined, 'Campaña', lead.campana),
                      _buildInfoTile(Icons.comment_outlined, 'Comentarios', lead.comentarios),
                      if (lead.fechaRegistro != null)
                        _buildInfoTile(
                          Icons.calendar_today_outlined,
                          'Fecha de Registro',
                          '${lead.fechaRegistro!.day.toString().padLeft(2, '0')}/${lead.fechaRegistro!.month.toString().padLeft(2, '0')}/${lead.fechaRegistro!.year}',
                        ),
                    ],
                  ),
                ),
              ),
              // Botones de acción
              Container(
                padding: const EdgeInsets.symmetric(horizontal: TBSpacing.lg, vertical: TBSpacing.md),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: TBColors.grey300)),
                ),
                child: Row(
                  children: [
                    // Eliminar
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Eliminar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TBColors.error,
                        side: const BorderSide(color: TBColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TBSpacing.radiusMd)),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _confirmDelete(lead);
                      },
                    ),
                    const Spacer(),
                    // Editar
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TBColors.primary,
                        side: const BorderSide(color: TBColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TBSpacing.radiusMd)),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.pushNamed(context, '/admin/leads/detail', arguments: lead.id);
                      },
                    ),
                    const SizedBox(width: TBSpacing.sm),
                    // Cerrar
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TBColors.primary,
                        foregroundColor: TBColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TBSpacing.radiusMd)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: TBSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TBColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: TBColors.primary),
          ),
          const SizedBox(width: TBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TBTypography.bodyMedium.copyWith(color: TBColors.grey500, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(LeadModel lead) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TBSpacing.radiusLg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TBColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: TBColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Confirmar eliminación'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el lead "${lead.nombre} ${lead.apellido}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Eliminar'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (lead.id != null) {
                context.read<LeadsBloc>().add(DeleteLead(leadId: lead.id!));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TBColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TBSpacing.radiusMd)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BUILD PRINCIPAL ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadsBloc, LeadsState>(
      listener: (context, state) {
        if (state is ExportInProgress) {
          setState(() { _isExporting = true; });
        } else if (state is ExportCompleted) {
          setState(() { _isExporting = false; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Exportado: ${_fileNameFromPath(state.filePath)}'),
              ],
            ),
            backgroundColor: TBColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ));
        } else if (state is LeadsError && _isExporting) {
          setState(() { _isExporting = false; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: TBColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: TBColors.background,
        body: Column(
          children: [
            _buildHeader(),
            _buildStatsBar(),
            _buildSearchBar(),
            _buildActionToolbar(),
            Expanded(
              child: BlocBuilder<LeadsBloc, LeadsState>(
                buildWhen: (previous, current) =>
                    current is! ExportInProgress && current is! ExportCompleted,
                builder: (context, state) {
                  if (state is LeadsLoading) {
                    return const Center(child: CircularProgressIndicator(color: TBColors.primary));
                  }
                  if (state is LeadsError && !_isExporting) {
                    return _buildErrorState(state.message);
                  }
                  if (state is LeadsLoaded) {
                    if (state.leads.isEmpty) return _buildEmptyState();
                    return _buildLeadsTable(state);
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER CON GRADIENTE ───────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(TBSpacing.lg, TBSpacing.xl, TBSpacing.lg, TBSpacing.lg),
      decoration: const BoxDecoration(
        gradient: TBColors.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Botón regresar
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Regresar',
            ),
            const SizedBox(width: TBSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión de Leads',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Administra tus contactos y prospectos',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
            const Spacer(),
            // Exportar
            _isExporting
                ? const SizedBox(
                    width: 40, height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : _buildHeaderButton(Icons.download_rounded, 'Exportar', () {
                    context.read<LeadsBloc>().add(ExportLeads());
                  }),
            const SizedBox(width: TBSpacing.sm),
            // Importar
            _buildHeaderButton(Icons.upload_file_rounded, 'Importar', _navigateToUpload),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(tooltip, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── BARRA DE ESTADÍSTICAS ──────────────────────────────────────────
  Widget _buildStatsBar() {
    return BlocBuilder<LeadsBloc, LeadsState>(
      buildWhen: (prev, curr) => curr is LeadsLoaded,
      builder: (context, state) {
        if (state is! LeadsLoaded) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: TBSpacing.lg, vertical: TBSpacing.md),
          color: TBColors.surface,
          child: Row(
            children: [
              _buildStatChip(Icons.people_outline, '${state.leads.length} leads', TBColors.primary),
              const SizedBox(width: TBSpacing.md),
              _buildStatChip(Icons.pages_outlined, 'Pág. ${_currentPage + 1}/${state.totalPages == 0 ? 1 : state.totalPages}', TBColors.grey600),
              if (_selectedLeadIds.isNotEmpty) ...[
                const SizedBox(width: TBSpacing.md),
                _buildStatChip(Icons.check_circle_outline, '${_selectedLeadIds.length} seleccionados', TBColors.secondary),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── BARRA DE BÚSQUEDA ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.lg, vertical: TBSpacing.sm),
      color: TBColors.surface,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TBTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, email, teléfono...',
          hintStyle: TBTypography.bodyMedium.copyWith(color: TBColors.grey500),
          prefixIcon: const Icon(Icons.search, color: TBColors.grey500),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: TBColors.grey500),
                  onPressed: () { _searchController.clear(); _onSearchChanged(''); },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TBSpacing.radiusXl),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: TBColors.grey100,
          contentPadding: const EdgeInsets.symmetric(horizontal: TBSpacing.md, vertical: TBSpacing.sm),
        ),
      ),
    );
  }

  // ─── ACTION TOOLBAR (ASSIGNMENT BUTTONS + FILTER) ────────────────────
  Widget _buildActionToolbar() {
    final hasSelection = _selectedLeadIds.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.lg, vertical: TBSpacing.sm),
      decoration: const BoxDecoration(
        color: TBColors.surface,
        border: Border(bottom: BorderSide(color: TBColors.grey300, width: 0.5)),
      ),
      child: Row(
        children: [
          // "Asignar a Asesor" button
          _buildActionButton(
            icon: Icons.person_add_outlined,
            label: 'Asignar a Asesor',
            onPressed: hasSelection ? _onAssignPressed : null,
            color: TBColors.primary,
          ),
          const SizedBox(width: TBSpacing.sm),
          // "Desasignar" button
          _buildActionButton(
            icon: Icons.person_remove_outlined,
            label: 'Desasignar',
            onPressed: hasSelection ? _onUnassignPressed : null,
            color: TBColors.warning,
            isLoading: _isUnassigning,
          ),
          const Spacer(),
          // Filter dropdown
          _buildFilterDropdown(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    bool isLoading = false,
  }) {
    final isEnabled = onPressed != null && !isLoading;
    return Material(
      color: isEnabled ? color.withOpacity(0.08) : TBColors.grey100,
      borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        onTap: isEnabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, size: 18, color: isEnabled ? color : TBColors.grey400),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? color : TBColors.grey400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.filter_list, size: 18, color: TBColors.grey600),
        const SizedBox(width: 6),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _filterValue,
            isDense: true,
            style: TBTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: TBColors.grey700,
            ),
            icon: const Icon(Icons.arrow_drop_down, color: TBColors.grey600),
            items: _buildFilterItems(),
            onChanged: _onFilterChanged,
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildFilterItems() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: 'all',
        child: Text('Todos'),
      ),
      const DropdownMenuItem(
        value: 'unassigned',
        child: Text('Sin asignar'),
      ),
    ];

    // Add advisor options dynamically
    for (final advisor in _advisors) {
      items.add(DropdownMenuItem(
        value: advisor.advisorId.toString(),
        child: Text(
          advisor.advisorName,
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }

    return items;
  }

  void _onFilterChanged(String? value) {
    if (value == null || value == _filterValue) return;
    setState(() {
      _filterValue = value;
      _currentPage = 0;
      _selectedLeadIds.clear();
    });
    _loadLeads();
  }

  // ─── ASSIGNMENT ACTIONS ──────────────────────────────────────────────
  Future<void> _onAssignPressed() async {
    // Count how many selected leads already have an advisor
    final state = context.read<LeadsBloc>().state;
    int alreadyAssignedCount = 0;
    if (state is LeadsLoaded) {
      alreadyAssignedCount = state.leads
          .where((l) => l.id != null && _selectedLeadIds.contains(l.id) && l.advisorId != null)
          .length;
    }

    final result = await AssignAdvisorDialog.show(
      context,
      selectedLeadIds: _selectedLeadIds.toList(),
      alreadyAssignedCount: alreadyAssignedCount,
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${result.assignedCount} lead${result.assignedCount == 1 ? '' : 's'} asignado${result.assignedCount == 1 ? '' : 's'} a ${result.advisorName}',
              ),
            ),
          ],
        ),
        backgroundColor: TBColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
      setState(() => _selectedLeadIds.clear());
      _loadLeads();
      _loadAdvisorsForFilter(); // Refresh advisor counts
    }
  }

  Future<void> _onUnassignPressed() async {
    setState(() => _isUnassigning = true);
    try {
      final count = await LeadAssignmentService.unassignLeads(
        _selectedLeadIds.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('$count lead${count == 1 ? '' : 's'} desasignado${count == 1 ? '' : 's'}'),
            ],
          ),
          backgroundColor: TBColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
        setState(() {
          _selectedLeadIds.clear();
          _isUnassigning = false;
        });
        _loadLeads();
        _loadAdvisorsForFilter(); // Refresh advisor counts
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUnassigning = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al desasignar: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: TBColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ─── ESTADOS VACÍO Y ERROR ─────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TBColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, size: 48, color: TBColors.primary),
          ),
          const SizedBox(height: TBSpacing.lg),
          Text('No se encontraron leads', style: TBTypography.titleLarge),
          const SizedBox(height: TBSpacing.sm),
          Text('Importa un archivo Excel para comenzar', style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600)),
          const SizedBox(height: TBSpacing.lg),
          ElevatedButton.icon(
            onPressed: _navigateToUpload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importar Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TBColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TBSpacing.radiusMd)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TBColors.error.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 48, color: TBColors.error),
          ),
          const SizedBox(height: TBSpacing.lg),
          Text('Error al cargar leads', style: TBTypography.titleLarge),
          const SizedBox(height: TBSpacing.sm),
          Text(message, style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600), textAlign: TextAlign.center),
          const SizedBox(height: TBSpacing.lg),
          ElevatedButton.icon(
            onPressed: _loadLeads,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TBColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TBSpacing.radiusMd)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SELECCIÓN DE LEADS ──────────────────────────────────────────────
  void _toggleLeadSelection(int leadId) {
    setState(() {
      if (_selectedLeadIds.contains(leadId)) {
        _selectedLeadIds.remove(leadId);
      } else {
        _selectedLeadIds.add(leadId);
      }
    });
  }

  void _toggleSelectAll(List<LeadModel> leads) {
    setState(() {
      final allIds = leads.where((l) => l.id != null).map((l) => l.id!).toSet();
      if (_selectedLeadIds.containsAll(allIds)) {
        _selectedLeadIds.removeAll(allIds);
      } else {
        _selectedLeadIds.addAll(allIds);
      }
    });
  }

  bool _areAllSelected(List<LeadModel> leads) {
    final allIds = leads.where((l) => l.id != null).map((l) => l.id!).toSet();
    return allIds.isNotEmpty && _selectedLeadIds.containsAll(allIds);
  }

  // ─── TABLA DE LEADS ─────────────────────────────────────────────────
  Widget _buildLeadsTable(LeadsLoaded state) {
    final allSelected = _areAllSelected(state.leads);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                sortColumnIndex: _getSortColumnIndex(),
                sortAscending: _sortAscending,
                headingRowColor: WidgetStateProperty.all(TBColors.grey100),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return TBColors.primary.withOpacity(0.04);
                  }
                  return null;
                }),
                columns: [
                  // Checkbox "Select All" column
                  DataColumn(
                    label: Checkbox(
                      value: allSelected,
                      onChanged: (_) => _toggleSelectAll(state.leads),
                      activeColor: TBColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  _buildSortableColumn('Nombre', 'nombre'),
                  _buildSortableColumn('Apellido', 'apellido'),
                  _buildSortableColumn('Asesor', 'advisor'),
                  _buildSortableColumn('Status', 'lastCallStatus'),
                  _buildSortableColumn('País', 'pais'),
                  _buildSortableColumn('Teléfono', 'telefono'),
                  _buildSortableColumn('Email', 'email'),
                  _buildSortableColumn('Campaña', 'campana'),
                ],
                rows: state.leads.map((lead) {
                  final isSelected = lead.id != null && _selectedLeadIds.contains(lead.id);
                  return DataRow(
                    selected: isSelected,
                    color: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return TBColors.primary.withOpacity(0.06);
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return TBColors.primary.withOpacity(0.04);
                      }
                      return null;
                    }),
                    cells: [
                      DataCell(
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) {
                            if (lead.id != null) _toggleLeadSelection(lead.id!);
                          },
                          activeColor: TBColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      DataCell(Text(lead.nombre, style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500))),
                      DataCell(Text(lead.apellido, style: TBTypography.bodyMedium)),
                      DataCell(_buildAdvisorCell(lead)),
                      DataCell(_buildStatusBadge(lead.lastCallStatus)),
                      DataCell(Text(lead.pais, style: TBTypography.bodyMedium)),
                      DataCell(Text(lead.telefono, style: TBTypography.bodyMedium)),
                      DataCell(Text(lead.email, style: TBTypography.bodyMedium.copyWith(color: TBColors.primary))),
                      DataCell(Text(lead.campana, style: TBTypography.bodyMedium)),
                    ],
                    onSelectChanged: (_) => _showLeadDetailModal(context, lead),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        _buildPaginationControls(state),
      ],
    );
  }

  /// Builds the advisor cell showing the advisor name or "Sin asignar" badge.
  Widget _buildAdvisorCell(LeadModel lead) {
    if (lead.advisorName != null && lead.advisorName!.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 16, color: TBColors.grey600),
          const SizedBox(width: 4),
          Text(
            lead.advisorName!,
            style: TBTypography.bodyMedium,
          ),
        ],
      );
    }
    // Unassigned lead — show orange badge
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TBColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off_outlined, size: 14, color: TBColors.warning),
          SizedBox(width: 4),
          Text(
            'Sin asignar',
            style: TextStyle(
              fontSize: 12,
              color: TBColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TBColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 12, color: TBColors.secondary, fontWeight: FontWeight.w600),
      ),
    );
  }

  DataColumn _buildSortableColumn(String label, String field) {
    return DataColumn(
      label: Text(label, style: TBTypography.titleMedium.copyWith(color: TBColors.grey700, fontSize: 13)),
      onSort: (_, __) => _onSort(field),
    );
  }

  int? _getSortColumnIndex() {
    if (_sortColumn == null) return null;
    // Offset by 1 for the checkbox column at index 0
    const columns = ['nombre', 'apellido', 'advisor', 'lastCallStatus', 'pais', 'telefono', 'email', 'campana'];
    final index = columns.indexOf(_sortColumn!);
    return index >= 0 ? index + 1 : null;
  }

  Widget _buildPaginationControls(LeadsLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.lg, vertical: TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
            color: TBColors.primary,
            disabledColor: TBColors.grey400,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: TBColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Página ${_currentPage + 1} de ${state.totalPages == 0 ? 1 : state.totalPages}',
              style: TextStyle(fontSize: 13, color: TBColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _currentPage < state.totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
            color: TBColors.primary,
            disabledColor: TBColors.grey400,
          ),
        ],
      ),
    );
  }
}
