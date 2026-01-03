import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

class SalidaModal extends StatefulWidget {
  const SalidaModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SalidaModal(),
    );
  }

  @override
  State<SalidaModal> createState() => _SalidaModalState();
}

class _SalidaModalState extends State<SalidaModal> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  String selectedPaymentMethod = 'Efectivo';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Salida'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) return newValue;
                  final number = double.tryParse(newValue.text) ?? 0;
                  final formatted = NumberFormat('#,##0', 'es_CO').format(number.toInt());
                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }),
              ],
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                hintText: '1,000,000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Método de Pago',
                border: OutlineInputBorder(),
              ),
              items: ['Efectivo', 'Transferencia', 'Mixto']
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final cleanAmount = amountController.text.replaceAll(',', '').replaceAll('.', '');
            final amount = double.tryParse(cleanAmount) ?? 0;
            
            if (amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor ingresa un monto válido'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
            
            if (descriptionController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor ingresa una descripción'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
            
            try {
              // Aquí se implementará la lógica para registrar la salida
              // await ApiService.createSalida(...)
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Salida registrada exitosamente'),
                  backgroundColor: AppColors.success,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al registrar salida: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}