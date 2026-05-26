import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../constants/countries.dart';
import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../bloc/leads_bloc.dart';
import '../models/lead_model.dart';
import '../services/leads_service.dart';

class LeadDetailScreen extends StatelessWidget {
  final int leadId;

  const LeadDetailScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LeadsBloc(leadsService: LeadsService())..add(LoadLeadDetail(leadId: leadId)),
      child: _LeadDetailView(leadId: leadId),
    );
  }
}

class _LeadDetailView extends StatefulWidget {
  final int leadId;

  const _LeadDetailView({required this.leadId});

  @override
  State<_LeadDetailView> createState() => _LeadDetailViewState();
}

class _LeadDetailViewState extends State<_LeadDetailView> {
  bool _isEditing = false;
  bool _isUpdating = false;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _lastCallStatusController;
  late TextEditingController _paisController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _campanaController;
  late TextEditingController _fechaRegistroController;
  late TextEditingController _comentariosController;

  LeadModel? _currentLead;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();
    _lastCallStatusController = TextEditingController();
    _paisController = TextEditingController();
    _telefonoController = TextEditingController();
    _emailController = TextEditingController();
    _campanaController = TextEditingController();
    _fechaRegistroController = TextEditingController();
    _comentariosController = TextEditingController();
  }

  void _populateControllers(LeadModel lead) {
    _nombreController.text = lead.nombre;
    _apellidoController.text = lead.apellido;
    _lastCallStatusController.text = lead.lastCallStatus;
    _paisController.text = lead.pais;
    _telefonoController.text = lead.telefono;
    _emailController.text = lead.email;
    _campanaController.text = lead.campana;
    _fechaRegistroController.text = lead.fechaRegistro != null
        ? DateFormat('yyyy-MM-dd').format(lead.fechaRegistro!)
        : '';
    _comentariosController.text = lead.comentarios;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _lastCallStatusController.dispose();
    _paisController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _campanaController.dispose();
    _fechaRegistroController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    if (_currentLead != null) {
      _populateControllers(_currentLead!);
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;
    if (_currentLead == null) return;

    DateTime? fechaRegistro;
    if (_fechaRegistroController.text.isNotEmpty) {
      try {
        fechaRegistro = DateTime.parse(_fechaRegistroController.text);
      } catch (_) {
        fechaRegistro = _currentLead!.fechaRegistro;
      }
    }

    final updatedLead = _currentLead!.copyWith(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      lastCallStatus: _lastCallStatusController.text.trim(),
      pais: _paisController.text.trim(),
      telefono: _telefonoController.text.trim(),
      email: _emailController.text.trim(),
      campana: _campanaController.text.trim(),
      fechaRegistro: fechaRegistro,
      comentarios: _comentariosController.text.trim(),
    );

    setState(() {
      _isUpdating = true;
    });

    context.read<LeadsBloc>().add(UpdateLead(lead: updatedLead));
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Formato de email inválido';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido';
    }
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Solo se permiten dígitos, +, -, espacios y paréntesis';
    }
    if (value.trim().length < 7 || value.trim().length > 20) {
      return 'El teléfono debe tener entre 7 y 20 caracteres';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Lead'),
        backgroundColor: TBColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: _enterEditMode,
            ),
        ],
      ),
      body: BlocConsumer<LeadsBloc, LeadsState>(
        listener: (context, state) {
          if (state is LeadDetailLoaded) {
            _currentLead = state.lead;
            if (_isUpdating) {
              _isUpdating = false;
              setState(() {
                _isEditing = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lead actualizado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else if (state is LeadsError) {
            if (_isUpdating) {
              _isUpdating = false;
              setState(() {});
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LeadsLoading && _currentLead == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_currentLead == null) {
            if (state is LeadsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: TBTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<LeadsBloc>()
                            .add(LoadLeadDetail(leadId: widget.leadId));
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          if (_isEditing) {
            return _buildEditMode();
          }

          return _buildDetailView(_currentLead!);
        },
      ),
    );
  }

  Widget _buildDetailView(LeadModel lead) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailHeader(lead),
              const Divider(height: 32),
              _buildDetailField('Nombre', lead.nombre, Icons.person),
              _buildDetailField('Apellido', lead.apellido, Icons.person_outline),
              _buildDetailField(
                  'Estado de Llamada', lead.lastCallStatus, Icons.phone_callback),
              _buildDetailField('País', lead.pais, Icons.flag),
              _buildDetailField('Teléfono', lead.telefono, Icons.phone),
              _buildDetailField('Email', lead.email, Icons.email),
              _buildDetailField('Campaña', lead.campana, Icons.campaign),
              _buildDetailField(
                'Fecha de Registro',
                lead.fechaRegistro != null
                    ? DateFormat('dd/MM/yyyy').format(lead.fechaRegistro!)
                    : 'No disponible',
                Icons.calendar_today,
              ),
              _buildDetailField(
                  'Comentarios', lead.comentarios, Icons.comment),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _enterEditMode,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TBColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailHeader(LeadModel lead) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: TBColors.primary,
          child: Text(
            '${lead.nombre.isNotEmpty ? lead.nombre[0].toUpperCase() : ''}${lead.apellido.isNotEmpty ? lead.apellido[0].toUpperCase() : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${lead.nombre} ${lead.apellido}',
                style: TBTypography.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                lead.email,
                style: TBTypography.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: TBColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TBTypography.bodySmall.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'No disponible',
                  style: TBTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar Lead',
                  style: TBTypography.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nombreController,
                  label: 'Nombre',
                  icon: Icons.person,
                  validator: (v) => _validateRequired(v, 'Nombre'),
                ),
                _buildTextField(
                  controller: _apellidoController,
                  label: 'Apellido',
                  icon: Icons.person_outline,
                  validator: (v) => _validateRequired(v, 'Apellido'),
                ),
                _buildTextField(
                  controller: _lastCallStatusController,
                  label: 'Estado de Llamada',
                  icon: Icons.phone_callback,
                ),
                _buildCountryDropdown(),
                _buildTextField(
                  controller: _telefonoController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  controller: _campanaController,
                  label: 'Campaña',
                  icon: Icons.campaign,
                ),
                _buildTextField(
                  controller: _fechaRegistroController,
                  label: 'Fecha de Registro (yyyy-MM-dd)',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.datetime,
                ),
                _buildTextField(
                  controller: _comentariosController,
                  label: 'Comentarios',
                  icon: Icons.comment,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isUpdating ? null : _cancelEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TBColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isUpdating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    // Include current value even if not in standard list
    final currentValue = _paisController.text.trim();
    final countries = List<String>.from(Countries.latinAmerica);
    if (currentValue.isNotEmpty && !countries.contains(currentValue)) {
      countries.insert(0, currentValue);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: currentValue.isNotEmpty ? currentValue : null,
        decoration: const InputDecoration(
          labelText: 'País',
          prefixIcon: Icon(Icons.flag, color: TBColors.primary),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        menuMaxHeight: 300,
        items: [
          const DropdownMenuItem<String>(
            value: '',
            child: Text('Seleccionar país'),
          ),
          ...countries.map((country) => DropdownMenuItem<String>(
                value: country,
                child: Text(country),
              )),
        ],
        onChanged: (value) {
          _paisController.text = value ?? '';
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: TBColors.primary),
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }
}
