import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

import '../../data/services/api_service.dart';
import '../../domain/models/expense_category.dart';
import '../../domain/models/expense_model.dart';
import '../widgets/app_drawer.dart';
import 'new_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String selectedPeriod = 'Día';
  List<ExpenseCategory> _categories = [];
  List<ExpenseModel> _expenses = [];
  bool _isLoadingCategories = true;
  bool _isLoadingExpenses = true;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadExpenses();
  }
  
  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await ApiService.getAllExpenseCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: $e')),
        );
      }
    }
  }
  
  Future<void> _loadExpenses() async {
    setState(() => _isLoadingExpenses = true);
    try {
      final expenses = await ApiService.getAllExpenses();
      setState(() {
        _expenses = expenses;
        _isLoadingExpenses = false;
      });
    } catch (e) {
      setState(() => _isLoadingExpenses = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar gastos: $e')),
        );
      }
    }
  }

  List<ExpenseModel> get filteredExpenses {
    final now = DateTime.now();
    
    if (selectedPeriod == 'Día') {
      // Mostrar gastos del día actual
      return _expenses.where((e) => 
        e.expenseDate.year == now.year && 
        e.expenseDate.month == now.month && 
        e.expenseDate.day == now.day
      ).toList();
    } else {
      // Mostrar gastos de toda la semana actual
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return _expenses.where((e) => 
        e.expenseDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        e.expenseDate.isBefore(now.add(const Duration(days: 1)))
      ).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = filteredExpenses;
    final totalExpenses = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');

    final expensesByCategory = <String, double>{};
    for (var expense in expenses) {
      expensesByCategory[expense.category.name] = (expensesByCategory[expense.category.name] ?? 0) + expense.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Diarios'),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Día', label: Text('Día')),
              ButtonSegment(value: 'Mes', label: Text('Mes')),
            ],
            selected: {selectedPeriod},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                selectedPeriod = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resumen de Gastos', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Gastado:', style: AppTextStyles.body),
                      Text(
                        currencyFormat.format(totalExpenses),
                        style: AppTextStyles.h2.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Gastos de Hoy - Movido a la parte superior
          Card(
            color: AppColors.primary.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Gastos de ${selectedPeriod == 'Día' ? 'Hoy' : 'esta Semana'}', style: AppTextStyles.h3),
                      TextButton.icon(
                        onPressed: _showExpensesModal,
                        icon: const Icon(Icons.visibility),
                        label: Text('Ver todos (${_expenses.length})'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (expenses.isEmpty)
                    Text(
                      'No hay gastos registrados ${selectedPeriod == 'Día' ? 'hoy' : 'esta semana'}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    )
                  else
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total ${selectedPeriod == 'Día' ? 'del día' : 'de la semana'}:', style: AppTextStyles.body),
                            Text(
                              currencyFormat.format(expenses.fold(0.0, (sum, e) => sum + e.amount)),
                              style: AppTextStyles.h2.copyWith(color: AppColors.error),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${expenses.length} gasto${expenses.length != 1 ? 's' : ''} registrado${expenses.length != 1 ? 's' : ''}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          if (expensesByCategory.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gráfica de Gastos - $selectedPeriod', style: AppTextStyles.h3),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: expensesByCategory.entries.map((entry) {
                            return PieChartSectionData(
                              value: entry.value,
                              title: '${((entry.value / totalExpenses) * 100).toStringAsFixed(0)}%',
                              color: _getCategoryColor(entry.key),
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay datos para mostrar gráfica',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Por Categoría', style: AppTextStyles.h3),
              IconButton(
                onPressed: _showAddCategoryModal,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Agregar Categoría',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (expensesByCategory.isNotEmpty)
            ...expensesByCategory.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(entry.key).withOpacity(0.1),
                    child: Icon(_getCategoryIcon(entry.key), color: _getCategoryColor(entry.key)),
                  ),
                  title: Text(entry.key),
                  trailing: Text(
                    currencyFormat.format(entry.value),
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            })
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay gastos por categoría',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_categories.isNotEmpty) ...[
            const Text('Categorías Disponibles', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(int.parse('ff${category.colorValue}', radix: 16)).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(int.parse('ff${category.colorValue}', radix: 16)),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getIconFromName(category.iconName),
                            color: Color(int.parse('ff${category.colorValue}', radix: 16)),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            category.name,
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewExpenseScreen()),
          );
          if (result == true) {
            _loadExpenses(); // Recargar gastos si se creó uno nuevo
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar Gasto'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Comida':
        return Icons.restaurant;
      case 'Ropa':
        return Icons.shopping_bag;
      case 'Transporte':
        return Icons.directions_car;
      case 'Entretenimiento':
        return Icons.movie;
      case 'Salud':
        return Icons.medical_services;
      default:
        return Icons.attach_money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Comida':
        return Colors.orange;
      case 'Ropa':
        return Colors.purple;
      case 'Transporte':
        return Colors.blue;
      case 'Entretenimiento':
        return Colors.pink;
      case 'Salud':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showAddCategoryModal() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    IconData selectedIcon = Icons.category;
    Color selectedColor = AppColors.primary;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_circle, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Nueva Categoría', style: AppTextStyles.h2),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la categoría',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Icono:', style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Icons.category,
                      Icons.shopping_cart,
                      Icons.restaurant,
                      Icons.shopping_bag,
                      Icons.directions_car,
                      Icons.movie,
                      Icons.medical_services,
                      Icons.home,
                      Icons.work,
                      Icons.school,
                      Icons.sports,
                      Icons.pets,
                      Icons.local_gas_station,
                      Icons.coffee,
                      Icons.flight,
                      Icons.hotel,
                      Icons.phone,
                      Icons.wifi,
                      Icons.electric_bolt,
                      Icons.water_drop,
                      Icons.savings,
                      Icons.credit_card,
                      Icons.account_balance,
                      Icons.attach_money,
                    ].map((icon) => GestureDetector(
                      onTap: () => setModalState(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedIcon == icon ? AppColors.primary.withOpacity(0.2) : null,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedIcon == icon ? AppColors.primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Icon(icon, color: selectedIcon == icon ? AppColors.primary : Colors.grey),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color:', style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.red,
                      Colors.teal,
                      Colors.indigo,
                      Colors.brown,
                    ].map((color) => GestureDetector(
                      onTap: () => setModalState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selectedColor == color ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                await ApiService.createExpenseCategory(
                                  name: nameController.text.trim(),
                                  iconName: _getIconName(selectedIcon),
                                  colorValue: _getColorValue(selectedColor),
                                );
                                if (mounted) {
                                  Navigator.pop(context);
                                  _loadCategories();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Categoría "${nameController.text.trim()}" creada'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al crear categoría: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: const Text('Crear'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showExpensesModal() {
    showDialog(
      context: context,
      builder: (context) => _ExpensesModalWidget(
        onExpenseUpdated: () {
          _loadExpenses(); // Recargar gastos en la pantalla principal
        },
      ),
    );
  }

  String _getIconName(IconData icon) {
    if (icon == Icons.category) return 'category';
    if (icon == Icons.shopping_cart) return 'shopping_cart';
    if (icon == Icons.restaurant) return 'restaurant';
    if (icon == Icons.shopping_bag) return 'shopping_bag';
    if (icon == Icons.directions_car) return 'directions_car';
    if (icon == Icons.movie) return 'movie';
    if (icon == Icons.medical_services) return 'medical_services';
    if (icon == Icons.home) return 'home';
    if (icon == Icons.work) return 'work';
    if (icon == Icons.school) return 'school';
    if (icon == Icons.sports) return 'sports';
    if (icon == Icons.pets) return 'pets';
    if (icon == Icons.local_gas_station) return 'local_gas_station';
    if (icon == Icons.coffee) return 'coffee';
    if (icon == Icons.flight) return 'flight';
    if (icon == Icons.hotel) return 'hotel';
    if (icon == Icons.phone) return 'phone';
    if (icon == Icons.wifi) return 'wifi';
    if (icon == Icons.electric_bolt) return 'electric_bolt';
    if (icon == Icons.water_drop) return 'water_drop';
    if (icon == Icons.savings) return 'savings';
    if (icon == Icons.credit_card) return 'credit_card';
    if (icon == Icons.account_balance) return 'account_balance';
    if (icon == Icons.attach_money) return 'attach_money';
    return 'category';
  }
  
  String _getColorValue(Color color) {
    return color.value.toRadixString(16);
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

class _ExpensesModalWidget extends StatefulWidget {
  final VoidCallback? onExpenseUpdated;
  
  const _ExpensesModalWidget({this.onExpenseUpdated});
  
  @override
  _ExpensesModalWidgetState createState() => _ExpensesModalWidgetState();
}

class _ExpensesModalWidgetState extends State<_ExpensesModalWidget> {
  String selectedFilter = 'Hoy';
  List<ExpenseModel> filteredModalExpenses = [];
  bool isLoadingModal = true;
  int currentPage = 0;
  final int itemsPerPage = 10;
  
  @override
  void initState() {
    super.initState();
    loadFilteredExpenses();
  }
  
  Future<void> loadFilteredExpenses() async {
    setState(() => isLoadingModal = true);
    try {
      List<ExpenseModel> expenses;
      final now = DateTime.now();
      
      print('Loading expenses for filter: $selectedFilter');
      
      switch (selectedFilter) {
        case 'Hoy':
          final startOfDay = DateTime(now.year, now.month, now.day);
          final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          print('Date range for today: $startOfDay to $endOfDay');
          expenses = await ApiService.getExpensesByDateRange(
            startDate: startOfDay,
            endDate: endOfDay,
          );
          break;
        case 'Semana':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          final endDate = now;
          print('Date range for week: $startDate to $endDate');
          expenses = await ApiService.getExpensesByDateRange(
            startDate: startDate,
            endDate: endDate,
          );
          break;
        case 'Mes':
          final startOfMonth = DateTime(now.year, now.month, 1);
          final endDate = now;
          print('Date range for month: $startOfMonth to $endDate');
          expenses = await ApiService.getExpensesByDateRange(
            startDate: startOfMonth,
            endDate: endDate,
          );
          break;
        default:
          print('Getting all expenses');
          expenses = await ApiService.getAllExpenses();
      }
      
      print('Found ${expenses.length} expenses');
      
      setState(() {
        filteredModalExpenses = expenses;
        currentPage = 0;
        isLoadingModal = false;
      });
    } catch (e) {
      print('Error loading expenses: $e');
      setState(() => isLoadingModal = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Gastos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Selector de rango de fechas
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: DateTimeRange(
                                start: DateTime.now().subtract(const Duration(days: 7)),
                                end: DateTime.now(),
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedFilter = 'Rango personalizado';
                                isLoadingModal = true;
                              });
                              
                              // Cargar gastos del rango seleccionado
                              try {
                                final endOfDay = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
                                final expenses = await ApiService.getExpensesByDateRange(
                                  startDate: picked.start,
                                  endDate: endOfDay,
                                );
                                setState(() {
                                  filteredModalExpenses = expenses;
                                  currentPage = 0;
                                  isLoadingModal = false;
                                });
                              } catch (e) {
                                setState(() => isLoadingModal = false);
                              }
                            }
                          },
                          icon: const Icon(Icons.date_range),
                          label: const Text('Seleccionar rango'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() => selectedFilter = 'Hoy');
                          loadFilteredExpenses();
                        },
                        icon: const Icon(Icons.today),
                        label: const Text('Hoy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => selectedFilter = 'Semana');
                            loadFilteredExpenses();
                          },
                          child: const Text('Esta semana'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => selectedFilter = 'Mes');
                            loadFilteredExpenses();
                          },
                          child: const Text('Este mes'),
                        ),
                      ),
                    ],
                  ),
                  if (selectedFilter != 'Hoy' && selectedFilter != 'Semana' && selectedFilter != 'Mes')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Rango personalizado seleccionado',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
            
            Expanded(
              child: isLoadingModal
                  ? const Center(child: CircularProgressIndicator())
                  : filteredModalExpenses.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay gastos en el período seleccionado',
                            style: AppTextStyles.body,
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _getCurrentPageItems().length,
                                itemBuilder: (context, index) {
                                  final expense = _getCurrentPageItems()[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Color(int.parse('ff${expense.category.colorValue}', radix: 16)).withOpacity(0.1),
                                        child: Icon(
                                          _getIconFromName(expense.category.iconName),
                                          color: Color(int.parse('ff${expense.category.colorValue}', radix: 16)),
                                        ),
                                      ),
                                      title: Text(expense.description),
                                      subtitle: Text(
                                        '${expense.category.name} • ${DateFormat('dd/MM/yyyy HH:mm').format(expense.expenseDate)}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO').format(expense.amount),
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.error,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => _showEditExpenseModal(expense),
                                            icon: const Icon(Icons.edit, size: 20),
                                            tooltip: 'Editar gasto',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_getTotalPages() > 1) _buildPagination(),
                          ],
                        ),
            ),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total ($selectedFilter): ${filteredModalExpenses.length} gastos', style: AppTextStyles.h3),
                  Text(
                    NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO')
                        .format(filteredModalExpenses.fold(0.0, (sum, e) => sum + e.amount)),
                    style: AppTextStyles.h2.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
  
  List<ExpenseModel> _getCurrentPageItems() {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredModalExpenses.length);
    return filteredModalExpenses.sublist(startIndex, endIndex);
  }
  
  int _getTotalPages() {
    return (filteredModalExpenses.length / itemsPerPage).ceil();
  }
  
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            'Página ${currentPage + 1} de ${_getTotalPages()}',
            style: AppTextStyles.body,
          ),
          IconButton(
            onPressed: currentPage < _getTotalPages() - 1 ? () => setState(() => currentPage++) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
  
  void _showEditExpenseModal(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => _EditExpenseModal(
        expense: expense,
        onExpenseUpdated: () {
          loadFilteredExpenses();
          if (widget.onExpenseUpdated != null) {
            widget.onExpenseUpdated!();
          }
        },
      ),
    );
  }
}

class _EditExpenseModal extends StatefulWidget {
  final ExpenseModel expense;
  final VoidCallback onExpenseUpdated;
  
  const _EditExpenseModal({
    required this.expense,
    required this.onExpenseUpdated,
  });
  
  @override
  _EditExpenseModalState createState() => _EditExpenseModalState();
}

class _EditExpenseModalState extends State<_EditExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<ExpenseCategory> _categories = [];
  ExpenseCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadCategories();
  }
  
  void _initializeFields() {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0, locale: 'es_CO');
    _amountController.text = formatter.format(widget.expense.amount);
    _descriptionController.text = widget.expense.description;
    _selectedDate = widget.expense.expenseDate;
  }
  
  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.getAllExpenseCategories();
      setState(() {
        _categories = categories;
        // Buscar la categoría correspondiente por ID
        _selectedCategory = categories.firstWhere(
          (cat) => cat.id == widget.expense.category.id,
          orElse: () => categories.isNotEmpty ? categories.first : widget.expense.category,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Editar Gasto', style: AppTextStyles.h2),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              DropdownButtonFormField<ExpenseCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
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
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto (COP)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  _CurrencyInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El monto es requerido';
                  }
                  final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (numericValue.isEmpty || int.parse(numericValue) <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es requerida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDate),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate)}',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _deleteExpense,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateExpense,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Actualizar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final numericAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      await ApiService.updateExpense(
        expenseId: widget.expense.id ?? 0,
        categoryId: _selectedCategory!.id ?? 0,
        amount: double.parse(numericAmount),
        description: _descriptionController.text.trim(),
        expenseDate: _selectedDate,
      );
      
      if (mounted) {
        Navigator.pop(context);
        widget.onExpenseUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar gasto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _deleteExpense() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: const Text('¿Estás seguro de que deseas eliminar este gasto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await ApiService.deleteExpense(widget.expense.id ?? 0);
      
      if (mounted) {
        Navigator.pop(context);
        widget.onExpenseUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar gasto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final numericValue = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericValue.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0, locale: 'es_CO');
    final formattedValue = formatter.format(int.parse(numericValue));

    return newValue.copyWith(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}