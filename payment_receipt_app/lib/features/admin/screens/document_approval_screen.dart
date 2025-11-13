import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../design_system/components/atoms/tb_button.dart';
import '../../../services/image_storage_service.dart';
import '../../../services/document_api_service.dart';
import '../../../services/auth_service.dart';

class DocumentApprovalScreen extends StatefulWidget {
  const DocumentApprovalScreen({super.key});

  @override
  State<DocumentApprovalScreen> createState() => _DocumentApprovalScreenState();
}

class _DocumentApprovalScreenState extends State<DocumentApprovalScreen> {
  Map<String, Uint8List?> documents = {};
  Map<String, String> statuses = {};
  List<Map<String, dynamic>> usersWithDocuments = [];
  int selectedUserIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      // Cargar usuarios con documentos desde la API
      final users = await DocumentApiService.getAllUsersWithDocuments();
      
      // Para demo, usar datos locales si no hay conexión
      final documentFront = await ImageStorageService.getDocumentFront();
      final documentBack = await ImageStorageService.getDocumentBack();
      final clientPhoto = await ImageStorageService.getClientPhoto();
      
      final frontStatus = await ImageStorageService.getDocumentFrontStatus();
      final backStatus = await ImageStorageService.getDocumentBackStatus();
      final photoStatus = await ImageStorageService.getClientPhotoStatus();

      setState(() {
        usersWithDocuments = users;
        documents = {
          'documentFront': documentFront,
          'documentBack': documentBack,
          'clientPhoto': clientPhoto,
        };
        statuses = {
          'documentFront': frontStatus,
          'documentBack': backStatus,
          'clientPhoto': photoStatus,
        };
        isLoading = false;
      });
    } catch (e) {
      // Fallback a datos locales
      final documentFront = await ImageStorageService.getDocumentFront();
      final documentBack = await ImageStorageService.getDocumentBack();
      final clientPhoto = await ImageStorageService.getClientPhoto();
      
      final frontStatus = await ImageStorageService.getDocumentFrontStatus();
      final backStatus = await ImageStorageService.getDocumentBackStatus();
      final photoStatus = await ImageStorageService.getClientPhotoStatus();

      setState(() {
        documents = {
          'documentFront': documentFront,
          'documentBack': documentBack,
          'clientPhoto': clientPhoto,
        };
        statuses = {
          'documentFront': frontStatus,
          'documentBack': backStatus,
          'clientPhoto': photoStatus,
        };
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aprobar Documentos', style: TBTypography.headlineMedium),
        backgroundColor: TBColors.primary,
        foregroundColor: TBColors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(TBSpacing.md),
              child: Column(
                children: [
                  _buildDocumentCard('Documento Frontal', 'documentFront', Icons.credit_card),
                  const SizedBox(height: TBSpacing.md),
                  _buildDocumentCard('Documento Reverso', 'documentBack', Icons.flip_to_back),
                  const SizedBox(height: TBSpacing.md),
                  _buildDocumentCard('Foto del Cliente', 'clientPhoto', Icons.person),
                ],
              ),
            ),
    );
  }

  Widget _buildDocumentCard(String title, String key, IconData icon) {
    final imageBytes = documents[key];
    final status = statuses[key] ?? 'PENDING';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(TBSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: TBColors.primary),
                const SizedBox(width: TBSpacing.sm),
                Text(title, style: TBTypography.titleMedium),
                const Spacer(),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: TBSpacing.md),
            if (imageBytes != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TBColors.grey300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(imageBytes, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: TBColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TBColors.grey300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 48, color: TBColors.grey500),
                    Text('No subido', style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600)),
                  ],
                ),
              ),
            if (imageBytes != null) ...[
              const SizedBox(height: TBSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TBButton(
                      text: 'Aprobar',
                      type: TBButtonType.primary,
                      onPressed: status == 'APPROVED' ? null : () => _updateStatus(key, 'APPROVED'),
                    ),
                  ),
                  const SizedBox(width: TBSpacing.sm),
                  Expanded(
                    child: TBButton(
                      text: 'Rechazar',
                      type: TBButtonType.outline,
                      onPressed: status == 'REJECTED' ? null : () => _updateStatus(key, 'REJECTED'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'APPROVED':
        color = TBColors.success;
        label = 'Aprobado';
        break;
      case 'REJECTED':
        color = TBColors.error;
        label = 'Rechazado';
        break;
      default:
        color = Colors.orange;
        label = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TBTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _updateStatus(String key, String newStatus) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        // Actualizar en la base de datos
        await DocumentApiService.updateDocumentStatus(
          userId: user['id'],
          documentType: key,
          status: newStatus,
        );
      }
      
      // Actualizar localmente
      switch (key) {
        case 'documentFront':
          await ImageStorageService.setDocumentFrontStatus(newStatus);
          break;
        case 'documentBack':
          await ImageStorageService.setDocumentBackStatus(newStatus);
          break;
        case 'clientPhoto':
          await ImageStorageService.setClientPhotoStatus(newStatus);
          break;
      }

      setState(() {
        statuses[key] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Documento ${newStatus == 'APPROVED' ? 'aprobado' : 'rechazado'}'),
          backgroundColor: newStatus == 'APPROVED' ? TBColors.success : TBColors.error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: TBColors.error,
        ),
      );
    }
  }
}