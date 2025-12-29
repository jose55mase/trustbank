import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/transaction.dart';
import '../../data/services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/loan_id_row.dart';

// Import condicional para web
import 'dart:html' as html show Blob, Url, document, AnchorElement;

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String selectedFilter = 'Todas';
  String? loanTypeFilter;
  String? paymentFrequencyFilter;
  DateTime? selectedDate;
  DateTimeRange? selectedDateRange;
  Transaction? selectedTransaction;
  List<dynamic> _transactions = [];
  List<dynamic> _loans = [];
  bool _isLoading = true;
  
  // Variables temporales para filtros (antes de aplicar)
  String _tempSelectedFilter = 'Todas';
  String? _tempLoanTypeFilter;
  String? _tempPaymentFrequencyFilter;
  DateTime? _tempSelectedDate;
  DateTimeRange? _tempSelectedDateRange;

  @override
  void initState() {
    super.initState();
    // Configurar filtro inicial para el día actual
    final today = DateTime.now();
    selectedDate = DateTime(today.year, today.month, today.day);
    _tempSelectedDate = selectedDate;
    
    _tempSelectedFilter = selectedFilter;
    _tempLoanTypeFilter = loanTypeFilter;
    _tempPaymentFrequencyFilter = paymentFrequencyFilter;
    _tempSelectedDateRange = selectedDateRange;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> transactions;
      List<dynamic> loans;
      
      // Aplicar filtros al backend
      if (selectedDateRange != null) {
        transactions = await ApiService.getTransactionsByDateRange(
          startDate: selectedDateRange!.start,
          endDate: selectedDateRange!.end,
        );
      } else {
        transactions = await ApiService.getAllTransactions();
      }
      
      loans = await ApiService.getAllLoans();
      
      setState(() {
        _transactions = transactions;
        _loans = loans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  List<dynamic> get filteredTransactions {
    var filtered = <dynamic>[];
    
    if (selectedFilter == 'Préstamo') {
      filtered = List.from(_loans);
    } else {
      filtered = List.from(_transactions);
      
      if (selectedFilter == 'Pago') {
        filtered = filtered.where((t) => t['type'] == 'PAYMENT').toList();
      }
    }
    
    if (loanTypeFilter != null) {
      if (selectedFilter == 'Préstamo') {
        filtered = filtered.where((loan) {
          final loanType = loan['loanType']?.toString();
          return (loanTypeFilter == 'Fijo' && (loanType == 'FIXED' || loanType == 'Fijo')) ||
                 (loanTypeFilter == 'Rotativo' && (loanType == 'REVOLVING' || loanType == 'Rotativo')) ||
                 (loanTypeFilter == 'Ahorro' && (loanType == 'SAVINGS' || loanType == 'Ahorro'));
        }).toList();
      } else {
        filtered = filtered.where((t) {
          final loan = t['loan'];
          if (loan == null) return false;
          final loanType = loan['loanType']?.toString();
          return (loanTypeFilter == 'Fijo' && (loanType == 'FIXED' || loanType == 'Fijo')) ||
                 (loanTypeFilter == 'Rotativo' && (loanType == 'REVOLVING' || loanType == 'Rotativo')) ||
                 (loanTypeFilter == 'Ahorro' && (loanType == 'SAVINGS' || loanType == 'Ahorro'));
        }).toList();
      }
    }
    
    if (paymentFrequencyFilter != null) {
      if (selectedFilter == 'Préstamo') {
        filtered = filtered.where((loan) {
          final frequency = loan['paymentFrequency']?.toString();
          return frequency == paymentFrequencyFilter;
        }).toList();
      } else {
        filtered = filtered.where((t) {
          final loan = t['loan'];
          if (loan == null) return false;
          final frequency = loan['paymentFrequency']?.toString();
          return frequency == paymentFrequencyFilter;
        }).toList();
      }
    }
    
    if (selectedDate != null) {
      filtered = filtered.where((item) {
        try {
          final dateField = selectedFilter == 'Préstamo' ? 'startDate' : 'date';
          if (item[dateField] == null) return false;
          final itemDate = DateTime.parse(item[dateField]);
          return itemDate.year == selectedDate!.year &&
                 itemDate.month == selectedDate!.month &&
                 itemDate.day == selectedDate!.day;
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    if (selectedDateRange != null) {
      filtered = filtered.where((item) {
        try {
          final dateField = selectedFilter == 'Préstamo' ? 'startDate' : 'date';
          if (item[dateField] == null) return false;
          final itemDate = DateTime.parse(item[dateField]);
          return itemDate.isAfter(selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                 itemDate.isBefore(selectedDateRange!.end.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    return filtered;
  }
  
  void _applyFilters() {
    setState(() {
      selectedFilter = _tempSelectedFilter;
      loanTypeFilter = _tempLoanTypeFilter;
      paymentFrequencyFilter = _tempPaymentFrequencyFilter;
      selectedDate = _tempSelectedDate;
      selectedDateRange = _tempSelectedDateRange;
    });
    _loadTransactions();
    Navigator.pop(context);
  }
  
  void _clearFilters() {
    setState(() {
      _tempSelectedFilter = 'Todas';
      _tempLoanTypeFilter = null;
      _tempPaymentFrequencyFilter = null;
      _tempSelectedDate = null;
      _tempSelectedDateRange = null;
    });
  }
  
  Widget _buildFilterDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text('Filtros', style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipo de datos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('Todas'),
                    value: 'Todas',
                    groupValue: _tempSelectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _tempSelectedFilter = value!;
                        if (_tempSelectedFilter == 'Préstamo') {
                          _tempLoanTypeFilter = null;
                        }
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Préstamos'),
                    value: 'Préstamo',
                    groupValue: _tempSelectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _tempSelectedFilter = value!;
                        if (_tempSelectedFilter == 'Préstamo') {
                          _tempLoanTypeFilter = null;
                        }
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Pagos'),
                    value: 'Pago',
                    groupValue: _tempSelectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _tempSelectedFilter = value!;
                      });
                    },
                  ),
                  if (_tempSelectedFilter == 'Todas' || _tempSelectedFilter == 'Pago') ...[
                    const SizedBox(height: 16),
                    const Text('Tipo de préstamo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String?>(
                      value: _tempLoanTypeFilter,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: 'Fijo', child: Text('Fijo')),
                        DropdownMenuItem(value: 'Rotativo', child: Text('Rotativo')),
                        DropdownMenuItem(value: 'Ahorro', child: Text('Ahorro')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _tempLoanTypeFilter = value;
                        });
                      },
                    ),
                  ],
                  if (_tempSelectedFilter == 'Todas' || _tempSelectedFilter == 'Pago' || _tempSelectedFilter == 'Préstamo') ...[
                    const SizedBox(height: 16),
                    const Text('Forma de pago:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String?>(
                      value: _tempPaymentFrequencyFilter,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todas')),
                        DropdownMenuItem(value: 'Mensual 15', child: Text('Mensual 15')),
                        DropdownMenuItem(value: 'Mensual 30', child: Text('Mensual 30')),
                        DropdownMenuItem(value: 'Quincenal', child: Text('Quincenal')),
                        DropdownMenuItem(value: 'Quincenal 5', child: Text('Quincenal 5')),
                        DropdownMenuItem(value: 'Quincenal 20', child: Text('Quincenal 20')),
                        DropdownMenuItem(value: 'Semanal', child: Text('Semanal')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _tempPaymentFrequencyFilter = value;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Filtros de fecha:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _tempSelectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() {
                                _tempSelectedDate = picked;
                                _tempSelectedDateRange = null;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_tempSelectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(_tempSelectedDate!)
                              : 'Fecha'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: _tempSelectedDateRange,
                            );
                            if (picked != null) {
                              setState(() {
                                _tempSelectedDateRange = picked;
                                _tempSelectedDate = null;
                              });
                            }
                          },
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _tempSelectedDateRange != null
                                ? '${DateFormat('dd/MM').format(_tempSelectedDateRange!.start)}-${DateFormat('dd/MM').format(_tempSelectedDateRange!.end)}'
                                : 'Rango',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_tempSelectedDate != null || _tempSelectedDateRange != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _tempSelectedDate = null;
                          _tempSelectedDateRange = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar fechas'),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Aplicar Filtros'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Limpiar Filtros'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _exportTransactions(List<dynamic> transactions) async {
    try {
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Transacciones'];
      
      // Encabezados principales
      final headers1 = [
        'ID', 'TIPO', 'FECHA', 'MONTO', 'METODO', 'TIPO DE', 
        'FORMA', 'ID', 'CLIENTE', 'TELEFONO', 'CUOTAS', 
        'CUOTAS', 'CUOTAS', 'CAPITAL', 'INTERES', 'NOTAS'
      ];
      
      // Encabezados secundarios
      final headers2 = [
        '', '', '', '', 'DE PAGO', 'PRESTAMO', 
        'DE PAGO', 'PRESTAMO', '', '', 'TOTALES', 
        'PAGADAS', 'RESTANTES', '', '', ''
      ];
      
      // Ajustar altura de las filas de encabezados
      sheet.setRowHeight(0, 25);
      sheet.setRowHeight(1, 25);
      
      // Agregar primera fila de encabezados
      for (int i = 0; i < headers1.length; i++) {
        final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = excel.TextCellValue(headers1[i]);
        cell.cellStyle = excel.CellStyle(
          bold: true,
          fontSize: 12,
          fontColorHex: excel.ExcelColor.white,
          backgroundColorHex: excel.ExcelColor.blue,
          horizontalAlign: excel.HorizontalAlign.Center,
          verticalAlign: excel.VerticalAlign.Center,
        );
      }
      
      // Agregar segunda fila de encabezados
      for (int i = 0; i < headers2.length; i++) {
        final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
        cell.value = excel.TextCellValue(headers2[i]);
        cell.cellStyle = excel.CellStyle(
          bold: true,
          fontSize: 12,
          fontColorHex: excel.ExcelColor.white,
          backgroundColorHex: excel.ExcelColor.blue,
          horizontalAlign: excel.HorizontalAlign.Center,
          verticalAlign: excel.VerticalAlign.Center,
        );
      }
      
      // Ajustar ancho de columnas
      for (int i = 0; i < headers1.length; i++) {
        sheet.setColumnWidth(i, 20);
      }
      
      // Agregar datos
      for (int rowIndex = 0; rowIndex < transactions.length; rowIndex++) {
        final item = transactions[rowIndex];
        final isLoan = selectedFilter == 'Préstamo';
        final isPayment = !isLoan && item['type'] == 'PAYMENT';
        
        final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');
        
        final row = [
          item['id']?.toString() ?? '',
          isLoan ? 'Prestamo' : (isPayment ? 'Pago' : 'Transaccion'),
          isLoan 
            ? (item['startDate'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(item['startDate'])) : '')
            : (item['date'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['date'])) : ''),
          currencyFormat.format(item['amount'] ?? 0),
          isLoan ? '' : _getPaymentMethodText(item['paymentMethod']?.toString() ?? ''),
          isLoan 
            ? (item['loanType']?.toString() ?? '')
            : (item['loan']?['loanType']?.toString() ?? ''),
          isLoan 
            ? (item['paymentFrequency']?.toString() ?? '')
            : (item['loan']?['paymentFrequency']?.toString() ?? ''),
          isLoan ? item['id']?.toString() ?? '' : (item['loan']?['id']?.toString() ?? ''),
          isLoan 
            ? (item['user']?['name']?.toString() ?? '')
            : (item['loan']?['user']?['name']?.toString() ?? ''),
          isLoan 
            ? (item['user']?['phone']?.toString() ?? '')
            : (item['loan']?['user']?['phone']?.toString() ?? ''),
          isLoan 
            ? (item['installments']?.toString() ?? '')
            : (item['loan']?['installments']?.toString() ?? ''),
          isLoan 
            ? (item['paidInstallments']?.toString() ?? '')
            : (item['loan']?['paidInstallments']?.toString() ?? ''),
          isLoan 
            ? ((item['installments'] ?? 0) - (item['paidInstallments'] ?? 0)).toString()
            : ((item['loan']?['installments'] ?? 0) - (item['loan']?['paidInstallments'] ?? 0)).toString(),
          isPayment ? currencyFormat.format(item['principalAmount'] ?? 0) : '',
          isPayment ? currencyFormat.format(item['interestAmount'] ?? 0) : '',
          item['notes']?.toString() ?? ''
        ];
        
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 2));
          cell.value = excel.TextCellValue(row[colIndex]);
          cell.cellStyle = excel.CellStyle(
            fontSize: 12,
            horizontalAlign: excel.HorizontalAlign.Center,
            verticalAlign: excel.VerticalAlign.Center,
          );
        }
      }
      
      // Generar archivo
      final bytes = excelFile.encode();
      if (bytes != null) {
        final now = DateTime.now();
        final fileName = 'transacciones_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';
        
        if (kIsWeb) {
          // Para web: descargar directamente
          final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..style.display = 'none'
            ..download = fileName;
          html.document.body?.children.add(anchor);
          anchor.click();
          html.document.body?.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        } else {
          // Para móvil: usar share
          await Share.shareXFiles(
            [XFile.fromData(
              Uint8List.fromList(bytes), 
              name: fileName,
              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            )],
            text: 'Exportacion de transacciones',
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(kIsWeb ? 'Excel descargado exitosamente' : 'Excel compartido exitosamente')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  double get totalPayments {
    return filteredTransactions
        .where((t) => t['type'] == 'PAYMENT')
        .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  }

  double get totalInterest {
    return filteredTransactions
        .where((t) => t['type'] == 'PAYMENT')
        .fold(0.0, (sum, t) => sum + ((t['interestAmount'] as num?)?.toDouble() ?? 0.0));
  }

  double get totalPrincipal {
    return filteredTransactions
        .where((t) => t['type'] == 'PAYMENT')
        .fold(0.0, (sum, t) => sum + ((t['principalAmount'] as num?)?.toDouble() ?? 0.0));
  }

  double get totalAllTransactions {
    return filteredTransactions
        .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'CASH':
        return 'Efectivo';
      case 'TRANSFER':
        return 'Transferencia';
      case 'CHECK':
        return 'Cheque';
      case 'MIXED':
        return 'Mixto';
      default:
        return method;
    }
  }

  String _getLoanStatusText(String? status) {
    switch (status) {
      case 'ACTIVE':
        return 'Activo';
      case 'PAID':
        return 'Pagado';
      case 'OVERDUE':
        return 'Vencido';
      case 'CANCELLED':
        return 'Cancelado';
      default:
        return status ?? 'Desconocido';
    }
  }

  void _showSummaryModal(NumberFormat currencyFormat) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
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
                    const Icon(Icons.analytics, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Resumen Financiero',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSummaryCard(
                        'Total General',
                        currencyFormat.format(totalAllTransactions),
                        Icons.account_balance_wallet,
                        AppColors.primary,
                        'Suma de todas las transacciones filtradas',
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryCard(
                        'Total Intereses',
                        currencyFormat.format(totalInterest),
                        Icons.trending_up,
                        AppColors.success,
                        'Ganancias por intereses de pagos',
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryCard(
                        'Total Capital',
                        currencyFormat.format(totalPrincipal),
                        Icons.payments,
                        AppColors.secondary,
                        'Capital recuperado de préstamos',
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryCard(
                        'Total Pagos',
                        currencyFormat.format(totalPayments),
                        Icons.payment,
                        AppColors.warning,
                        'Solo transacciones de tipo pago',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLoanDetail(String loanId) async {
    try {
      final loan = await ApiService.getLoanById(loanId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _LoanInfoDialog(loan: loan),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar préstamo: $e')),
        );
      }
    }
  }

  void _showTransactionDetail(Map<String, dynamic> transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');
    final isPayment = transaction['type'] == 'PAYMENT';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isPayment ? AppColors.success : AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPayment ? Icons.payment : Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPayment ? 'Detalle del Pago' : 'Detalle del Préstamo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${transaction['id']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailSection(
                        title: 'Información General',
                        children: [
                          _DetailRow('Tipo', isPayment ? 'Pago' : 'Préstamo'),
                          _DetailRow('Monto', currencyFormat.format(transaction['amount'] ?? 0)),
                          _DetailRow('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaction['date']))),
                          _DetailRow('Método de Pago', _getPaymentMethodText(transaction['paymentMethod']?.toString() ?? '')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DetailSection(
                        title: 'Información del Préstamo',
                        children: [
                          LoanIdRow(
                            loanId: transaction['loan']?['id']?.toString() ?? 'N/A',
                            onTap: transaction['loan']?['id'] != null
                                ? () {
                                    Navigator.pop(context);
                                    _showLoanDetail(transaction['loan']['id'].toString());
                                  }
                                : null,
                          ),
                          if (transaction['loan']?['user'] != null) ...[
                            _DetailRow('Cliente', transaction['loan']['user']['name'] ?? 'N/A'),
                            _DetailRow('Teléfono', transaction['loan']['user']['phone'] ?? 'N/A'),
                            _DetailRow('Email', transaction['loan']['user']['email'] ?? 'N/A'),
                          ],
                          if (transaction['loan'] != null) ...[
                            _DetailRow('Monto Préstamo', currencyFormat.format(transaction['loan']['amount'] ?? 0)),
                            _DetailRow('Tipo de Préstamo', transaction['loan']['loanType'] ?? 'N/A'),
                            _DetailRow('Forma de Pago', transaction['loan']['paymentFrequency'] ?? 'N/A'),
                            _DetailRow('Tasa Interés', '${transaction['loan']['interestRate'] ?? 0}%'),
                            _DetailRow('Cuotas Totales', '${transaction['loan']['installments'] ?? 0}'),
                            _DetailRow('Cuotas Pagadas', '${transaction['loan']['paidInstallments'] ?? 0}'),
                            _DetailRow('Estado', _getLoanStatusText(transaction['loan']['status']?.toString())),
                            if (transaction['loan']['startDate'] != null)
                              _DetailRow('Fecha Inicio', DateFormat('dd/MM/yyyy').format(DateTime.parse(transaction['loan']['startDate']))),
                          ],
                        ],
                      ),
                      if (isPayment && (transaction['interestAmount'] != null || transaction['principalAmount'] != null)) ...[
                        const SizedBox(height: 20),
                        _DetailSection(
                          title: 'Desglose del Pago',
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Desglose del Pago',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showEditPaymentBreakdown(context, transaction, currencyFormat),
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Editar desglose',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (transaction['principalAmount'] != null)
                              _DetailRow('Capital', currencyFormat.format(transaction['principalAmount'])),
                            if (transaction['interestAmount'] != null)
                              _DetailRow('Interés', currencyFormat.format(transaction['interestAmount'])),
                          ],
                        ),
                      ],
                      if (transaction['notes']?.isNotEmpty == true) ...[
                        const SizedBox(height: 20),
                        _DetailSection(
                          title: 'Notas',
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                transaction['notes'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (transaction['loan']?['id'] != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showLoanDetail(transaction['loan']['id'].toString());
                          },
                          icon: const Icon(Icons.account_balance_wallet),
                          label: Text('Ver Préstamo #${transaction['loan']['id']}'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (transaction['loan']?['id'] != null)
                      const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');
    final filtered = filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              tooltip: 'Filtros',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      endDrawer: _buildFilterDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${filtered.length} transacciones', style: AppTextStyles.h3),
                    if (filtered.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _exportTransactions(filtered),
                        icon: const Icon(Icons.download),
                        label: const Text('Exportar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay transacciones', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          if (item == null) return const SizedBox.shrink();
                          
                          // Determinar si es préstamo o transacción
                          final isLoan = selectedFilter == 'Préstamo';
                          final isPayment = !isLoan && item['type'] == 'PAYMENT';
                          
                          return Stack(
                            children: [
                              Card(
                                margin: const EdgeInsets.only(bottom: 12, top: 8),
                                child: InkWell(
                                  onTap: () => isLoan ? _showLoanDetail(item['id'].toString()) : _showTransactionDetail(item),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: (isLoan ? AppColors.warning : (isPayment ? AppColors.success : AppColors.primary)).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            isLoan ? Icons.account_balance_wallet : (isPayment ? Icons.arrow_downward : Icons.arrow_upward),
                                            color: isLoan ? AppColors.warning : (isPayment ? AppColors.success : AppColors.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isLoan 
                                                    ? 'Cliente: ${item['user']?['name'] ?? 'N/A'}'
                                                    : 'Préstamo ID: ${item['loan']?['id'] ?? 'N/A'}',
                                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isLoan 
                                                    ? 'Préstamo • ${item['id']}'
                                                    : '${isPayment ? 'Pago' : 'Transacción'} • ${item['id']}',
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isLoan 
                                                    ? DateFormat('dd/MM/yyyy').format(DateTime.parse(item['startDate']))
                                                    : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['date'])),
                                                style: AppTextStyles.caption,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currencyFormat.format(item['amount'] ?? 0),
                                              style: AppTextStyles.body.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: isLoan ? AppColors.warning : (isPayment ? AppColors.success : AppColors.primary),
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isLoan ? AppColors.warning : AppColors.success).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isLoan 
                                                    ? _getLoanStatusText(item['status']?.toString())
                                                    : _getPaymentMethodText(item['paymentMethod']?.toString() ?? ''),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isLoan ? AppColors.warning : AppColors.success,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Burbuja con código de usuario
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
                                    isLoan 
                                        ? '${item['user']?['userCode'] ?? 'N/A'}'
                                        : '${item['loan']?['user']?['userCode'] ?? 'N/A'}',
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSummaryModal(NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.analytics),
        label: const Text('Resumen'),
      ),
    );
  }

  void _showEditPaymentBreakdown(BuildContext context, Map<String, dynamic> transaction, NumberFormat currencyFormat) {
    final principalController = TextEditingController(
      text: NumberFormat('#,###', 'es_CO').format(transaction['principalAmount'] ?? 0),
    );
    final interestController = TextEditingController(
      text: NumberFormat('#,###', 'es_CO').format(transaction['interestAmount'] ?? 0),
    );
    final notesController = TextEditingController(
      text: transaction['notes']?.toString() ?? '',
    );
    String selectedPaymentMethod = _getPaymentMethodFromBackend(transaction['paymentMethod']?.toString() ?? 'CASH');

    // Variables locales para mostrar cambios inmediatos
    double currentPrincipal = (transaction['principalAmount'] ?? 0).toDouble();
    double currentInterest = (transaction['interestAmount'] ?? 0).toDouble();
    String currentPaymentMethod = selectedPaymentMethod;
    String currentNotes = transaction['notes']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Editar Desglose del Pago'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID Transacción: ${transaction['id']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: principalController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) async {
                    String text = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (text.isNotEmpty) {
                      final formatted = NumberFormat('#,###', 'es_CO').format(int.parse(text));
                      principalController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                      
                      // Actualizar inmediatamente
                      currentPrincipal = double.parse(text);
                      await _updateTransactionField(transaction['id'].toString(), 'principalAmount', currentPrincipal);
                      setState(() {}); // Actualizar la pantalla principal
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Capital',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: interestController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) async {
                    String text = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (text.isNotEmpty) {
                      final formatted = NumberFormat('#,###', 'es_CO').format(int.parse(text));
                      interestController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                      
                      // Actualizar inmediatamente
                      currentInterest = double.parse(text);
                      await _updateTransactionField(transaction['id'].toString(), 'interestAmount', currentInterest);
                      setState(() {}); // Actualizar la pantalla principal
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Interés/Ganancia',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
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
                  onChanged: (value) async {
                    setModalState(() {
                      selectedPaymentMethod = value!;
                    });
                    
                    // Actualizar inmediatamente
                    currentPaymentMethod = value!;
                    await _updateTransactionField(transaction['id'].toString(), 'paymentMethod', _mapPaymentMethodToBackend(currentPaymentMethod));
                    setState(() {}); // Actualizar la pantalla principal
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  onChanged: (value) async {
                    // Actualizar inmediatamente con debounce
                    currentNotes = value;
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      if (currentNotes == value) { // Solo actualizar si no ha cambiado
                        await _updateTransactionField(transaction['id'].toString(), 'notes', currentNotes);
                        setState(() {}); // Actualizar la pantalla principal
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Los cambios se guardan automáticamente',
                        style: TextStyle(fontSize: 12, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadTransactions(); // Recargar para asegurar sincronización
              },
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentMethodFromBackend(String backendMethod) {
    switch (backendMethod) {
      case 'CASH':
        return 'Efectivo';
      case 'TRANSFER':
        return 'Transferencia';
      case 'MIXED':
        return 'Mixto';
      default:
        return 'Efectivo';
    }
  }

  String _mapPaymentMethodToBackend(String frontendMethod) {
    switch (frontendMethod) {
      case 'Efectivo':
        return 'CASH';
      case 'Transferencia':
        return 'TRANSFER';
      case 'Mixto':
        return 'MIXED';
      default:
        return 'CASH';
    }
  }

  Future<void> _updateTransactionField(String transactionId, String field, dynamic value) async {
    try {
      await ApiService.updateTransactionField(
        transactionId: transactionId,
        field: field,
        value: value,
      );
    } catch (e) {
      // Silencioso para no interrumpir la edición
      print('Error actualizando campo $field: $e');
    }
  }

  Future<void> _updateTransactionBreakdown(
    BuildContext context,
    String transactionId,
    double principalAmount,
    double interestAmount,
    String paymentMethod,
    String notes,
    NumberFormat currencyFormat,
  ) async {
    try {
      await ApiService.updateTransaction(
        transactionId: transactionId,
        principalAmount: principalAmount,
        interestAmount: interestAmount,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transacción actualizada correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Recargar las transacciones
      await _loadTransactions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar transacción: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanInfoDialog extends StatelessWidget {
  final Map<String, dynamic> loan;

  const _LoanInfoDialog({required this.loan});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_CO');
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información del Préstamo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${loan['id']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (loan['user'] != null) ...[
                      _DetailSection(
                        title: 'Cliente',
                        children: [
                          _DetailRow('Nombre', loan['user']['name'] ?? 'N/A'),
                          _DetailRow('Teléfono', loan['user']['phone'] ?? 'N/A'),
                          _DetailRow('Email', loan['user']['email'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    _DetailSection(
                      title: 'Detalles del Préstamo',
                      children: [
                        _DetailRow('Monto', currencyFormat.format(loan['amount'] ?? 0)),
                        _DetailRow('Tipo de Préstamo', loan['loanType'] ?? 'N/A'),
                        _DetailRow('Forma de Pago', loan['paymentFrequency'] ?? 'N/A'),
                        _DetailRow('Tasa de Interés', '${loan['interestRate'] ?? 0}%'),
                        _DetailRow('Cuotas Totales', '${loan['installments'] ?? 0}'),
                        _DetailRow('Cuotas Pagadas', '${loan['paidInstallments'] ?? 0}'),
                        _DetailRow('Estado', loan['status'] ?? 'N/A'),
                        if (loan['startDate'] != null)
                          _DetailRow('Fecha Inicio', DateFormat('dd/MM/yyyy').format(DateTime.parse(loan['startDate']))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}