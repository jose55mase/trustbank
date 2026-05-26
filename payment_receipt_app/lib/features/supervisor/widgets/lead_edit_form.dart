import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/countries.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../models/lead_model.dart';
import '../bloc/supervisor_bloc.dart';

/// Formulario de edición de lead para el supervisor.
///
/// Recibe un [LeadModel] como entrada y muestra todos los campos editables.
/// Todos los campos son opcionales (sin validación de requeridos).
/// Al guardar, envía solo los campos que fueron modificados respecto al original
/// (actualización parcial) mediante el evento [UpdateLead] del [SupervisorBloc].
class LeadEditForm extends StatefulWidget {
  final LeadModel lead;

  const LeadEditForm({super.key, required this.lead});

  @override
  State<LeadEditForm> createState() => _LeadEditFormState();
}

class _LeadEditFormState extends State<LeadEditForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;
  late final TextEditingController _campanaController;
  late final TextEditingController _lastCallStatusController;
  late final TextEditingController _comentariosController;

  /// Selected country value for the dropdown
  String? _selectedPais;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.lead.nombre ?? '');
    _apellidoController =
        TextEditingController(text: widget.lead.apellido ?? '');
    _telefonoController =
        TextEditingController(text: widget.lead.telefono ?? '');
    _emailController = TextEditingController(text: widget.lead.email ?? '');
    _campanaController = TextEditingController(text: widget.lead.campana ?? '');
    _lastCallStatusController =
        TextEditingController(text: widget.lead.lastCallStatus ?? '');
    _comentariosController =
        TextEditingController(text: widget.lead.comentarios ?? '');

    // Initialize country: use existing value if it's in the list, otherwise keep as-is
    final leadPais = widget.lead.pais ?? '';
    if (leadPais.isNotEmpty && Countries.latinAmerica.contains(leadPais)) {
      _selectedPais = leadPais;
    } else if (leadPais.isNotEmpty) {
      // Country not in list — keep the value but it won't be pre-selected
      _selectedPais = leadPais;
    } else {
      _selectedPais = null;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _campanaController.dispose();
    _lastCallStatusController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  /// Compara los valores actuales del formulario con los originales del lead
  /// y retorna un mapa con solo los campos que fueron modificados.
  Map<String, dynamic> _getModifiedFields() {
    final modified = <String, dynamic>{};

    final currentNombre = _nombreController.text;
    final originalNombre = widget.lead.nombre ?? '';
    if (currentNombre != originalNombre) {
      modified['nombre'] = currentNombre;
    }

    final currentApellido = _apellidoController.text;
    final originalApellido = widget.lead.apellido ?? '';
    if (currentApellido != originalApellido) {
      modified['apellido'] = currentApellido;
    }

    final currentTelefono = _telefonoController.text;
    final originalTelefono = widget.lead.telefono ?? '';
    if (currentTelefono != originalTelefono) {
      modified['telefono'] = currentTelefono;
    }

    final currentEmail = _emailController.text;
    final originalEmail = widget.lead.email ?? '';
    if (currentEmail != originalEmail) {
      modified['email'] = currentEmail;
    }

    final currentPais = _selectedPais ?? '';
    final originalPais = widget.lead.pais ?? '';
    if (currentPais != originalPais) {
      modified['pais'] = currentPais;
    }

    final currentCampana = _campanaController.text;
    final originalCampana = widget.lead.campana ?? '';
    if (currentCampana != originalCampana) {
      modified['campana'] = currentCampana;
    }

    final currentLastCallStatus = _lastCallStatusController.text;
    final originalLastCallStatus = widget.lead.lastCallStatus ?? '';
    if (currentLastCallStatus != originalLastCallStatus) {
      modified['lastCallStatus'] = currentLastCallStatus;
    }

    final currentComentarios = _comentariosController.text;
    final originalComentarios = widget.lead.comentarios ?? '';
    if (currentComentarios != originalComentarios) {
      modified['comentarios'] = currentComentarios;
    }

    return modified;
  }

  void _onSave() {
    final modifiedFields = _getModifiedFields();

    if (modifiedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se han realizado cambios'),
          backgroundColor: TBColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    context.read<SupervisorBloc>().add(
          UpdateLead(leadId: widget.lead.id, fields: modifiedFields),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupervisorBloc, SupervisorState>(
      listener: (context, state) {
        if (state is SupervisorLeadUpdated) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lead actualizado exitosamente'),
              backgroundColor: TBColors.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is SupervisorError) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: TBColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: TBColors.background,
        appBar: AppBar(
          title: Text(
            'Editar Lead',
            style: TBTypography.headlineMedium.copyWith(color: TBColors.white),
          ),
          backgroundColor: TBColors.primary,
          iconTheme: const IconThemeData(color: TBColors.white),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(TBSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Lead ID info
                _buildLeadIdBanner(),
                const SizedBox(height: TBSpacing.lg),
                // Form fields
                _buildTextField(
                  controller: _nombreController,
                  label: 'Nombre',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: TBSpacing.md),
                _buildTextField(
                  controller: _apellidoController,
                  label: 'Apellido',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: TBSpacing.md),
                _buildTextField(
                  controller: _telefonoController,
                  label: 'Teléfono',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: TBSpacing.md),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: TBSpacing.md),
                _buildCountryDropdown(),
                const SizedBox(height: TBSpacing.md),
                _buildTextField(
                  controller: _campanaController,
                  label: 'Campaña',
                  icon: Icons.campaign_outlined,
                ),
                const SizedBox(height: TBSpacing.md),
                _buildTextField(
                  controller: _lastCallStatusController,
                  label: 'Estado de Última Llamada',
                  icon: Icons.call_outlined,
                ),
                const SizedBox(height: TBSpacing.md),
                _buildTextField(
                  controller: _comentariosController,
                  label: 'Comentarios',
                  icon: Icons.comment_outlined,
                  maxLines: 4,
                ),
                const SizedBox(height: TBSpacing.xl),
                // Save button
                _buildSaveButton(),
                const SizedBox(height: TBSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadIdBanner() {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: TBColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: TBColors.primary, size: 20),
          const SizedBox(width: TBSpacing.sm),
          Text(
            'Lead #${widget.lead.id}',
            style: TBTypography.titleMedium.copyWith(color: TBColors.primary),
          ),
          const Spacer(),
          if (widget.lead.campana != null && widget.lead.campana!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TBSpacing.sm,
                vertical: TBSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: TBColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
              ),
              child: Text(
                widget.lead.campana!,
                style: TBTypography.labelMedium.copyWith(
                  color: TBColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TBTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
        prefixIcon: Icon(icon, color: TBColors.grey500, size: 20),
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
    );
  }

  Widget _buildCountryDropdown() {
    // Build the list of dropdown items including the current value if not in the standard list
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: '',
        child: Text('Seleccionar país'),
      ),
    ];

    // If the lead has a country not in the standard list, add it as an option
    final currentPais = _selectedPais ?? '';
    if (currentPais.isNotEmpty && !Countries.latinAmerica.contains(currentPais)) {
      items.add(DropdownMenuItem(
        value: currentPais,
        child: Text(currentPais),
      ));
    }

    for (final country in Countries.latinAmerica) {
      items.add(DropdownMenuItem(
        value: country,
        child: Text(country),
      ));
    }

    return DropdownButtonFormField<String>(
      value: (currentPais.isNotEmpty &&
              items.any((item) => item.value == currentPais))
          ? currentPais
          : '',
      items: items,
      onChanged: (value) {
        setState(() {
          _selectedPais = (value == null || value.isEmpty) ? null : value;
        });
      },
      style: TBTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: 'País',
        labelStyle: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
        prefixIcon:
            const Icon(Icons.public_outlined, color: TBColors.grey500, size: 20),
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
      isExpanded: true,
      menuMaxHeight: 300,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: TBColors.primary,
          foregroundColor: TBColors.white,
          disabledBackgroundColor: TBColors.grey400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TBColors.white,
                ),
              )
            : Text(
                'Guardar Cambios',
                style: TBTypography.buttonMedium.copyWith(
                  color: TBColors.white,
                ),
              ),
      ),
    );
  }
}
