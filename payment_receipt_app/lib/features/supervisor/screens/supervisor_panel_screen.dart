import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../constants/countries.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../models/lead_model.dart';
import '../../../services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../bloc/supervisor_bloc.dart';

/// Pantalla principal del Panel del Supervisor (Asesor).
///
/// Muestra:
/// - Header con título "Mis Leads" y conteo total de leads asignados
/// - Campo de búsqueda para filtrar dentro de los leads asignados
/// - Tabla de leads con paginación (nombre, apellido, teléfono, email, país,
///   campaña, estado de última llamada, comentarios)
/// - Panel lateral derecho de edición al hacer clic en un lead
/// - Mensaje amigable cuando no hay leads asignados
class SupervisorPanelScreen extends StatelessWidget {
  const SupervisorPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SupervisorBloc()..add(LoadSupervisorLeads()),
      child: const _SupervisorPanelView(),
    );
  }
}

class _SupervisorPanelView extends StatefulWidget {
  const _SupervisorPanelView();

  @override
  State<_SupervisorPanelView> createState() => _SupervisorPanelViewState();
}

class _SupervisorPanelViewState extends State<_SupervisorPanelView> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  int _totalLeadCount = 0;
  static const int _pageSize = 20;

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

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();
    _telefonoController = TextEditingController();
    _emailController = TextEditingController();
    _campanaController = TextEditingController();
    _statusController = TextEditingController();
    _comentariosController = TextEditingController();
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

  void _onSearch(String term) {
    _currentPage = 0;
    if (term.trim().isEmpty) {
      context
          .read<SupervisorBloc>()
          .add(LoadSupervisorLeads(page: 0, size: _pageSize));
    } else {
      context
          .read<SupervisorBloc>()
          .add(SearchSupervisorLeads(term: term, page: 0, size: _pageSize));
    }
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    final term = _searchController.text.trim();
    if (term.isEmpty) {
      context
          .read<SupervisorBloc>()
          .add(LoadSupervisorLeads(page: page, size: _pageSize));
    } else {
      context
          .read<SupervisorBloc>()
          .add(SearchSupervisorLeads(term: term, page: page, size: _pageSize));
    }
  }

  // ─── DETAIL PANEL METHODS ────────────────────────────────────────────

  void _onLeadTap(LeadModel lead) {
    setState(() {
      _selectedLead = lead;
      _nombreController.text = lead.nombre ?? '';
      _apellidoController.text = lead.apellido ?? '';
      _telefonoController.text = lead.telefono ?? '';
      _emailController.text = lead.email ?? '';
      _campanaController.text = lead.campana ?? '';
      _statusController.text = lead.lastCallStatus ?? '';
      _comentariosController.text = lead.comentarios ?? '';
      _selectedPais =
          lead.pais != null && lead.pais!.isNotEmpty ? lead.pais : null;
      _selectedLastCallDate = lead.lastCallDate;
    });
  }

  void _closeDetailPanel() {
    setState(() {
      _selectedLead = null;
    });
  }

  void _saveLeadFromPanel() {
    if (_selectedLead == null) return;
    if (!(_panelFormKey.currentState?.validate() ?? false)) return;

    final fields = <String, dynamic>{
      'nombre': _nombreController.text.trim(),
      'apellido': _apellidoController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'email': _emailController.text.trim(),
      'pais': _selectedPais ?? '',
      'lastCallStatus': _statusController.text.trim(),
      'comentarios': _comentariosController.text.trim(),
      if (_selectedLastCallDate != null)
        'lastCallDate': _selectedLastCallDate!.toIso8601String(),
    };

    context.read<SupervisorBloc>().add(
          UpdateLead(leadId: _selectedLead!.id, fields: fields),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: BlocConsumer<SupervisorBloc, SupervisorState>(
              listener: _blocListener,
              builder: (context, state) {
                if (state is SupervisorLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: TBColors.primary),
                  );
                }
                if (state is SupervisorLeadsLoaded) {
                  return _buildMainContent(state);
                }
                if (state is SupervisorError) {
                  return _buildErrorState(state.message);
                }
                // SupervisorInitial
                return const Center(
                  child: CircularProgressIndicator(color: TBColors.primary),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _blocListener(BuildContext context, SupervisorState state) {
    if (state is SupervisorError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: TBColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    if (state is SupervisorLeadsLoaded) {
      setState(() {
        _currentPage = state.currentPage;
        _totalLeadCount = state.totalItems;
      });
    }
    if (state is SupervisorLeadUpdated) {
      _closeDetailPanel();
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      // Reload leads to reflect changes
      final term = _searchController.text.trim();
      if (term.isEmpty) {
        context
            .read<SupervisorBloc>()
            .add(LoadSupervisorLeads(page: _currentPage, size: _pageSize));
      } else {
        context.read<SupervisorBloc>().add(
              SearchSupervisorLeads(
                  term: term, page: _currentPage, size: _pageSize),
            );
      }
    }
  }

  // ─── MAIN CONTENT (TABLE + PANEL) ───────────────────────────────────

  Widget _buildMainContent(SupervisorLeadsLoaded state) {
    if (state.leads.isEmpty) {
      return _buildEmptyState();
    }

    return Row(
      children: [
        // Left: Table content
        Expanded(child: _buildLeadsContent(state)),
        // Right: Detail/Edit panel
        if (_selectedLead != null) _buildDetailPanel(),
      ],
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        TBSpacing.lg,
        TBSpacing.xl,
        TBSpacing.lg,
        TBSpacing.lg,
      ),
      decoration: const BoxDecoration(gradient: TBColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mis Leads${_totalLeadCount > 0 ? ' ($_totalLeadCount)' : ''}',
                  style: TBTypography.headlineMedium.copyWith(
                    color: TBColors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: TBColors.white),
                  tooltip: 'Recargar',
                  onPressed: () {
                    context.read<SupervisorBloc>().add(
                          LoadSupervisorLeads(
                              page: _currentPage, size: _pageSize),
                        );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: TBColors.white),
                  tooltip: 'Cerrar sesión',
                  onPressed: () async {
                    await AuthService.logout();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── SEARCH BAR ─────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.screenPadding),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, apellido, teléfono o email...',
          hintStyle: TBTypography.bodyMedium.copyWith(color: TBColors.grey500),
          prefixIcon: const Icon(Icons.search, color: TBColors.grey500),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: TBColors.grey500),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: TBColors.surface,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: TBSpacing.md,
            vertical: TBSpacing.md,
          ),
        ),
      ),
    );
  }

  // ─── LEADS CONTENT ──────────────────────────────────────────────────────

  Widget _buildLeadsContent(SupervisorLeadsLoaded state) {
    return Column(
      children: [
        // Results info
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: TBSpacing.screenPadding),
          child: Row(
            children: [
              Text(
                '${state.totalItems} lead${state.totalItems == 1 ? '' : 's'} encontrado${state.totalItems == 1 ? '' : 's'}',
                style: TBTypography.bodySmall.copyWith(color: TBColors.grey600),
              ),
              const Spacer(),
              Text(
                'Página ${state.currentPage + 1} de ${state.totalPages}',
                style: TBTypography.bodySmall.copyWith(color: TBColors.grey600),
              ),
            ],
          ),
        ),
        const SizedBox(height: TBSpacing.sm),
        // Leads table
        Expanded(
          child: _buildLeadsTable(state.leads),
        ),
        // Pagination
        _buildPagination(state),
      ],
    );
  }

  Widget _buildLeadsTable(List<LeadModel> leads) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.screenPadding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            TBColors.primary.withOpacity(0.05),
          ),
          headingTextStyle: TBTypography.labelMedium.copyWith(
            color: TBColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
          dataTextStyle: TBTypography.bodyMedium,
          columnSpacing: TBSpacing.lg,
          horizontalMargin: TBSpacing.md,
          decoration: BoxDecoration(
            color: TBColors.surface,
            borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: TBColors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          columns: const [
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Apellido')),
            DataColumn(label: Text('Teléfono')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('País')),
            DataColumn(label: Text('Campaña')),
            DataColumn(label: Text('Última Llamada')),
            DataColumn(label: Text('Últ. Fecha')),
            DataColumn(label: Text('Comentarios')),
          ],
          rows: leads.map((lead) => _buildLeadRow(lead)).toList(),
        ),
      ),
    );
  }

  DataRow _buildLeadRow(LeadModel lead) {
    return DataRow(
      selected: _selectedLead?.id == lead.id,
      onSelectChanged: (_) => _onLeadTap(lead),
      cells: [
        DataCell(Text(lead.nombre ?? '-')),
        DataCell(Text(lead.apellido ?? '-')),
        DataCell(Text(lead.telefono ?? '-')),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              lead.email ?? '-',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(lead.pais ?? '-')),
        DataCell(Text(lead.campana ?? '-')),
        DataCell(_buildCallStatusBadge(lead.lastCallStatus)),
        DataCell(Text(
          lead.lastCallDate != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(lead.lastCallDate!)
              : '-',
        )),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              lead.comentarios ?? '-',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallStatusBadge(String? status) {
    if (status == null || status.isEmpty) {
      return Text('-', style: TBTypography.bodyMedium);
    }

    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'contestó':
      case 'contesto':
      case 'contactado':
        badgeColor = TBColors.success;
        break;
      case 'no contestó':
      case 'no contesto':
      case 'sin respuesta':
        badgeColor = TBColors.warning;
        break;
      case 'número inválido':
      case 'numero invalido':
      case 'rechazado':
        badgeColor = TBColors.error;
        break;
      default:
        badgeColor = TBColors.grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TBTypography.labelMedium.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.symmetric(
                horizontal: TBSpacing.md, vertical: TBSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: TBColors.grey300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedLead!.nombre ?? ''} ${_selectedLead!.apellido ?? ''}'
                        .trim(),
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
                    ),
                    const SizedBox(height: TBSpacing.md),
                    _buildPanelTextField(
                      controller: _apellidoController,
                      label: 'Apellido',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: TBSpacing.md),
                    _buildPanelTextField(
                      controller: _telefonoController,
                      label: 'Teléfono',
                      icon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: TBSpacing.md),
                    _buildPanelTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: TBSpacing.md),
                    // País dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedPais != null &&
                              Countries.latinAmerica.contains(_selectedPais)
                          ? _selectedPais
                          : null,
                      decoration: InputDecoration(
                        labelText: 'País',
                        prefixIcon:
                            const Icon(Icons.public_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(TBSpacing.radiusMd),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                      items: Countries.latinAmerica.map((country) {
                        return DropdownMenuItem(
                          value: country,
                          child:
                              Text(country, style: TBTypography.bodyMedium),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPais = value;
                        });
                      },
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
                    _buildPanelTextField(
                      controller: _statusController,
                      label: 'Última Llamada',
                      icon: Icons.phone_callback_outlined,
                    ),
                    const SizedBox(height: TBSpacing.md),
                    // Última Fecha de Llamada datepicker + timepicker
                    GestureDetector(
                      onTap: () async {
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
                      },
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
                    _buildPanelTextField(
                      controller: _comentariosController,
                      label: 'Comentarios',
                      icon: Icons.comment_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: TBSpacing.xl),
                    // Guardar button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveLeadFromPanel,
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Guardar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TBColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(TBSpacing.radiusMd),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  // ─── PAGINATION ─────────────────────────────────────────────────────────

  Widget _buildPagination(SupervisorLeadsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: state.hasPrevious ? TBColors.primary : TBColors.grey400,
            onPressed:
                state.hasPrevious ? () => _goToPage(_currentPage - 1) : null,
            tooltip: 'Página anterior',
          ),
          const SizedBox(width: TBSpacing.sm),
          // Page indicators
          ..._buildPageIndicators(state),
          const SizedBox(width: TBSpacing.sm),
          // Next button
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: state.hasNext ? TBColors.primary : TBColors.grey400,
            onPressed: state.hasNext ? () => _goToPage(_currentPage + 1) : null,
            tooltip: 'Página siguiente',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicators(SupervisorLeadsLoaded state) {
    final totalPages = state.totalPages;
    if (totalPages <= 1) return [];

    final List<Widget> indicators = [];
    const int maxVisible = 5;
    int start = (_currentPage - maxVisible ~/ 2).clamp(0, totalPages - 1);
    int end = (start + maxVisible).clamp(0, totalPages);

    if (end - start < maxVisible && start > 0) {
      start = (end - maxVisible).clamp(0, totalPages - 1);
    }

    for (int i = start; i < end; i++) {
      final isActive = i == _currentPage;
      indicators.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Material(
            color: isActive ? TBColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
            child: InkWell(
              borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
              onTap: isActive ? null : () => _goToPage(i),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: TBTypography.labelMedium.copyWith(
                    color: isActive ? TBColors.white : TBColors.grey600,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return indicators;
  }

  // ─── EMPTY & ERROR STATES ───────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;

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
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.assignment_ind_outlined,
              size: 48,
              color: TBColors.primary,
            ),
          ),
          const SizedBox(height: TBSpacing.lg),
          Text(
            isSearching
                ? 'Sin resultados'
                : 'No tienes leads asignados actualmente',
            style: TBTypography.titleLarge,
          ),
          const SizedBox(height: TBSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TBSpacing.xl),
            child: Text(
              isSearching
                  ? 'No hay resultados para "${_searchController.text}"'
                  : 'Cuando te asignen leads, aparecerán aquí.',
              style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
              textAlign: TextAlign.center,
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
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: TBColors.error,
            ),
          ),
          const SizedBox(height: TBSpacing.lg),
          Text(
            'Error al cargar leads',
            style: TBTypography.titleLarge,
          ),
          const SizedBox(height: TBSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TBSpacing.xl),
            child: Text(
              message,
              style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: TBSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              _currentPage = 0;
              context
                  .read<SupervisorBloc>()
                  .add(LoadSupervisorLeads(page: 0, size: _pageSize));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TBColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
