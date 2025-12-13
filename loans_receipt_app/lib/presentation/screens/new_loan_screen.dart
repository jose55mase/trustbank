import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/api_service.dart';
import '../../domain/models/user.dart';
import '../atoms/app_button.dart';
import '../widgets/app_drawer.dart';

class NewLoanScreen extends StatefulWidget {
  const NewLoanScreen({super.key});

  @override
  State<NewLoanScreen> createState() => _NewLoanScreenState();
}

class _NewLoanScreenState extends State<NewLoanScreen> {
  String? selectedUserId;
  String? paymentFrequency;
  String? loanType;
  final amountController = TextEditingController();
  final interestController = TextEditingController();
  final installmentsController = TextEditingController();
  final phoneController = TextEditingController();
  final numberFormat = NumberFormat('#,###', 'es_CO');
  List<User> users = [];
  bool isLoading = true;
  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    amountController.addListener(_formatAmount);
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    try {
      final fetchedUsers = await ApiService.getUsers();
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: ${e.toString()}')),
        );
      }
    }
  }

  void _formatAmount() {
    String text = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return;
    
    final value = int.parse(text);
    final formatted = numberFormat.format(value);
    
    final cursorPosition = formatted.length;
    amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
  
  Future<void> _createLoan() async {
    if (isLoading || users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando a cargar usuarios...')),
      );
      return;
    }
    
    if (selectedUserId == null || 
        amountController.text.isEmpty || 
        interestController.text.isEmpty || 
        installmentsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }
    
    setState(() {
      isCreating = true;
    });
    
    try {
      final amount = double.parse(amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      final interestRate = double.parse(interestController.text);
      final installments = int.parse(installmentsController.text);
      
      await ApiService.createLoan(
        userId: selectedUserId!,
        amount: amount,
        interestRate: interestRate,
        installments: installments,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préstamo creado exitosamente')),
        );
        Navigator.pop(context, true); // Retornar true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear préstamo: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isCreating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    amountController.removeListener(_formatAmount);
    amountController.dispose();
    interestController.dispose();
    installmentsController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Préstamo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Crear Nuevo Préstamo', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: selectedUserId,
            decoration: const InputDecoration(
              labelText: 'Seleccionar Usuario',
              border: OutlineInputBorder(),
            ),
            items: isLoading ? [] : users.map((user) {
              return DropdownMenuItem(
                value: user.id,
                child: Text('${user.userCode} - ${user.name}'),
              );
            }).toList(),
            onChanged: isLoading ? null : (value) => setState(() => selectedUserId = value),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Número de Teléfono',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto del Préstamo',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
              hintText: '0',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: interestController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            decoration: const InputDecoration(
              labelText: 'Tasa de Interés',
              suffixText: '%',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: installmentsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Número de Cuotas',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: paymentFrequency,
            decoration: const InputDecoration(
              labelText: 'Forma de Pago',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
              DropdownMenuItem(value: 'Quincenal', child: Text('Quincenal')),
            ],
            onChanged: (value) => setState(() => paymentFrequency = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: loanType,
            decoration: const InputDecoration(
              labelText: 'Tipo de Préstamo',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Fijo', child: Text('Fijo')),
              DropdownMenuItem(value: 'Rotativo', child: Text('Rotativo')),
            ],
            onChanged: (value) => setState(() => loanType = value),
          ),
          const SizedBox(height: 32),
          AppButton(
            text: isCreating ? 'Creando...' : 'Crear Préstamo',
            onPressed: isCreating ? null : _createLoan,
          ),
        ],
      ),
    );
  }
}
