import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/dialog_utils.dart';
import '../atoms/app_button.dart';
import '../widgets/app_drawer.dart';
import '../../data/services/api_service.dart';
import 'new_loan_screen.dart';

class NewUserScreen extends StatefulWidget {
  const NewUserScreen({super.key});

  @override
  State<NewUserScreen> createState() => _NewUserScreenState();
}

class _NewUserScreenState extends State<NewUserScreen> {
  final nameController = TextEditingController();
  final userCodeController = TextEditingController();
  final phoneController = TextEditingController();
  final direccionController = TextEditingController();
  final referenceNameController = TextEditingController();
  final referencePhoneController = TextEditingController();
  DateTime? selectedDate;
  bool isLoading = false;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _registerUser() async {
    if (nameController.text.trim().isEmpty ||
        userCodeController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        direccionController.text.trim().isEmpty) {
      DialogUtils.showWarningDialog(context, 'Campos Incompletos', 'Por favor completa todos los campos antes de continuar.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ApiService.createUser(
        name: nameController.text.trim(),
        userCode: userCodeController.text.trim(),
        phone: phoneController.text.trim(),
        direccion: direccionController.text.trim(),
        referenceName: referenceNameController.text.trim().isNotEmpty ? referenceNameController.text.trim() : null,
        referencePhone: referencePhoneController.text.trim().isNotEmpty ? referencePhoneController.text.trim() : null,
        registrationDate: selectedDate,
      );

      if (mounted) {
        DialogUtils.showSuccessDialog(
          context, 
          '¡Usuario Creado!', 
          'El usuario ha sido registrado exitosamente. ¿Deseas registrar un préstamo ahora?',
          onClose: () {
            Navigator.pop(context); // Close dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewLoanScreen(),
              ),
            ).then((result) {
              // Cuando regrese de crear el préstamo, cerrar la pantalla de usuario
              if (result == true && mounted) {
                Navigator.pop(context, true);
              }
            });
          }
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Ocurrió un problema al registrar el usuario. Verifica los datos e intenta nuevamente.';
        
        // Extraer mensaje del error
        final errorString = e.toString();
        if (errorString.startsWith('Exception: ')) {
          errorMessage = errorString.substring('Exception: '.length);
        }
        
        DialogUtils.showErrorDialog(context, 'Error al Registrar', errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Usuario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Nuevo Usuario', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre Completo',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: userCodeController,
            decoration: const InputDecoration(
              labelText: 'Código de Usuario (ej: USR0001)',
              prefixIcon: Icon(Icons.tag),
              border: OutlineInputBorder(),
              hintText: 'USR0001',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: direccionController,
            keyboardType: TextInputType.streetAddress,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: referenceNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre Referencia (Opcional)',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: referencePhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono Referencia (Opcional)',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    selectedDate != null
                        ? 'Fecha de Registro: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Seleccionar Fecha de Registro (Opcional)',
                    style: TextStyle(
                      color: selectedDate != null ? Colors.black : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            text: isLoading ? 'Registrando...' : 'Registrar Usuario',
            onPressed: isLoading ? null : _registerUser,
          ),
        ],
      ),
    );
  }
}
