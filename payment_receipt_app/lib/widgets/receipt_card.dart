import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_receipt.dart';
import '../utils/currency_formatter.dart';

class ReceiptCard extends StatelessWidget {
  final PaymentReceipt receipt;
  final VoidCallback onDownloadPdf;

  const ReceiptCard({
    super.key,
    required this.receipt,
    required this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${receipt.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    receipt.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Tipo:', receipt.transactionType),
            _buildInfoRow('De:', receipt.senderName),
            _buildInfoRow('Para:', receipt.recipientName),
            _buildInfoRow('Monto:', CurrencyFormatter.format(receipt.amount)),
            _buildInfoRow('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(receipt.date)),
            _buildInfoRow('Concepto:', receipt.concept),
            _buildInfoRow('Autorización:', receipt.authorizationCode),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: onDownloadPdf,
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}