import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../domain/models/user.dart';
import '../widgets/app_drawer.dart';
import 'user_detail_screen.dart';
import 'new_user_screen.dart';

class UnregisteredPaymentsScreen extends StatefulWidget {
  const UnregisteredPaymentsScreen({super.key});

  @override
  State<UnregisteredPaymentsScreen> createState() => _UnregisteredPaymentsScreenState();
}

class _UnregisteredPaymentsScreenState extends State<UnregisteredPaymentsScreen> {
  List<dynamic> allPayments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllPayments();
  }

  Future<void> _loadAllPayments() async {
    try {
      final payments = await ApiService.getAllPayments();
      setState(() {
        allPayments = payments;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<dynamic> get unregisteredPayments => allPayments.where((p) => p['registered'] == false).toList();
  List<dynamic> get registeredPayments => allPayments.where((p) => p['registered'] == true).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entradas y Salidas'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      /*
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPaymentModal(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),*/
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Builder(
                builder: (context) {
                  final tabController = DefaultTabController.of(context);
                  tabController.addListener(() {
                    if (tabController.index == 1) {
                      // Tab "Registrados" seleccionado
                      _loadAllPayments();
                    }
                  });
                  return Column(
                children: [
                  const TabBar(
                    labelColor: AppColors.primary,
                    tabs: [
                      Tab(text: 'Sin Registrar'),
                      Tab(text: 'Registrados'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildUnregisteredTab(),
                        _buildRegisteredTab(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
            ),
    );
  }

  void _showAddPaymentModal(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPaymentMethod = 'Efectivo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Agregar Entrada/Salida'),
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
                      final number = int.tryParse(newValue.text) ?? 0;
                      final formatted = NumberFormat('#,###', 'es_CO').format(number);
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
                    labelText: 'Descripción (opcional)',
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
              onPressed: () {
                final cleanAmount = amountController.text.replaceAll(',', '');
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
                
                _addPayment(
                  amount: amount,
                  paymentMethod: selectedPaymentMethod,
                  description: descriptionController.text,
                );
                
                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _addPayment({
    required double amount,
    required String paymentMethod,
    required String description,
  }) {
    setState(() {
      unregisteredPayments.add({
        'amount': amount,
        'paymentMethod': paymentMethod,
        'description': description,
        'date': DateTime.now(),
      });
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entrada/Salida agregada'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildUnregisteredTab() {
    return unregisteredPayments.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.money_off_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay entradas/salidas sin registrar', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadAllPayments,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: unregisteredPayments.length,
              itemBuilder: (context, index) {
                final payment = unregisteredPayments[index];
                final userName = payment['user']?['name'] ?? 'Usuario desconocido';
                final amount = payment['amount']?.toDouble() ?? 0.0;
                final paymentDate = payment['paymentDate'] != null 
                    ? DateTime.parse(payment['paymentDate'])
                    : DateTime.now();
                
                // Debug logs
                
                return Stack(
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 12, top: 8),
                      child: ListTile(
                        onTap: () {
                          final hasUsuarioNuevo = payment['description']?.toString().contains('Usuario Nuevo') == true;
                          if (hasUsuarioNuevo) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NewUserScreen(),
                              ),
                            );
                          } else {
                            _navigateToUserDetail(payment['user']);
                          }
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          child: const Icon(Icons.money_off, color: Colors.orange),
                        ),
                        title: Column(
                          children: [
                            Builder(
                              builder: (context) {
                                final hasUsuarioNuevo = payment['description']?.toString().contains('Usuario Nuevo') == true;
                                return hasUsuarioNuevo
                                    ? const Text(
                                        'Usuario Nuevo',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Text(' $userName ');
                              },
                            ),
                            Row(
                              children: [
                                Text('${DateFormat('dd/MM/yyyy').format(paymentDate)} '),
                                Text('${DateFormat('HH:mm').format(paymentDate)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total: \$${NumberFormat('#,##0', 'es_CO').format(amount)}'),
                            if (!(payment['description']?.toString().contains('Usuario Nuevo') == true))
                              Row(
                                children: [
                                  Icon(
                                    (payment['debtPayment']?.toDouble() ?? 0.0) > 0 ? Icons.check_circle : Icons.cancel,
                                    size: 16,
                                    color: (payment['debtPayment']?.toDouble() ?? 0.0) > 0 ? AppColors.success : AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('Deuda: ${(payment['debtPayment']?.toDouble() ?? 0.0) > 0 ? "Sí" : "No"}'),
                                  const SizedBox(width: 16),
                                  Icon(
                                    (payment['interestPayment']?.toDouble() ?? 0.0) > 0 ? Icons.check_circle : Icons.cancel,
                                    size: 16,
                                    color: (payment['interestPayment']?.toDouble() ?? 0.0) > 0 ? AppColors.success : AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('Interés: ${(payment['interestPayment']?.toDouble() ?? 0.0) > 0 ? "Sí" : "No"}'),
                                ],
                              ),
                            Text('Método: ${payment['paymentMethod'] ?? 'N/A'}'),
                            if (payment['description'] != null && payment['description'].isNotEmpty)
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.black, fontSize: 14),
                                  children: [
                                    const TextSpan(text: 'Desc: '),
                                    if (payment['salida'] == true && payment['description'].toString().contains('Usuario Nuevo'))
                                      TextSpan(
                                        text: payment['description'],
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else
                                      TextSpan(text: payment['description']),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showConfirmationDialog(payment['id']),
                              icon: const Icon(Icons.check_circle_outline, size: 20),
                              color: AppColors.success,
                              tooltip: 'Marcar como registrado',
                            ),
                            IconButton(
                              onPressed: () => _showDeleteConfirmation(
                                payment['id'].toString(),
                                userName,
                                amount,
                              ),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: AppColors.error,
                              tooltip: 'Eliminar pago',
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${payment['user']?['userCode'] ?? 'N/A'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
  }

  Widget _buildRegisteredTab() {
    return registeredPayments.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay entradas/salidas registradas', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadAllPayments,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: registeredPayments.length,
              itemBuilder: (context, index) {
                final payment = registeredPayments[index];
                final userName = payment['user']?['name'] ?? 'Usuario desconocido';
                final amount = payment['amount']?.toDouble() ?? 0.0;
                final paymentDate = payment['paymentDate'] != null 
                    ? DateTime.parse(payment['paymentDate'])
                    : DateTime.now();
                
                return Stack(
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 12, top: 8),
                      child: ListTile(
                        onTap: () => _navigateToUserDetail(payment['user']),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.success.withOpacity(0.1),
                          child: const Icon(Icons.payment, color: AppColors.success),
                        ),
                        title: Text('\$${NumberFormat('#,##0', 'es_CO').format(amount)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total: \$${NumberFormat('#,##0', 'es_CO').format(amount)}'),
                            Row(
                              children: [
                                Icon(
                                  (payment['debtPayment']?.toDouble() ?? 0.0) > 0 ? Icons.check_circle : Icons.cancel,
                                  size: 16,
                                  color: (payment['debtPayment']?.toDouble() ?? 0.0) > 0 ? AppColors.success : AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text('Deuda: ${(payment['debtPayment']?.toDouble() ?? 0.0) > 0 ? "Sí" : "No"}'),
                                const SizedBox(width: 16),
                                Icon(
                                  (payment['interestPayment']?.toDouble() ?? 0.0) > 0 ? Icons.check_circle : Icons.cancel,
                                  size: 16,
                                  color: (payment['interestPayment']?.toDouble() ?? 0.0) > 0 ? AppColors.success : AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text('Interés: ${(payment['interestPayment']?.toDouble() ?? 0.0) > 0 ? "Sí" : "No"}'),
                              ],
                            ),
                            Text('Usuario: $userName'),
                            Text('Método: ${payment['paymentMethod'] ?? 'N/A'}'),
                            if (payment['description'] != null && payment['description'].isNotEmpty)
                              Text('Desc: ${payment['description']}'),
                            Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(paymentDate)}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () => _showDeleteConfirmation(
                                payment['id'].toString(),
                                userName,
                                amount,
                              ),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: AppColors.error,
                              tooltip: 'Eliminar pago',
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${payment['user']?['userCode'] ?? 'N/A'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
  }

  void _navigateToUserDetail(dynamic userData) {
    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información de usuario no disponible'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = User(
      id: userData['id']?.toString() ?? '0',
      name: userData['name'] ?? 'Usuario desconocido',
      userCode: userData['userCode'] ?? '',
      phone: userData['phone'] ?? '',
      direccion: userData['direccion'] ?? '',
      registrationDate: userData['registrationDate'] != null 
          ? DateTime.parse(userData['registrationDate'])
          : DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(user: user),
      ),
    );
  }

  void _showConfirmationDialog(int paymentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Registro'),
        content: const Text('¿Estás seguro de que deseas marcar este pago como registrado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAsRegistered(paymentId);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePayment(String paymentId) async {
    try {
      await ApiService.deletePayment(paymentId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago eliminado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      
      await _loadAllPayments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showDeleteConfirmation(String paymentId, String userName, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            const Text('Confirmar Eliminación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que deseas eliminar este pago?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: $paymentId', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Usuario: $userName'),
                  Text('Monto: \$${NumberFormat('#,##0', 'es_CO').format(amount)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePayment(paymentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _markAsRegistered(int paymentId) async {
    try {
      await ApiService.markPaymentAsRegistered(paymentId.toString());
      await _loadAllPayments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago marcado como registrado'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}