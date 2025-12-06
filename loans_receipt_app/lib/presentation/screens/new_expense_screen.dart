import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/expense.dart';
import '../atoms/app_button.dart';
import '../widgets/app_drawer.dart';

class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({super.key});

  @override
  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  ExpenseCategory selectedCategory = ExpenseCategory.food;
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Gasto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Nuevo Gasto', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          DropdownButtonFormField<ExpenseCategory>(
            value: selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
            items: ExpenseCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedCategory = value!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => selectedDate = picked);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text('Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Guardar Gasto',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gasto registrado exitosamente')),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
