import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/payment_receipt.dart';
import '../utils/currency_formatter.dart';

class PdfService {
  static Future<void> generateAndDownloadReceipt(PaymentReceipt receipt) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with TrustBank branding and logo
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [PdfColor.fromHex('#6C63FF'), PdfColor.fromHex('#9C96FF')],
                  ),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TrustBank',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'COMPROBANTE DE TRANSACCIÓN',
                          style: pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    pw.Image(
                      logo,
                      width: 80,
                      height: 60,
                      fit: pw.BoxFit.contain,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Transaction details
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DETALLES DE LA TRANSACCIÓN',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#6C63FF'),
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    _buildInfoRow('ID de Transacción:', receipt.id),
                    _buildInfoRow('Tipo:', receipt.transactionType),
                    _buildInfoRow('Fecha y Hora:', DateFormat('dd/MM/yyyy - HH:mm:ss').format(receipt.date)),
                    _buildInfoRow('Estado:', receipt.status),
                    _buildInfoRow('Código de Autorización:', receipt.authorizationCode),
                    
                    pw.SizedBox(height: 20),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F8F9FA'),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'MONTO TOTAL',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            CurrencyFormatter.format(receipt.amount),
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#6C63FF'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 25),
              
              // Client information
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'REMITENTE',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#6C63FF'),
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          _buildSmallInfoRow('Nombre:', receipt.senderName),
                          _buildSmallInfoRow('Cuenta:', receipt.senderAccount),
                          _buildSmallInfoRow('Email:', receipt.senderEmail),
                          _buildSmallInfoRow('Teléfono:', receipt.senderPhone),
                          _buildSmallInfoRow('Dirección:', receipt.senderAddress),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'BENEFICIARIO',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#6C63FF'),
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          _buildSmallInfoRow('Nombre:', receipt.recipientName),
                          _buildSmallInfoRow('Cuenta:', receipt.recipientAccount),
                          _buildSmallInfoRow('Banco:', receipt.bankName),
                          _buildSmallInfoRow('Concepto:', receipt.concept),
                          _buildSmallInfoRow('Referencia:', receipt.reference),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8F9FA'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Este comprobante es válido como constancia oficial de la transacción.',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'TrustBank - Tu banco de confianza | www.trustbank.com',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildSmallInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  static Future<pw.ImageProvider> _loadLogo() async {
    final ByteData data = await rootBundle.load('assets/images/logobanklettersblak.png');
    return pw.MemoryImage(data.buffer.asUint8List());
  }
}