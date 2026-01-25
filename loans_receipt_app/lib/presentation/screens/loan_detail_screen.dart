import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/loan_status.dart';
import '../../domain/models/user.dart';

import '../../data/services/api_service.dart';
import '../atoms/status_badge.dart';
import '../atoms/info_row.dart';
import '../widgets/app_drawer.dart';
import '../widgets/navigation_actions.dart';

class LoanDetailScreen extends StatefulWidget {
  final Loan loan;
  final User user;

  const LoanDetailScreen({super.key, required this.loan, required this.user});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  late Loan currentLoan;
  Map<String, dynamic>? lastCapitalPayment;

  @override
  void initState() {
    super.initState();
    currentLoan = widget.loan;
    _loadLastCapitalPayment();
  }
  
  Future<void> _loadLastCapitalPayment() async {
    try {
      final payment = await ApiService.getLastCapitalPayment(currentLoan.id);
      setState(() {
        lastCapitalPayment = payment;
      });
    } catch (e) {
      print('Error loading last capital payment: $e');
    }
  }
  
  Future<Map<String, dynamic>?> _loadPreviousPayment(String loanId) async {
    try {
      final transactions = await ApiService.getTransactionsByLoanId(loanId);
      if (transactions.isNotEmpty) {
        // Filtrar transacciones con principalAmount > 0 y ordenar por fecha descendente
        final capitalTransactions = transactions
            .where((t) => t['principalAmount'] != null && (t['principalAmount'] as num) > 0)
            .toList();
        
        if (capitalTransactions.isNotEmpty) {
          capitalTransactions.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
          return capitalTransactions.first;
        }
      }
    } catch (e) {
      print('Error loading previous payment: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('\$ #,###', 'es_CO');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Préstamooo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Regresar',
          ),
          NavigationActions(
            additionalActions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(context),
                tooltip: 'Editar Préstamo',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(context),
                tooltip: 'Eliminar Préstamo',
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.user.name, style: AppTextStyles.h2),
                      StatusBadge(status: currentLoan.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('ID: ${currentLoan.id}', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Información del Préstamo', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  InfoRow(label: 'Monto Prestado', value: currencyFormat.format(currentLoan.amount)),
                  InfoRow(label: 'Tasa de Interés', value: '${currentLoan.interestRate}%'),
                  InfoRow(
                    label: 'Ganancia',
                    value: currencyFormat.format(currentLoan.profit),
                    valueColor: AppColors.secondary,
                  ),
                  InfoRow(
                    label: 'Total a Pagar',
                    value: currencyFormat.format(currentLoan.totalAmount),
                    valueColor: AppColors.primary,
                  ),
                  const Divider(height: 24),
                  InfoRow(label: 'Forma de Pago', value: currentLoan.paymentFrequency ?? 'No especificado'),
                  InfoRow(label: 'Tipo de Préstamo', value: currentLoan.loanType ?? 'No especificado'),
                  const Divider(height: 24),
                  InfoRow(label: 'Cuotas Totales', value: '${currentLoan.installments}'),
                  InfoRow(label: 'Cuotas Pagadas', value: '${currentLoan.paidInstallments}'),
                  InfoRow(label: 'Cuotas Pendientes', value: '${currentLoan.installments - currentLoan.paidInstallments}'),
                  InfoRow(label: 'Valor por Cuota', value: currencyFormat.format(currentLoan.installmentAmount)),
                  if (currentLoan.valorRealCuota != null)
                    InfoRow(
                      label: 'Valor Real Cuota',
                      value: currencyFormat.format(currentLoan.valorRealCuota!),
                      valueColor: AppColors.secondary,
                    ),
                  InfoRow(
                    label: 'Monto Restante',
                    value: currencyFormat.format(currentLoan.remainingAmount),
                    valueColor: AppColors.warning,
                  ),
                  if (currentLoan.loanType == 'Rotativo' || currentLoan.loanType == 'Ahorro' || currentLoan.loanType == 'Fijo') ...[
                    const Divider(height: 24),
                    Text('Información ${currentLoan.loanType}', style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    InfoRow(
                      label: 'Interés sobre Restante',
                      value: currencyFormat.format(currentLoan.remainingAmount * currentLoan.interestRate / 100),
                      valueColor: AppColors.secondary,
                    ),
                    InfoRow(
                      label: 'Base de Cálculo',
                      value: 'Monto restante: ${currencyFormat.format(currentLoan.remainingAmount)}',
                      valueColor: AppColors.primary,
                    ),
                  ],
                  const Divider(height: 24),
                  InfoRow(
                    label: 'Estado Pago Anterior',
                    value: currentLoan.pagoAnterior ? 'Pagado' : 'No Pagado',
                    valueColor: currentLoan.pagoAnterior ? AppColors.success : AppColors.error,
                  ),
                  InfoRow(
                    label: 'Estado Pago Actual',
                    value: currentLoan.pagoActual ? 'Pagado' : 'Pendiente',
                    valueColor: currentLoan.pagoActual ? AppColors.success : AppColors.warning,
                  ),

                  const Divider(height: 24),
                  if (lastCapitalPayment != null) ...[
                    const Text('Último Pago a Capital', style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    InfoRow(
                      label: 'Monto',
                      value: currencyFormat.format((lastCapitalPayment!['principalAmount'] as num).toDouble()),
                      valueColor: AppColors.success,
                    ),
                    InfoRow(
                      label: 'Fecha',
                      value: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(lastCapitalPayment!['date'])),
                    ),
                    InfoRow(
                      label: 'Método',
                      value: _getPaymentMethodText(lastCapitalPayment!['paymentMethod']),
                    ),
                    if (lastCapitalPayment!['notes'] != null && lastCapitalPayment!['notes'].toString().isNotEmpty)
                      InfoRow(
                        label: 'Notas',
                        value: lastCapitalPayment!['notes'],
                      ),
                    const Divider(height: 24),
                  ],
                  InfoRow(label: 'Fecha de Inicio', value: DateFormat('dd/MM/yyyy').format(currentLoan.startDate)),
                  if (_calculateNextPaymentDate(currentLoan) != null)
                    InfoRow(
                      label: 'Próxima Fecha de Pago',
                      value: DateFormat('dd/MM/yyyy').format(_calculateNextPaymentDate(currentLoan)!),
                      valueColor: currentLoan.status.name.toLowerCase() == 'overdue' ? AppColors.error : AppColors.warning,
                    ),
                  const SizedBox(height: 16),
                  const Text('Progreso', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: currentLoan.paidInstallments / currentLoan.installments,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((currentLoan.paidInstallments / currentLoan.installments) * 100).toStringAsFixed(1)}% completado',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (currentLoan.status == LoanStatus.active || currentLoan.status == LoanStatus.overdue)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showPaymentDialog(context, currentLoan, currencyFormat);
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('Registrar Pago'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showCompletePaymentDialog(context, currentLoan);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Pago Completado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  void _showPaymentDialog(BuildContext context, Loan loan, NumberFormat currencyFormat) {
    // Usar valorRealCuota si existe, si no usar installmentAmount
    final cuotaValue = loan.valorRealCuota ?? loan.backendInstallmentAmount ?? loan.installmentAmount;
    
    final paymentController = TextEditingController(
      text: cuotaValue.toStringAsFixed(0),
    );
    // Calcular el interés según el tipo de préstamo
    final defaultInterest = currentLoan.loanType == 'Fijo' 
        ? (loan.remainingAmount * loan.interestRate / 100)  // Para fijos: monto restante * tasa
        : loan.loanType == 'Rotativo'
            ? (loan.remainingAmount * loan.interestRate / 100)  // Para rotativos: monto restante * tasa
            : loan.loanType == 'Ahorro'
                ? (loan.remainingAmount * loan.interestRate / 100)  // Para ahorro: monto restante * tasa
                : (cuotaValue * loan.interestRate / 100);  // Para otros: cuota * tasa
    
    final interestController = TextEditingController(
      text: NumberFormat('#,###', 'es_CO').format(defaultInterest),
    );
    final valorRealCuotaController = TextEditingController(
      text: '\$ ${NumberFormat('#,###', 'es_CO').format(cuotaValue.toInt())}',
    );
    final notesController = TextEditingController();
    bool useCustomAmount = false;
    String selectedPaymentMethod = 'Efectivo';
    bool showSidePanel = false;
    final sidePanelInterestController = TextEditingController();
    final sidePanelCapitalController = TextEditingController();
    String sidePanelPaymentMethod = 'CASH';
    Map<String, dynamic>? previousPayment;
    bool pagoMenorACuota = false;
    
    // Cargar información del pago anterior
    _loadPreviousPayment(loan.id).then((payment) {
      if (mounted) {
        setState(() {
          previousPayment = payment;
        });
      }
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Stack(
          children: [
            AlertDialog(
          title: const Text('Registrar Pago'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuota #${loan.paidInstallments + 1}', style: AppTextStyles.caption),
                const SizedBox(height: 8),
                Text('Tipo: ${loan.loanType ?? "Fijo"}', style: AppTextStyles.caption),
                const SizedBox(height: 16),
                const Text('Valor de la cuota:'),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(cuotaValue),
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ingresar monto diferente'),
                  value: useCustomAmount,
                  onChanged: (value) {
                    setState(() {
                      useCustomAmount = value ?? false;
                      if (!useCustomAmount) {
                        paymentController.text = cuotaValue.toStringAsFixed(0);
                      }
                    });
                  },
                ),
                if (useCustomAmount) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: paymentController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      String text = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (text.isNotEmpty) {
                        final formatted = NumberFormat('#,###', 'es_CO').format(int.parse(text));
                        paymentController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Monto a pagar',
                      prefixText: '\$ ',
                      border: const OutlineInputBorder(),
                      helperText: 'Máximo: ${currencyFormat.format(loan.remainingAmount)}',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: interestController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    String text = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (text.isNotEmpty) {
                      final formatted = NumberFormat('#,###', 'es_CO').format(int.parse(text));
                      interestController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Ganancia/Interés',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                    helperText: 'Ganancia que obtienes por este pago',
                  ),
                ),

                const SizedBox(height: 16),
                const Text('Método de pago:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPaymentMethod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Efectivo',
                    'Transferencia',
                    'Mixto']
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
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
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
            TextButton(
              onPressed: () {
                setState(() => showSidePanel = true);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange.withOpacity(0.1),
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Panel Detallado'),
            ),
            ElevatedButton(
              onPressed: () {
                // Si el checkbox está marcado, usar el valor del input; si no, usar el valor de la cuota
                final amount = useCustomAmount 
                    ? (double.tryParse(paymentController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
                    : cuotaValue;
                final interestAmount = double.tryParse(interestController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                
                final valorRealCuota = double.tryParse(valorRealCuotaController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                
                if (amount < 0) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error de Validación'),
                      content: const Text('El monto no puede ser negativo'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                
                // Validación para última cuota: debe pagar el total restante SIEMPRE
                final cuotasPendientes = loan.installments - loan.paidInstallments;
                if (cuotasPendientes == 1 && amount != loan.remainingAmount) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Última Cuota'),
                      content: Text('Esta es la última cuota. Debe pagar el total restante: ${currencyFormat.format(loan.remainingAmount)}\n\nO puede ampliar la cantidad de cuotas del préstamo.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                
                // Validación para préstamos fijos: debe pagar el monto completo de la cuota (solo si no es monto personalizado)
                if (loan.loanType == 'Fijo' && cuotasPendientes > 1 && amount > 0 && amount != cuotaValue && !useCustomAmount) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Préstamo Fijo'),
                      content: Text('Para préstamos fijos debe pagar el monto completo de la cuota: ${currencyFormat.format(cuotaValue)}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                
                if (amount > 0 && amount > loan.remainingAmount) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Monto Excesivo'),
                      content: const Text('El monto no puede exceder el saldo pendiente'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                // Mapear el método de pago al valor del enum del backend
                String backendPaymentMethod;
                switch (selectedPaymentMethod) {
                  case 'Efectivo':
                    backendPaymentMethod = 'CASH';
                    break;
                  case 'Transferencia':
                    backendPaymentMethod = 'TRANSFER';
                    break;
                  case 'Mixto':
                    backendPaymentMethod = 'MIXED';
                    break;
                  default:
                    backendPaymentMethod = 'CASH';
                }
                _showPaymentConfirmation(context, loan, amount, interestAmount, backendPaymentMethod, notesController.text, currencyFormat, valorRealCuota, selectedPaymentMethod);
              },
              child: const Text('Confirmar Pago'),
            ),
          ],
        ),
      if (showSidePanel)
              Positioned.fill(
                child: ClipRect(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => showSidePanel = false),
                          child: Container(color: Colors.black26),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 0.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(250 * value, 0),
                            child: child,
                          );
                        },
                        child: Material(
                          child: Container(
                            width: 250,
                            color: Colors.white,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  color: AppColors.primary,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        onPressed: () => setState(() => showSidePanel = false),
                                      ),
                                      const Expanded(
                                        child: Text(
                                          'Pago Detallado',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Préstamo #${loan.id}',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          widget.user.name,
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Información de Cuotas',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Text('Pago Anterior: ', style: TextStyle(fontSize: 12)),
                                                  Text(
                                                    loan.pagoAnterior ? 'Pagado' : 'Pendiente',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: loan.pagoAnterior ? Colors.green : Colors.red,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Text('Valor por Cuota: ', style: TextStyle(fontSize: 12)),
                                                  Text(
                                                    NumberFormat('\$ #,##0', 'es_CO').format(loan.installmentAmount),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.purple,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Text('Valor Real Cuota: ', style: TextStyle(fontSize: 12)),
                                                  Text(
                                                    NumberFormat('\$ #,##0', 'es_CO').format(loan.valorRealCuota ?? loan.installmentAmount),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blue,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (previousPayment != null) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Text('Monto Cuota Anterior: ', style: TextStyle(fontSize: 12)),
                                                    Text(
                                                      NumberFormat('\$ #,##0', 'es_CO').format((previousPayment!['principalAmount'] as num? ?? 0).toDouble()),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        TextField(
                                          controller: sidePanelInterestController,
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
                                          decoration: InputDecoration(
                                            labelText: 'Intereses',
                                            prefixText: '\$ ',
                                            hintText: '0',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: sidePanelCapitalController,
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
                                          decoration: InputDecoration(
                                            labelText: 'Capital',
                                            prefixText: '\$ ',
                                            hintText: '0',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<String>(
                                          value: sidePanelPaymentMethod,
                                          decoration: InputDecoration(
                                            labelText: 'Método de Pago',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'CASH', child: Text('Efectivo')),
                                            DropdownMenuItem(value: 'TRANSFER', child: Text('Transferencia')),
                                            DropdownMenuItem(value: 'MIXED', child: Text('Mixto')),
                                          ],
                                          onChanged: (value) => setState(() => sidePanelPaymentMethod = value!),
                                        ),
                                        const SizedBox(height: 16),
                                        CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Pago Menor a Cuota'),
                                          subtitle: const Text('No avanzar fecha si el capital es menor al valor por cuota'),
                                          value: pagoMenorACuota,
                                          onChanged: (value) => setState(() => pagoMenorACuota = value ?? false),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              final cleanInterest = sidePanelInterestController.text.replaceAll(',', '').replaceAll('.', '');
                                              final cleanCapital = sidePanelCapitalController.text.replaceAll(',', '').replaceAll('.', '');
                                              
                                              final interestAmount = double.tryParse(cleanInterest) ?? 0;
                                              final capitalAmount = double.tryParse(cleanCapital) ?? 0;
                                              final totalAmount = interestAmount + capitalAmount;
                                              
                                              if (totalAmount <= 0) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Debe ingresar al menos un monto'),
                                                    backgroundColor: AppColors.error,
                                                  ),
                                                );
                                                return;
                                              }
                                              
                                              // Mostrar diálogo de confirmación
                                              showDialog(
                                                context: context,
                                                builder: (confirmContext) => AlertDialog(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  title: Row(
                                                    children: [
                                                      Icon(Icons.check_circle_outline, color: AppColors.primary, size: 28),
                                                      const SizedBox(width: 12),
                                                      const Text('Confirmar Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Cuota #${loan.paidInstallments + 1}', style: AppTextStyles.h3),
                                                      const Divider(height: 24),
                                                      InfoRow(label: 'Capital', value: currencyFormat.format(capitalAmount)),
                                                      InfoRow(label: 'Intereses', value: currencyFormat.format(interestAmount)),
                                                      InfoRow(label: 'Total', value: currencyFormat.format(totalAmount)),
                                                      InfoRow(label: 'Método', value: sidePanelPaymentMethod == 'CASH' ? 'Efectivo' : sidePanelPaymentMethod == 'TRANSFER' ? 'Transferencia' : 'Mixto'),
                                                      const Divider(height: 24),
                                                      const Text('¿Confirmar este pago?', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(confirmContext),
                                                      child: const Text('Cancelar'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        Navigator.pop(confirmContext);
                                                        
                                                        try {
                                                          // Aplicar lógica de pago menor a cuota
                                                          final shouldSkipInstallmentUpdate = pagoMenorACuota && capitalAmount < loan.installmentAmount;
                                                          
                                                          await ApiService.createTransaction(
                                                            loanId: loan.id,
                                                            amount: totalAmount,
                                                            paymentMethod: sidePanelPaymentMethod,
                                                            notes: 'Capital: \$${NumberFormat('#,##0').format(capitalAmount)}, Intereses: \$${NumberFormat('#,##0').format(interestAmount)}${shouldSkipInstallmentUpdate ? ' - Pago parcial' : ''}',
                                                            interestAmount: interestAmount,
                                                            principalAmount: capitalAmount,
                                                            loanType: loan.loanType,
                                                            paymentFrequency: loan.paymentFrequency,
                                                          );
                                                          
                                                          // Solo actualizar cuotas si no es pago menor a cuota o si el capital es >= valor por cuota
                                                          if (!shouldSkipInstallmentUpdate) {
                                                            await ApiService.updateLoanInstallments(
                                                              loanId: loan.id,
                                                              paidInstallments: loan.paidInstallments + 1,
                                                            );
                                                          }
                                                          
                                                          if (loan.status == LoanStatus.overdue) {
                                                            await ApiService.updateLoanStatus(
                                                              loanId: loan.id,
                                                              status: 'ACTIVE',
                                                            );
                                                          }
                                                          
                                                          Navigator.pop(context);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Pago registrado exitosamente'),
                                                              backgroundColor: AppColors.success,
                                                            ),
                                                          );
                                                          await _refreshLoanData();
                                                        } catch (e) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Error: $e'),
                                                              backgroundColor: AppColors.error,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppColors.primary,
                                                        foregroundColor: Colors.white,
                                                      ),
                                                      child: const Text('Confirmar'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                            },
                                            icon: const Icon(Icons.check_circle),
                                            label: const Text('Realizar Pago', style: TextStyle(fontSize: 16)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.success,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
          ],
        ),
      ),
              )
    ]
    )
      )
    );
  }

  void _updatePaymentStatus(BuildContext context, String loanId, bool? pagoAnterior, bool? pagoActual) async {
    try {
      await ApiService.updatePaymentStatus(
        loanId: loanId,
        pagoAnterior: pagoAnterior,
        pagoActual: pagoActual,
      );
      
      // Obtener los datos actualizados del préstamo
      final updatedLoan = await ApiService.getLoanByIdAsModel(loanId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado de pago actualizado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Actualizar los datos en la pantalla actual
      await _refreshLoanData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado de pago actualizado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar estado: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showPaymentConfirmation(BuildContext context, Loan loan, double amount, double interestAmount, String backendPaymentMethod, String notes, NumberFormat currencyFormat, double valorRealCuota, String displayPaymentMethod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Confirmar Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuota #${loan.paidInstallments + 1}', style: AppTextStyles.h3),
            const Divider(height: 24),
            InfoRow(label: 'Monto Total', value: currencyFormat.format(amount)),
            InfoRow(label: 'Capital', value: currencyFormat.format(amount)),
            InfoRow(label: 'Ganancia', value: currencyFormat.format(interestAmount)),
            InfoRow(label: 'Método de Pago', value: displayPaymentMethod),
            if (notes.isNotEmpty) InfoRow(label: 'Notas', value: notes),
            const Divider(height: 24),
            const Text('¿Confirmar este pago?', style: TextStyle(fontWeight: FontWeight.bold)),
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
              _processPaymentWithCustomInterest(context, loan, amount, interestAmount, backendPaymentMethod, notes, currencyFormat, valorRealCuota);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _processPaymentWithCustomInterest(BuildContext context, Loan loan, double amount, double interestAmount, String paymentMethod, String notes, NumberFormat currencyFormat, double valorRealCuota) async {
    try {
      // El principalAmount debe ser el monto completo del pago
      // Los intereses se registran por separado y no se restan del capital
      final principalPortion = amount;
      // Crear la transacción en el backend
      final transaction = await ApiService.createTransaction(
        loanId: loan.id,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes.isNotEmpty ? notes : (amount == 0 ? 'Pago de ganancia/interés solamente' : 'Pago cuota #${loan.paidInstallments + 1}'),
        interestAmount: interestAmount,
        principalAmount: principalPortion.toDouble(),
        loanType: loan.loanType,
        paymentFrequency: loan.paymentFrequency,
        valorRealCuota: valorRealCuota,
      );
      
      // Actualizar cuotas pagadas siempre al hacer un pago
      await ApiService.updateLoanInstallments(
        loanId: loan.id,
        paidInstallments: loan.paidInstallments + 1,
      );
      
      // Actualizar estado de pago automáticamente
      await ApiService.updatePaymentStatus(
        loanId: loan.id,
        pagoAnterior: true,
        pagoActual: false,
      );
      
      // Si el préstamo estaba vencido, cambiarlo a activo al realizar un pago
      if (loan.status == LoanStatus.overdue) {
        await ApiService.updateLoanStatus(
          loanId: loan.id,
          status: 'ACTIVE',
        );
      }
      
      // Actualizar la pantalla con datos actualizados
      await _refreshLoanData();
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pago registrado exitosamente - ID: ${transaction['id']}'),
          backgroundColor: AppColors.success,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar pago: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _processPayment(BuildContext context, Loan loan, double amount, String paymentMethod, String notes, NumberFormat currencyFormat) async {
    try {
      // Calcular interés según el tipo de préstamo
      final interestPortion = loan.loanType == 'Fijo'
          ? (loan.remainingAmount * loan.interestRate / 100).clamp(0.0, amount)  // Para fijos: monto restante * tasa
          : loan.loanType == 'Ahorro'
              ? (loan.remainingAmount * loan.interestRate / 100).clamp(0.0, amount)  // Para ahorro: monto restante * tasa
              : (amount * loan.interestRate / 100).clamp(0.0, amount);      // Para otros: pago * tasa
      
      // El principalAmount debe ser el monto completo del pago
      // Los intereses se registran por separado y no se restan del capital
      final principalPortion = amount;
      
      // Crear la transacción en el backend
      final transaction = await ApiService.createTransaction(
        loanId: loan.id,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes.isNotEmpty ? notes : 'Pago cuota #${loan.paidInstallments + 1}',
        interestAmount: interestPortion,
        principalAmount: principalPortion,
        loanType: loan.loanType,
        paymentFrequency: loan.paymentFrequency,
      );
      
      // Actualizar las cuotas pagadas del préstamo
      await ApiService.updateLoanInstallments(
        loanId: loan.id,
        paidInstallments: loan.paidInstallments + 1,
      );
      
      // Actualizar estado de pago automáticamente
      await ApiService.updatePaymentStatus(
        loanId: loan.id,
        pagoAnterior: true,
        pagoActual: true,
      );
      
      // Mostrar confirmación
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pago Registrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID Transacción: ${transaction['id']}'),
              const SizedBox(height: 8),
              Text('Monto total: ${currencyFormat.format(amount)}'),
              Text('Capital: ${currencyFormat.format(principalPortion)}'),
              Text('Interés: ${currencyFormat.format(interestPortion)}'),
              Text('Método: $paymentMethod'),
              if (notes.isNotEmpty) Text('Notas: $notes'),
              const SizedBox(height: 8),
              const Text('Préstamo y estados actualizados correctamente', 
                style: TextStyle(color: AppColors.success, fontSize: 12)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Actualizar la pantalla con datos actualizados
                await _refreshLoanData();
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar pago: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  void _showCompletePaymentDialog(BuildContext context, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Marcar como Completado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas marcar este préstamo como completamente pagado?\n\nEsta acción actualizará el estado del préstamo.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markLoanAsCompleted(context, loan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _markLoanAsCompleted(BuildContext context, Loan loan) async {
    try {
      // 1. Actualizar las cuotas pagadas al total de cuotas
      await ApiService.updateLoanInstallments(
        loanId: loan.id,
        paidInstallments: loan.installments,
      );
      
      // 2. Actualizar el estado de pago a completado
      await ApiService.updatePaymentStatus(
        loanId: loan.id,
        pagoAnterior: true,
        pagoActual: true,
      );
      
      // 3. Cambiar el estado del préstamo a COMPLETED
      await ApiService.updateLoanStatus(
        loanId: loan.id,
        status: 'COMPLETED',
      );
      
      // 4. Crear una transacción de completado si hay saldo pendiente
      if (loan.remainingAmount > 0) {
        // Calcular interés según el tipo de préstamo
        final interestPortion = loan.loanType == 'Fijo'
            ? (loan.remainingAmount * loan.interestRate / 100).clamp(0.0, loan.remainingAmount)  // Para fijos: monto restante * tasa
            : loan.loanType == 'Ahorro'
                ? (loan.remainingAmount * loan.interestRate / 100).clamp(0.0, loan.remainingAmount)  // Para ahorro: monto restante * tasa
                : (loan.remainingAmount * loan.interestRate / 100).clamp(0.0, loan.remainingAmount);  // Para otros: saldo * tasa
        
        // El principalAmount debe ser el monto completo del pago
        final principalPortion = loan.remainingAmount;
        
        await ApiService.createTransaction(
          loanId: loan.id,
          amount: loan.remainingAmount,
          paymentMethod: 'Efectivo',
          notes: 'Pago completado - Saldo restante liquidado',
          interestAmount: interestPortion,
          principalAmount: principalPortion,
          loanType: loan.loanType,
          paymentFrequency: loan.paymentFrequency,
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préstamo finalizado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      
      await _refreshLoanData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al finalizar préstamo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _refreshLoanData() async {
    try {
      final updatedLoan = await ApiService.getLoanByIdAsModel(currentLoan.id);
      setState(() {
        currentLoan = updatedLoan;
      });
      await _loadLastCapitalPayment();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar datos: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'CASH':
        return 'Efectivo';
      case 'TRANSFER':
        return 'Transferencia';
      case 'MIXED':
        return 'Mixto';
      default:
        return method;
    }
  }

  void _reloadLoanData(BuildContext context) async {
    await _refreshLoanData();
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Eliminar Préstamo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que deseas eliminar este préstamo?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('ID: ${currentLoan.id}'),
            Text('Usuario: ${widget.user.name}'),
            Text('Monto: \$ ${NumberFormat('#,###', 'es_CO').format(currentLoan.amount)}'),
            const SizedBox(height: 12),
            const Text(
              'Esta acción no se puede deshacer y eliminará todas las transacciones asociadas.',
              style: TextStyle(color: Colors.red, fontSize: 14),
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
              _deleteLoan(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLoan(BuildContext context) async {
    try {
      await ApiService.deleteLoan(currentLoan.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préstamo eliminado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Regresar a la pantalla anterior
      Navigator.pop(context, true); // true indica que se eliminó el préstamo
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar préstamo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showEditDialog(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'es_CO');
    final amountController = TextEditingController(
      text: numberFormat.format(currentLoan.amount.toInt()),
    );
    final interestController = TextEditingController(text: currentLoan.interestRate.toString());
    final installmentsController = TextEditingController(text: currentLoan.installments.toString());
    final valorRealCuotaController = TextEditingController(
      text: currentLoan.valorRealCuota != null ? numberFormat.format(currentLoan.valorRealCuota!.toInt()) : '',
    );
    
    DateTime selectedDate = currentLoan.startDate;
    
    // Determinar si es capital fijo basado en sinCuotas
    bool capitalFijo = currentLoan.sinCuotas ?? false;
    
    // Validar que el loanType esté en la lista de opciones (sin Capital Fijo)
    final validLoanTypes = ['Fijo', 'Rotativo', 'Ahorro'];
    String selectedLoanType = validLoanTypes.contains(currentLoan.loanType) 
        ? currentLoan.loanType! 
        : 'Fijo';
    
    final validPaymentFrequencies = ['Mensual 15', 'Mensual 30', 'Quincenal', 'Quincenal 5', 'Quincenal 20', 'Semanal'];
    String selectedPaymentFrequency = validPaymentFrequencies.contains(currentLoan.paymentFrequency)
        ? currentLoan.paymentFrequency!
        : 'Mensual 30';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Préstamo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    String text = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (text.isNotEmpty) {
                      final formatted = numberFormat.format(int.parse(text));
                      amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Monto Prestado',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: interestController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tasa de Interés (%)',
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
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
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
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          'Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valorRealCuotaController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    String text = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (text.isNotEmpty) {
                      final formatted = numberFormat.format(int.parse(text));
                      valorRealCuotaController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Valor Real Cuota',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                    helperText: 'Valor real de cada cuota',
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Capital Fijo'),
                  subtitle: const Text('Marcar si el préstamo no aplica tasa de interés'),
                  value: capitalFijo,
                  onChanged: (value) {
                    setState(() {
                      capitalFijo = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLoanType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Préstamo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Fijo', child: Text('Fijo')),
                    DropdownMenuItem(value: 'Rotativo', child: Text('Rotativo')),
                    DropdownMenuItem(value: 'Ahorro', child: Text('Ahorro')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedLoanType = value!;
                      // Aplicar reglas específicas para cada tipo de préstamo
                      if (value == 'Fijo') {
                        selectedPaymentFrequency = 'Mensual 30';
                      } else if (value == 'Ahorro') {
                        selectedPaymentFrequency = 'Mensual 15';
                      }
                      // Rotativo mantiene la selección libre
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPaymentFrequency,
                  decoration: InputDecoration(
                    labelText: 'Forma de Pago',
                    border: const OutlineInputBorder(),
                    enabled: selectedLoanType == 'Rotativo',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Mensual 15', child: Text('Mensual 15')),
                    DropdownMenuItem(value: 'Mensual 30', child: Text('Mensual 30')),
                    DropdownMenuItem(value: 'Quincenal', child: Text('Quincenal (15-30)')),
                    DropdownMenuItem(value: 'Quincenal 30-15', child: Text('Quincenal (30-15)')),
                    DropdownMenuItem(value: 'Quincenal 5', child: Text('Quincenal 5')),
                    DropdownMenuItem(value: 'Quincenal 20', child: Text('Quincenal 20')),
                    DropdownMenuItem(value: 'Semanal', child: Text('Semanal')),
                  ],
                  onChanged: selectedLoanType == 'Rotativo' ? (value) => setState(() => selectedPaymentFrequency = value!) : null,
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
                final amount = double.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
                final interestRate = double.tryParse(interestController.text);
                final installments = int.tryParse(installmentsController.text);
                final valorRealCuota = valorRealCuotaController.text.isNotEmpty 
                    ? double.tryParse(valorRealCuotaController.text.replaceAll(RegExp(r'[^0-9]'), '')) 
                    : null;
                
                if (amount == null || interestRate == null || installments == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa valores válidos'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                await _updateLoan(amount, interestRate, installments, selectedLoanType, selectedPaymentFrequency, valorRealCuota, capitalFijo, selectedDate);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLoan(double amount, double interestRate, int installments, String loanType, String paymentFrequency, double? valorRealCuota, bool sinCuotas, DateTime startDate) async {
    try {
      await ApiService.updateLoan(
        loanId: currentLoan.id,
        amount: amount,
        interestRate: interestRate,
        installments: installments,
        loanType: loanType,
        paymentFrequency: paymentFrequency,
        valorRealCuota: valorRealCuota,
        sinCuotas: sinCuotas,
        startDate: startDate,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préstamo actualizado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      
      await _refreshLoanData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar préstamo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  DateTime? _calculateNextPaymentDate(Loan loan) {
    // Usar nextPaymentDate del backend si está disponible
    if (loan.nextPaymentDate != null) {
      return loan.nextPaymentDate;
    }
    
    // Fallback: si no hay nextPaymentDate, no mostrar fecha
    return null;
  }

}