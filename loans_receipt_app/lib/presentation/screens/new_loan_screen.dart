import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/dummy_data.dart';
import '../atoms/app_button.dart';
import '../widgets/app_drawer.dart';

class NewLoanScreen extends StatefulWidget {
  const NewLoanScreen({super.key});

  @override
  State<NewLoanScreen> createState() => _NewLoanScreenState();
}

class _NewLoanScreenState extends State<NewLoanScreen> {
  String? selectedUserId;
  final amountController = TextEditingController();
  final interestController = TextEditingController();
  final installmentsController = TextEditingController();

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
            items: DummyData.users.map((user) {
              return DropdownMenuItem(
                value: user.id,
                child: Text(user.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedUserId = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto del Préstamo',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: interestController,
            keyboardType: TextInputType.number,
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
            decoration: const InputDecoration(
              labelText: 'Número de Cuotas',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Crear Préstamo',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Préstamo creado exitosamente')),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
