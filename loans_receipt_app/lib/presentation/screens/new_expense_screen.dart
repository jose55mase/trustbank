import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/expense_category.dart';
import '../../domain/models/expense_model.dart';
import '../../data/services/api_service.dart';
import '../widgets/app_drawer.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    // Convert to number and format
    int value = int.parse(digitsOnly);
    String formatted = NumberFormat('#,###', 'es_CO').format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({super.key});

  @override
  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final currencyFormatter = CurrencyInputFormatter();
  List<ExpenseCategory> _categories = [];
  ExpenseCategory? selectedCategory;
  DateTime selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await ApiService.getAllExpenseCategories();
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          selectedCategory = categories.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: $e')),
        );
      }
    }
  }
  
  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Text('Nuevo Gasto', style: AppTextStyles.h2),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Categoría
                          if (_categories.isNotEmpty)
                            DropdownButtonFormField<ExpenseCategory>(
                              value: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Categoría *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIconFromName(category.iconName),
                                        color: Color(int.parse('ff${category.colorValue}', radix: 16)),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(category.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => selectedCategory = value),
                              validator: (value) {
                                if (value == null) {
                                  return 'Selecciona una categoría';
                                }
                                return null;
                              },
                            )
                          else
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No hay categorías disponibles. Crea una categoría primero.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Monto
                          TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              currencyFormatter,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Monto *',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                              helperText: 'Ingresa el monto del gasto',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El monto es requerido';
                              }
                              final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                              final amount = double.tryParse(cleanValue);
                              if (amount == null || amount <= 0) {
                                return 'Ingresa un monto válido';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Descripción
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 3,
                            maxLength: 200,
                            decoration: const InputDecoration(
                              labelText: 'Descripción *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                              helperText: 'Describe el gasto realizado',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La descripción es requerida';
                              }
                              if (value.trim().length < 3) {
                                return 'La descripción debe tener al menos 3 caracteres';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Fecha
                          InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha del gasto',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(selectedDate),
                                    style: AppTextStyles.body,
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Resumen
                  if (selectedCategory != null && amountController.text.isNotEmpty)
                    Card(
                      color: AppColors.primary.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Resumen:', style: AppTextStyles.h3),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _getIconFromName(selectedCategory!.iconName),
                                  color: Color(int.parse('ff${selectedCategory!.colorValue}', radix: 16)),
                                ),
                                const SizedBox(width: 8),
                                Text(selectedCategory!.name, style: AppTextStyles.body),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Monto: ${NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO').format(double.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)}',
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving || _categories.isEmpty ? null : _saveExpense,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Guardar Gasto'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
  
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }
  
  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final cleanAmount = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      await ApiService.createExpense(
        categoryId: selectedCategory!.id!,
        amount: double.parse(cleanAmount),
        description: descriptionController.text.trim(),
        expenseDate: selectedDate,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gasto registrado exitosamente'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                // Navegar a la lista de gastos
              },
            ),
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar que se guardó
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar gasto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'directions_car': return Icons.directions_car;
      case 'movie': return Icons.movie;
      case 'medical_services': return Icons.medical_services;
      case 'home': return Icons.home;
      case 'school': return Icons.school;
      case 'build': return Icons.build;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'work': return Icons.work;
      case 'sports': return Icons.sports;
      case 'pets': return Icons.pets;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'coffee': return Icons.coffee;
      case 'flight': return Icons.flight;
      case 'hotel': return Icons.hotel;
      case 'phone': return Icons.phone;
      case 'wifi': return Icons.wifi;
      case 'electric_bolt': return Icons.electric_bolt;
      case 'water_drop': return Icons.water_drop;
      case 'savings': return Icons.savings;
      case 'credit_card': return Icons.credit_card;
      case 'account_balance': return Icons.account_balance;
      case 'attach_money': return Icons.attach_money;
      default: return Icons.category;
    }
  }
}