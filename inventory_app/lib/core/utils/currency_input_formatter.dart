import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    symbol: '',
    decimalDigits: 0,
    locale: 'es_CO',
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final numericValue = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numericValue.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final number = int.parse(numericValue);
    final formatted = _formatter.format(number).trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static int parse(String text) {
    final numericValue = text.replaceAll(RegExp(r'[^\d]'), '');
    return numericValue.isEmpty ? 0 : int.parse(numericValue);
  }
}
