import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';

class NewUserModal extends StatefulWidget {
  const NewUserModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const NewUserModal(),
    );
  }

  @override
  State<NewUserModal> createState() => _NewUserModalState();
}

class _NewUserModalState extends State<NewUserModal> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  String selectedPaymentMethod = 'Efectivo';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Usuario Nuevo'),
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
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : () async {
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

            setState(() => isLoading = true);

            try {
              // Agregar "Usuario Nuevo" al final de la descripción
              final finalDescription = '${descriptionController.text.trim()} - Usuario Nuevo';
              
              // Obtener el primer usuario disponible para crear el pago
              final users = await ApiService.getUsers();
              if (users.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No hay usuarios registrados en el sistema'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              // Usar el primer usuario disponible
              final firstUser = users.first;
              
              // Crear pago sin registrar
              await ApiService.createPayment(
                userId: firstUser.id,
                amount: amount,
                paymentMethod: selectedPaymentMethod,
                description: finalDescription,
                debtPayment: 0,
                interestPayment: amount, // Todo el monto como interés/ganancia
                salida: true, // Marcar como salida
              );
              
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pago registrado en "Sin Registrar"'),
                  backgroundColor: AppColors.success,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al registrar: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            } finally {
              setState(() => isLoading = false);
            }
          },
          child: Text(isLoading ? 'Registrando...' : 'Registrar'),
        ),
      ],
    );
  }
}