import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../constants/countries.dart';
import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../../../../design_system/spacing/tb_spacing.dart';
import '../../../../services/permissions_provider.dart';
import '../bloc/lead_comments_bloc.dart';
import '../bloc/leads_bloc.dart';
import '../models/advisor_summary.dart';
import '../models/lead_model.dart';
import '../services/lead_assignment_service.dart';
import '../services/leads_service.dart';
import '../widgets/assign_advisor_dialog.dart';
import '../widgets/comments_section.dart';

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
  final _horizontalScrollController = ScrollController();
  int _currentPage = 0;
  String? _sortColumn;
  bool _sortAscending = true;
  String _searchTerm = '';
  bool _isExporting = false;
  final Set<int> _selectedLeadIds = {};

  // ─── FILTER STATE ────────────────────────────────────────────────────
  String _filterValue = 'all';
  String? _countryFilter;
  String? _statusFilter;
  List<AdvisorSummary> _advisors = [];
  bool _isUnassigning = false;
  bool _isSavingLead = false;

  // ─── DETAIL PANEL STATE ──────────────────────────────────────────────
  LeadModel? _selectedLead;
  final _panelFormKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _campanaController;
  late TextEditingController _statusController;
  late TextEditingController _comentariosController;
  String? _selectedPais;
  DateTime? _selectedLastCallDate;

  Set<int> get selectedLeadIds => _selectedLeadIds;

  @override
  void initState() {
    super.initState();
    _loadAdvisorsForFilter();
    _refreshPermissions();
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();
    _telefonoController = TextEditingController();
    _emailController = TextEditingController();
    _campanaController = TextEditingController();
    _statusController = TextEditingController();
    _comentariosController = TextEditingController();
  }

  /// Refresh granular permissions on navigation to Leads screen.
  Future<void> _refreshPermissions() async {
    await PermissionsProvider().refresh();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _campanaController.dispose();
    _statusController.dispose();
    _comentariosController.dispose();
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
    } catch (_) {}
  }

  // ─── DETAIL PANEL METHODS ────────────────────────────────────────────
  void _openDetailPanel(LeadModel lead) {
    setState(() {
      _selectedLead = lead;
      _nombreController.text = lead.nombre;
      _apellidoController.text = lead.apellido;
      _telefonoController.text = lead.telefono;
      _emailController.text = lead.email;
      _campanaController.text = lead.campana;
      _statusController.text = lead.lastCallStatus;
      _comentariosController.text = lead.comentarios;
      _selectedPais = lead.pais.isNotEmpty ? lead.pais : null;
      _selectedLastCallDate = lead.lastCallDate;
    });
  }

  void _closeDetailPanel() {
    setState(() {
      _selectedLead = null;
    });
  }

  void _openCommentsDialog(LeadModel lead) {
    if (lead.id == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.centerLeft,
          insetPadding: const EdgeInsets.only(left: 16, top: 40, bottom: 40, right: 300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 450,
            height: MediaQuery.of(dialogContext).size.height * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${lead.nombre} ${lead.apellido}',
                          style: TBTypography.titleLarge.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: BlocProvider(
                        create: (context) => LeadCommentsBloc()
                          ..add(LoadComments(leadId: lead.id!)),
                        child: CommentsSection(leadId: lead.id!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveLeadFromPanel() async {
    if (_selectedLead == null) return;
    if (!(_panelFormKey.currentState?.validate() ?? false)) return;

    final updatedLead = _selectedLead!.copyWith(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      email: _emailController.text.trim(),
      pais: _selectedPais ?? '',
      lastCallStatus: _statusController.text.trim(),
      lastCallDate: _selectedLastCallDate,
    );

    // Mostrar indicador de carga
    setState(() => _isSavingLead = true);

    try {
      await LeadsService.updateLead(updatedLead);
      if (!mounted) return;
      setState(() {
        _isSavingLead = false;
        // Update the selected lead in place without closing the panel
        _selectedLead = updatedLead;
      });
      // Reload the table at the current page (no reset)
      _loadLeads();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Lead actualizado correctamente'),
            ],
          ),
          backgroundColor: TBColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingLead = false);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
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
                child: const Icon(Icons.error_outline, color: TBColors.error, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Error al guardar'),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  void _deleteLeadFromPanel() {
    if (_selectedLead == null || _selectedLead!.id == null) return;
    _confirmDelete(_selectedLead!);
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
        pais: _countryFilter,
        status: _statusFilter,
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
                _closeDetailPanel();
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
              child: Row(
                children: [
                  // Left: Table content
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
                  // Right: Detail/Edit panel
                  if (_selectedLead != null) _buildDetailPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DETAIL/EDIT PANEL ──────────────────────────────────────────────
  Widget _buildDetailPanel() {
    return Container(
      width: 400,
      decoration: const BoxDecoration(
        color: TBColors.surface,
        border: Border(left: BorderSide(color: TBColors.grey300)),
      ),
      child: Column(
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: TBSpacing.md, vertical: TBSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: TBColors.grey300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedLead!.nombre} ${_selectedLead!.apellido}',
                    style: TBTypography.titleLarge.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _closeDetailPanel,
                  tooltip: 'Cerrar',
                  color: TBColors.grey600,
                ),
              ],
            ),
          ),
          // Scrollable form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(TBSpacing.md),
              child: Form(
                key: _panelFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPanelTextField(
                      controller: _nombreController,
                      label: 'Nombre',
                      icon: Icons.person_outline,
                      readOnly: !PermissionsProvider().permissions.canEdit(),
                    ),
                    const SizedBox(height: TBSpacing.md),
                    _buildPanelTextField(
                      controller: _apellidoController,
                      label: 'Apellido',
                      icon: Icons.person_outline,
                      readOnly: !PermissionsProvider().permissions.canEdit(),
                    ),
                    const SizedBox(height: TBSpacing.md),
                    _buildPanelTextField(
                      controller: _telefonoController,
                      label: 'Teléfono',
                      icon: Icons.phone_outlined,
                      readOnly: !PermissionsProvider().permissions.canEdit(),
                    ),
                    const SizedBox(height: TBSpacing.md),
                    _buildPanelTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      readOnly: !PermissionsProvider().permissions.canEdit(),
                    ),
                    const SizedBox(height: TBSpacing.md),
                    // País dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedPais != null && Countries.latinAmerica.contains(_selectedPais)
                          ? _selectedPais
                          : null,
                      decoration: InputDecoration(
                        labelText: 'País',
                        prefixIcon: const Icon(Icons.public_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                        ),
                        filled: !PermissionsProvider().permissions.canEdit(),
                        fillColor: !PermissionsProvider().permissions.canEdit() ? TBColors.grey100 : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: Countries.latinAmerica.map((country) {
                        return DropdownMenuItem(
                          value: country,
                          child: Text(country, style: TBTypography.bodyMedium),
                        );
                      }).toList(),
                      onChanged: PermissionsProvider().permissions.canEdit()
                          ? (value) {
                              setState(() { _selectedPais = value; });
                            }
                          : null,
                    ),
                    const SizedBox(height: TBSpacing.md),
                    // Campaña (read-only)
                    _buildPanelTextField(
                      controller: _campanaController,
                      label: 'Campaña',
                      icon: Icons.campaign_outlined,
                      readOnly: true,
                    ),
                    const SizedBox(height: TBSpacing.md),
                    // Status dropdown
                    DropdownButtonFormField<String>(
                      value: _statusController.text.isNotEmpty && 
                          _statusOptions.map((s) => s.toUpperCase()).contains(_statusController.text.toUpperCase())
                          ? _statusController.text.toUpperCase()
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        prefixIcon: const Icon(Icons.info_outline, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Sin status', style: TextStyle(color: Colors.grey)),
                        ),
                        ..._statusOptions.map((status) {
                          final color = _getStatusColor(status);
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(status, style: TBTypography.bodyMedium),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: PermissionsProvider().permissions.canEdit()
                          ? (value) {
                              setState(() => _statusController.text = value ?? '');
                            }
                          : null,
                    ),
                    const SizedBox(height: TBSpacing.md),
                    // Última Fecha de Llamada datepicker + timepicker
                    GestureDetector(
                      onTap: PermissionsProvider().permissions.canEdit()
                          ? () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedLastCallDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null && mounted) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: _selectedLastCallDate != null
                                ? TimeOfDay.fromDateTime(_selectedLastCallDate!)
                                : TimeOfDay.now(),
                          );
                          setState(() {
                            if (pickedTime != null) {
                              _selectedLastCallDate = DateTime(
                                pickedDate.year, pickedDate.month, pickedDate.day,
                                pickedTime.hour, pickedTime.minute,
                              );
                            } else {
                              _selectedLastCallDate = pickedDate;
                            }
                          });
                        }
                      }
                          : null,
                      child: AbsorbPointer(
                        child: TextFormField(
                          readOnly: true,
                          style: TBTypography.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Últ. Fecha de Llamada',
                            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          controller: TextEditingController(
                            text: _selectedLastCallDate != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(_selectedLastCallDate!)
                                : '',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: TBSpacing.md),
                    // Protected comments section
                    if (_selectedLead != null && _selectedLead!.id != null)
                      BlocProvider(
                        key: ValueKey('comments_${_selectedLead!.id}'),
                        create: (context) => LeadCommentsBloc()
                          ..add(LoadComments(leadId: _selectedLead!.id!)),
                        child: CommentsSection(leadId: _selectedLead!.id!),
                      ),
                    const SizedBox(height: TBSpacing.md),
                  ],
                ),
              ),
            ),
          ),
          // Fixed buttons at the bottom
          Padding(
            padding: const EdgeInsets.all(TBSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (PermissionsProvider().permissions.canEdit())
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSavingLead ? null : _saveLeadFromPanel,
                      icon: _isSavingLead
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(_isSavingLead ? 'Guardando...' : 'Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TBColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                if (PermissionsProvider().permissions.canEdit())
                  const SizedBox(height: TBSpacing.md),
                if (PermissionsProvider().permissions.canDelete())
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deleteLeadFromPanel,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Eliminar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TBColors.error,
                        side: const BorderSide(color: TBColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      style: TBTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        ),
        filled: readOnly,
        fillColor: readOnly ? TBColors.grey100 : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            _buildHeaderButton(Icons.refresh_rounded, 'Recargar', _loadLeads),
            if (PermissionsProvider().permissions.canExport()) ...[
              const SizedBox(width: TBSpacing.sm),
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
            ],
            if (PermissionsProvider().permissions.canImport()) ...[
              const SizedBox(width: TBSpacing.sm),
              _buildHeaderButton(Icons.upload_file_rounded, 'Importar', _navigateToUpload),
            ],
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
          if (PermissionsProvider().permissions.canAssign())
            _buildActionButton(
              icon: Icons.person_add_outlined,
              label: 'Asignar a Asesor',
              onPressed: hasSelection ? _onAssignPressed : null,
              color: TBColors.primary,
            ),
          if (PermissionsProvider().permissions.canAssign() &&
              PermissionsProvider().permissions.canUnassign())
            const SizedBox(width: TBSpacing.sm),
          if (PermissionsProvider().permissions.canUnassign())
            _buildActionButton(
              icon: Icons.person_remove_outlined,
              label: 'Desasignar',
              onPressed: hasSelection ? _onUnassignPressed : null,
              color: TBColors.warning,
              isLoading: _isUnassigning,
            ),
          const Spacer(),
          _buildCountryFilterDropdown(),
          const SizedBox(width: TBSpacing.md),
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

  Widget _buildCountryFilterDropdown() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.public, size: 18, color: TBColors.grey600),
        const SizedBox(width: 6),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _countryFilter ?? '',
            isDense: true,
            style: TBTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: TBColors.grey700,
            ),
            icon: const Icon(Icons.arrow_drop_down, color: TBColors.grey600),
            items: _buildCountryFilterItems(),
            onChanged: _onCountryFilterChanged,
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildCountryFilterItems() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: '',
        child: Text('Todos los países'),
      ),
    ];

    for (final country in Countries.latinAmerica) {
      items.add(DropdownMenuItem(
        value: country,
        child: Text(
          country,
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }

    return items;
  }

  void _onCountryFilterChanged(String? value) {
    if (value == null) return;
    setState(() {
      _countryFilter = value.isEmpty ? null : value;
      _currentPage = 0;
      _selectedLeadIds.clear();
    });
    _loadLeads();
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
      _loadAdvisorsForFilter();
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
        _loadAdvisorsForFilter();
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
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
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
                  DataColumn(label: _buildStatusColumnHeader()),
                  _buildSortableColumn('Últ. Llamada', 'lastCallDate'),
                  _buildSortableColumn('País', 'pais'),
                  _buildSortableColumn('Teléfono', 'telefono'),
                  _buildSortableColumn('Email', 'email'),
                  _buildSortableColumn('Campaña', 'campana'),
                  _buildSortableColumn('Fecha Registro', 'fechaRegistro'),
                  _buildSortableColumn('Comentarios', 'comentarios'),
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
                      DataCell(Text(
                        lead.lastCallDate != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(lead.lastCallDate!)
                            : '-',
                        style: TBTypography.bodyMedium,
                      )),
                      DataCell(Text(lead.pais, style: TBTypography.bodyMedium)),
                      DataCell(Text(lead.telefono, style: TBTypography.bodyMedium)),
                      DataCell(Text(lead.email, style: TBTypography.bodyMedium.copyWith(color: TBColors.primary))),
                      DataCell(Text(lead.campana, style: TBTypography.bodyMedium)),
                      DataCell(Text(
                        lead.fechaRegistro != null
                            ? DateFormat('dd/MM/yyyy').format(lead.fechaRegistro!)
                            : '-',
                        style: TBTypography.bodyMedium,
                      )),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 350),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (lead.lastComment ?? lead.comentarios).isNotEmpty
                                      ? (lead.lastComment ?? lead.comentarios)
                                      : '-',
                                  style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                              ),
                              if ((lead.lastComment ?? lead.comentarios).isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.open_in_new, size: 16, color: Colors.red),
                                  tooltip: 'Ver comentarios',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  onPressed: () => _openCommentsDialog(lead),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onSelectChanged: (_) => _openDetailPanel(lead),
                  );
                }).toList(),
              ),
            ),
          ),
          ),
        ),
        _buildPaginationControls(state),
      ],
    );
  }

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

  static const List<String> _statusOptions = [
    'NEW',
    'CALL BACK',
    'LOW POTENCIAL',
    'POTENTIAL',
    'NO ANSWER',
    'NO INTERED',
    'INTERED',
  ];

  static Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'NEW':
        return const Color(0xFF9E9E9E); // Grey
      case 'CALL BACK':
        return const Color(0xFF2196F3); // Blue
      case 'LOW POTENCIAL':
        return const Color(0xFFFF9800); // Orange
      case 'POTENTIAL':
        return const Color(0xFF9C27B0); // Violet
      case 'NO ANSWER':
        return const Color(0xFF00BCD4); // Cyan
      case 'NO INTERED':
        return const Color(0xFFF44336); // Red
      case 'INTERED':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  Widget _buildStatusColumnHeader() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _statusFilter ?? '',
        isDense: true,
        style: TBTypography.titleMedium.copyWith(
          color: TBColors.grey700,
          fontSize: 13,
        ),
        icon: Icon(
          Icons.filter_list,
          size: 14,
          color: _statusFilter != null ? TBColors.primary : TBColors.grey500,
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Status')),
          ..._statusOptions.map((s) => DropdownMenuItem(
            value: s,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: _getStatusColor(s), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(s, style: const TextStyle(fontSize: 12)),
              ],
            ),
          )),
        ],
        onChanged: (value) {
          setState(() {
            _statusFilter = (value == null || value.isEmpty) ? null : value;
            _currentPage = 0;
            _selectedLeadIds.clear();
          });
          _loadLeads();
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status.isEmpty) return const SizedBox.shrink();
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
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
    // Status column is now a filter dropdown (not sortable), skip it in index calculation
    const columns = ['nombre', 'apellido', 'advisor', null, 'lastCallDate', 'pais', 'telefono', 'email', 'campana', 'fechaRegistro', 'comentarios'];
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
