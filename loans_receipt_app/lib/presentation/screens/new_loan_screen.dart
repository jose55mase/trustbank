import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/dialog_utils.dart';
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
  String? paymentFrequency = 'Mensual 30';
  String? loanType;
  DateTime? selectedDate;
  final amountController = TextEditingController();
  final interestController = TextEditingController();
  final installmentsController = TextEditingController();
  final phoneController = TextEditingController();
  final valorRealCuotaController = TextEditingController();
  final capitalController = TextEditingController();
  bool capitalFijo = false;
  final numberFormat = NumberFormat('#,###', 'es_CO');
  List<User> users = [];
  bool isLoading = true;
  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    amountController.addListener(_formatAmount);
    amountController.addListener(_calculateValorRealCuota);
    interestController.addListener(_calculateValorRealCuota);
    valorRealCuotaController.addListener(_formatValorRealCuota);
    capitalController.addListener(_formatCapital);
    installmentsController.addListener(() {
      setState(() {});
      _calculateValorRealCuota();
    });
    _loadUsers();
  }
  


  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        // Forzar recálculo de fechas de pago
      });
    }
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
        DialogUtils.showErrorDialog(context, 'Error de Conexión', 'No se pudieron cargar los usuarios. Verifica tu conexión e intenta nuevamente.');
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
  
  void _formatValorRealCuota() {
    String text = valorRealCuotaController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return;
    
    final value = int.parse(text);
    final formatted = '\$ ${numberFormat.format(value)}';
    
    valorRealCuotaController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
  
  void _formatCapital() {
    String text = capitalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return;
    
    final value = int.parse(text);
    final formatted = numberFormat.format(value);
    
    final cursorPosition = formatted.length;
    capitalController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
  
  void _calculateValorRealCuota() {
    final amountText = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final interestText = interestController.text;
    final installmentsText = installmentsController.text;
    
    // Si está marcado "capital fijo", calcular sin interés
    if (capitalFijo) {
      if (amountText.isEmpty || installmentsText.isEmpty) {
        valorRealCuotaController.clear();
        return;
      }
      final amount = double.parse(amountText);
      final installments = int.parse(installmentsText);
      final valorRealCuota = amount / installments;
      final formatted = '\$ ${numberFormat.format(valorRealCuota.round())}';
      valorRealCuotaController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      return;
    }
    
    if (amountText.isEmpty || interestText.isEmpty || installmentsText.isEmpty || loanType == null) {
      valorRealCuotaController.clear();
      return;
    }
    
    final amount = double.parse(amountText);
    final interestRate = double.parse(interestText);
    final installments = int.parse(installmentsText);
    
    double valorRealCuota = 0.0;
    
    switch (loanType) {
      case 'Fijo':
        // Para préstamos fijos: capital por cuota + interés por cuota
        final capitalPorCuota = amount / installments;
        final interesPorCuota = amount * interestRate / 100;
        valorRealCuota = capitalPorCuota + interesPorCuota;
        break;
      case 'Rotativo':
        // Para préstamos rotativos: similar al fijo pero se recalcula con el saldo restante
        final capitalPorCuota = amount / installments;
        final interesPorCuota = amount * interestRate / 100;
        valorRealCuota = capitalPorCuota + interesPorCuota;
        break;
      case 'Ahorro':
      default:
        // Para otros tipos: total con interés dividido entre cuotas
        final totalWithInterest = amount + (amount * interestRate / 100);
        valorRealCuota = totalWithInterest / installments;
        break;
    }
    
    final formatted = '\$ ${numberFormat.format(valorRealCuota.round())}';
    valorRealCuotaController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
  
  List<DateTime> _calculatePaymentDates() {
    if (paymentFrequency == null || installmentsController.text.isEmpty) return [];
    
    final installments = int.tryParse(installmentsController.text) ?? 0;
    if (installments <= 0) return [];
    
    List<DateTime> dates = [];
    DateTime loanDate = selectedDate ?? DateTime.now(); // Usar fecha seleccionada o actual
    DateTime firstPaymentDate;
    
    switch (paymentFrequency) {
      case 'Mensual 15':
        // Primera fecha: 15 del mes siguiente al mes del préstamo
        firstPaymentDate = DateTime(loanDate.year, loanDate.month + 1, 15);
        if (firstPaymentDate.month != loanDate.month + 1) {
          firstPaymentDate = DateTime(loanDate.year, loanDate.month + 2, 0); // Último día del mes
        }
        for (int i = 0; i < installments; i++) {
          DateTime paymentDate = DateTime(firstPaymentDate.year, firstPaymentDate.month + i, 15);
          if (paymentDate.month != firstPaymentDate.month + i) {
            paymentDate = DateTime(firstPaymentDate.year, firstPaymentDate.month + i + 1, 0);
          }
          dates.add(paymentDate);
        }
        break;
        
      case 'Mensual 30':
        // Primera fecha: 1 del segundo mes siguiente al préstamo
        firstPaymentDate = DateTime(loanDate.year, loanDate.month + 2, 1);
        for (int i = 0; i < installments; i++) {
          DateTime paymentDate = DateTime(firstPaymentDate.year, firstPaymentDate.month + i, 1);
          dates.add(paymentDate);
        }
        break;
        
      case 'Quincenal':
        // Alternar entre día 15 y día 1 de cada mes
        DateTime currentDate = loanDate;
        for (int i = 0; i < installments; i++) {
          DateTime nextPayment;
          if (i % 2 == 0) {
            // Pago en día 15
            if (currentDate.day <= 15) {
              nextPayment = DateTime(currentDate.year, currentDate.month, 15);
            } else {
              nextPayment = DateTime(currentDate.year, currentDate.month + 1, 15);
            }
          } else {
            // Pago en día 1 del siguiente mes
            nextPayment = DateTime(currentDate.year, currentDate.month + 1, 1);
          }
          dates.add(nextPayment);
          currentDate = nextPayment;
        }
        break;
        
      case 'Quincenal 5':
        // Alternar entre día 5 y 20 de cada mes
        DateTime currentDate = loanDate;
        for (int i = 0; i < installments; i++) {
          DateTime nextPayment;
          if (i % 2 == 0) {
            // Pago en día 5
            if (currentDate.day <= 5) {
              nextPayment = DateTime(currentDate.year, currentDate.month, 5);
            } else {
              nextPayment = DateTime(currentDate.year, currentDate.month + 1, 5);
            }
          } else {
            // Pago en día 20
            if (currentDate.day <= 20) {
              nextPayment = DateTime(currentDate.year, currentDate.month, 20);
            } else {
              nextPayment = DateTime(currentDate.year, currentDate.month + 1, 20);
            }
          }
          dates.add(nextPayment);
          currentDate = nextPayment;
        }
        break;
        
      case 'Quincenal 20':
        // Alternar entre día 20 y 5 de cada mes
        DateTime currentDate = loanDate;
        for (int i = 0; i < installments; i++) {
          DateTime nextPayment;
          if (i % 2 == 0) {
            // Pago en día 20
            if (currentDate.day <= 20) {
              nextPayment = DateTime(currentDate.year, currentDate.month, 20);
            } else {
              nextPayment = DateTime(currentDate.year, currentDate.month + 1, 20);
            }
          } else {
            // Pago en día 5 del siguiente mes
            nextPayment = DateTime(currentDate.year, currentDate.month + 1, 5);
          }
          dates.add(nextPayment);
          currentDate = nextPayment;
        }
        break;
        
      case 'Semanal':
        // Primera fecha: 7 días después del préstamo (mismo día de la semana)
        firstPaymentDate = loanDate.add(const Duration(days: 7));
        for (int i = 0; i < installments; i++) {
          DateTime paymentDate = firstPaymentDate.add(Duration(days: 7 * i));
          dates.add(paymentDate);
        }
        break;
        
      default:
        break;
    }
    
    // Validar que la primera fecha de pago cumpla con el rango mínimo
    if (dates.isNotEmpty) {
      _validatePaymentDates(dates.first, loanDate);
    }
    
    return dates;
  }
  
  void _validatePaymentDates(DateTime firstPayment, DateTime loanDate) {
    final daysDifference = firstPayment.difference(loanDate).inDays;
    
    String? alertMessage;
    
    switch (paymentFrequency) {
      case 'Mensual 15':
      case 'Mensual 30':
        if (daysDifference < 30) {
          alertMessage = 'Alerta: La primera fecha de pago es menor a 30 días. Fecha: ${DateFormat('dd/MM/yyyy').format(firstPayment)}';
        }
        break;
      case 'Quincenal':
        if (daysDifference < 15) {
          alertMessage = 'Alerta: La primera fecha de pago es menor a 15 días. Fecha: ${DateFormat('dd/MM/yyyy').format(firstPayment)}';
        }
        break;
      case 'Quincenal 5':
      case 'Quincenal 20':
        if (daysDifference < 15) {
          alertMessage = 'Alerta: La primera fecha de pago es menor a 15 días. Fecha: ${DateFormat('dd/MM/yyyy').format(firstPayment)}';
        }
        break;
      case 'Semanal':
        if (daysDifference < 7) {
          alertMessage = 'Alerta: La primera fecha de pago es menor a 7 días. Fecha: ${DateFormat('dd/MM/yyyy').format(firstPayment)}';
        }
        break;
    }
    
    if (alertMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          DialogUtils.showWarningDialog(context, 'Validación de Fechas', alertMessage!);
        }
      });
    }
  }
  
  String _getLoanTypeRule(String loanType) {
    switch (loanType) {
      case 'Fijo':
        return 'Préstamo Fijo: Forma de pago fija en Mensual 30 (pago el día 1 de cada mes)';
      case 'Ahorro':
        return 'Préstamo Ahorro: Forma de pago fija en Mensual 15 (pago el día 15 de cada mes)';
      case 'Rotativo':
        return 'Préstamo Rotativo: Puedes elegir cualquier forma de pago disponible';
      default:
        return '';
    }
  }
  
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'Lunes';
      case 2: return 'Martes';
      case 3: return 'Miércoles';
      case 4: return 'Jueves';
      case 5: return 'Viernes';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return '';
    }
  }
  
  Widget _buildPaymentDatesWidget() {
    if (paymentFrequency == null || installmentsController.text.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final dates = _calculatePaymentDates();
    if (dates.isEmpty) return const SizedBox.shrink();
    
    final loanDate = selectedDate ?? DateTime.now();
    
    Color color;
    String title;
    
    switch (paymentFrequency!) {
      case 'Mensual 15':
        color = Colors.blue;
        title = 'Fechas de Pago (Mensual 15):';
        break;
      case 'Mensual 30':
        color = Colors.green;
        title = 'Fechas de Pago (Mensual 30 - Día 1):';
        break;
      case 'Quincenal':
        color = Colors.purple;
        title = 'Fechas de Pago (Quincenal - Alterna 15 y 1):';
        break;
      case 'Quincenal 5':
        color = Colors.teal;
        title = 'Fechas de Pago (Quincenal 5 - Alterna 5 y 20):';
        break;
      case 'Quincenal 20':
        color = Colors.indigo;
        title = 'Fechas de Pago (Quincenal 20 - Alterna 20 y 5):';
        break;
      case 'Semanal':
        color = Colors.red;
        title = 'Fechas de Pago (Semanal - ${_getWeekdayName(loanDate.weekday)}):';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          ...(dates.take(5).map((date) {
            if (paymentFrequency == 'Semanal') {
              return Text('• ${DateFormat('dd/MM/yyyy').format(date)} (${_getWeekdayName(date.weekday)})');
            }
            return Text('• ${DateFormat('dd/MM/yyyy').format(date)}');
          })),
          if (dates.length > 5)
            Text('... y ${dates.length - 5} fechas más'),
        ],
      ),
    );
  }
  
  Future<void> _createLoan() async {
    if (isLoading || users.isEmpty) {
      DialogUtils.showWarningDialog(context, 'Cargando Datos', 'Esperando a cargar usuarios. Intenta nuevamente en un momento.');
      return;
    }
    
    // Validación: todos los campos requeridos
    if (selectedUserId == null || 
        amountController.text.isEmpty || 
        interestController.text.isEmpty || 
        installmentsController.text.isEmpty ||
        loanType == null ||
        paymentFrequency == null) {
      DialogUtils.showWarningDialog(context, 'Campos Incompletos', 'Por favor completa todos los campos marcados con asterisco (*) antes de continuar.');
      return;
    }
    
    setState(() {
      isCreating = true;
    });
    
    try {
      final amount = double.parse(amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      final interestRate = double.parse(interestController.text);
      final installments = int.parse(installmentsController.text);
      
      // Obtener el valor real de cuota calculado
      final valorRealCuotaText = valorRealCuotaController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final valorRealCuota = valorRealCuotaText.isNotEmpty ? double.parse(valorRealCuotaText) : null;
      
      // Obtener el capital
      final capitalText = capitalController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final capital = capitalText.isNotEmpty ? double.parse(capitalText) : null;
      
      print('========== CREANDO PRÉSTAMO ==========');
      print('capitalFijo (checkbox): $capitalFijo');
      print('amount: $amount');
      print('interestRate: $interestRate');
      print('installments: $installments');
      print('loanType: $loanType');
      print('paymentFrequency: $paymentFrequency');
      print('valorRealCuota: $valorRealCuota');
      print('sinCuotas (enviando al backend): $capitalFijo');
      print('======================================');
      
      await ApiService.createLoan(
        userId: selectedUserId!,
        amount: amount,
        interestRate: interestRate,
        installments: installments,
        loanType: loanType,
        paymentFrequency: paymentFrequency,
        startDate: selectedDate,
        valorRealCuota: valorRealCuota,
        capital: capital,
        sinCuotas: capitalFijo,
      );
      
      if (mounted) {
        DialogUtils.showSuccessDialog(context, '¡Éxito!', 'El préstamo ha sido creado exitosamente y está listo para ser utilizado.', onClose: () => Navigator.pop(context, true));
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(context, 'Error al Crear Préstamo', 'Ocurrió un problema al procesar la solicitud. Verifica los datos e intenta nuevamente.');
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
    amountController.removeListener(_calculateValorRealCuota);
    interestController.removeListener(_calculateValorRealCuota);
    valorRealCuotaController.removeListener(_formatValorRealCuota);
    capitalController.removeListener(_formatCapital);
    amountController.dispose();
    interestController.dispose();
    installmentsController.dispose();
    phoneController.dispose();
    valorRealCuotaController.dispose();
    capitalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Préstamooo'),
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
              labelText: 'Seleccionar Usuario *',
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
          /*TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Número de Teléfono',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),*/
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto del Préstamo *',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
              hintText: '0',
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Capital Fijo'),
            subtitle: const Text('Marcar si el préstamo no aplica tasa de interés (solo capital)'),
            value: capitalFijo,
            onChanged: (value) {
              setState(() {
                capitalFijo = value ?? false;
                _calculateValorRealCuota();
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: interestController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            decoration: const InputDecoration(
              labelText: 'Tasa de Interés *',
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
              labelText: 'Número de Cuotas *',
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
                        ? 'Fecha de Creación: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Seleccionar Fecha de Creación (Opcional)',
                    style: TextStyle(
                      color: selectedDate != null ? Colors.black : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: loanType,
            decoration: const InputDecoration(
              labelText: 'Tipo de Préstamo *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Fijo', child: Text('Fijo')),
              DropdownMenuItem(value: 'Rotativo', child: Text('Rotativo')),
              DropdownMenuItem(value: 'Ahorro', child: Text('Ahorro')),
            ],
            onChanged: (value) {
              setState(() {
                loanType = value;
                // Aplicar reglas específicas para cada tipo de préstamo
                if (value == 'Fijo') {
                  paymentFrequency = 'Mensual 30';
                } else if (value == 'Ahorro') {
                  paymentFrequency = 'Mensual 15';
                }
                // Rotativo mantiene la selección libre
                _calculateValorRealCuota();
              });
            },
          ),
          if (loanType != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getLoanTypeRule(loanType!),
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: paymentFrequency,
            decoration: InputDecoration(
              labelText: 'Forma de Pago *',
              border: const OutlineInputBorder(),
              enabled: loanType == null || loanType == 'Rotativo',
            ),
            items: const [
              DropdownMenuItem(value: 'Mensual 15', child: Text('Mensual 15')),
              DropdownMenuItem(value: 'Mensual 30', child: Text('Mensual 30')),
              DropdownMenuItem(value: 'Quincenal', child: Text('Quincenal')),
              DropdownMenuItem(value: 'Quincenal 5', child: Text('Quincenal 5')),
              DropdownMenuItem(value: 'Quincenal 20', child: Text('Quincenal 20')),
              DropdownMenuItem(value: 'Semanal', child: Text('Semanal')),
            ],
            onChanged: (loanType == null || loanType == 'Rotativo') ? (value) {
              setState(() {
                paymentFrequency = value;
              });
            } : null,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: valorRealCuotaController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Valor Real Cuota',
              border: const OutlineInputBorder(),
              helperText: 'Valor real de cada cuota (se calcula automáticamente)',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: _calculateValorRealCuota,
                    tooltip: 'Recalcular automáticamente',
                  ),
                  const Icon(Icons.edit, color: Colors.orange),
                ],
              ),
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          _buildPaymentDatesWidget(),
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
