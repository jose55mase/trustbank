import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
/// - Mensaje amigable cuando no hay leads asignados
/// - Navegación al formulario de edición al hacer clic en un lead
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

  @override
  void dispose() {
    _searchController.dispose();
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

  void _onLeadTap(LeadModel lead) {
    // Navigate to lead edit form (implemented in task 13.2)
    Navigator.of(context).pushNamed(
      '/supervisor/lead/edit',
      arguments: lead,
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
                  return _buildLeadsContent(state);
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
                  icon: const Icon(Icons.logout, color: TBColors.white),
                  tooltip: 'Cerrar sesión',
                  onPressed: () async {
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
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
    if (state.leads.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Results info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TBSpacing.screenPadding),
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
            DataColumn(label: Text('Comentarios')),
          ],
          rows: leads.map((lead) => _buildLeadRow(lead)).toList(),
        ),
      ),
    );
  }

  DataRow _buildLeadRow(LeadModel lead) {
    return DataRow(
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
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
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
