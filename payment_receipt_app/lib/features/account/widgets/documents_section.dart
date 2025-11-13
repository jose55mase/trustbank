import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../services/user_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/image_storage_service.dart';
import '../../../services/document_api_service.dart';
import 'upload_document_images_dialog.dart';
import 'dart:typed_data';

class DocumentsSection extends StatefulWidget {
  const DocumentsSection({super.key});

  @override
  State<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends State<DocumentsSection> {
  List<dynamic> userDocuments = [];
  Map<String, Uint8List?> localImages = {};
  Map<String, String> imageStatuses = {};
  bool isLoadingDocs = true;

  @override
  void initState() {
    super.initState();
    _loadUserDocuments();
    _loadUserImages();
  }

  Future<void> _loadUserDocuments() async {
    try {
      final docs = await UserService.getUserDocuments();
      if (mounted) {
        setState(() {
          userDocuments = docs;
          isLoadingDocs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingDocs = false;
        });
      }
    }
  }

  Future<void> _loadUserImages() async {
    try {
      final user = await AuthService.getCurrentUser();
      
      // Cargar imágenes locales
      final documentFront = await ImageStorageService.getDocumentFront();
      final documentBack = await ImageStorageService.getDocumentBack();
      final clientPhoto = await ImageStorageService.getClientPhoto();
      
      Map<String, String> apiStatuses = {};
      
      // Intentar cargar estados desde la API
      if (user != null) {
        try {
          final userDocs = await DocumentApiService.getUserDocuments(user['id']);
          apiStatuses = {
            'documentFront': userDocs['documentFromStatus'] ?? 'PENDING',
            'documentBack': userDocs['documentBackStatus'] ?? 'PENDING',
            'clientPhoto': userDocs['fotoStatus'] ?? 'PENDING',
          };
        } catch (e) {
          // Fallback a estados locales
          apiStatuses = {
            'documentFront': await ImageStorageService.getDocumentFrontStatus(),
            'documentBack': await ImageStorageService.getDocumentBackStatus(),
            'clientPhoto': await ImageStorageService.getClientPhotoStatus(),
          };
        }
      } else {
        // Estados locales
        apiStatuses = {
          'documentFront': await ImageStorageService.getDocumentFrontStatus(),
          'documentBack': await ImageStorageService.getDocumentBackStatus(),
          'clientPhoto': await ImageStorageService.getClientPhotoStatus(),
        };
      }
      
      if (mounted) {
        setState(() {
          localImages = {
            'documentFront': documentFront,
            'documentBack': documentBack,
            'clientPhoto': clientPhoto,
          };
          imageStatuses = apiStatuses;
        });
      }
    } catch (e) {
      // Error loading images
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: TBColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(TBSpacing.md),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TBColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: TBSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mis Documentos',
                      style: TBTypography.headlineSmall,
                    ),
                    IconButton(
                      onPressed: () => _showUploadDialog(context),
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: TBColors.primary,
                        foregroundColor: TBColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (localImages.isNotEmpty) _buildImagesSection(),
          Expanded(
            child: isLoadingDocs
                ? const Center(child: CircularProgressIndicator())
                : userDocuments.isEmpty && _hasNoImages()
                  ? _buildEmptyState()
                  : _buildDocumentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: TBColors.grey500,
          ),
          const SizedBox(height: TBSpacing.md),
          Text(
            'No hay documentos',
            style: TBTypography.titleMedium.copyWith(
              color: TBColors.grey600,
            ),
          ),
          const SizedBox(height: TBSpacing.sm),
          Text(
            'Sube tu primer documento para comenzar',
            style: TBTypography.bodySmall.copyWith(
              color: TBColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.md),
      itemCount: userDocuments.length,
      itemBuilder: (context, index) {
        final doc = userDocuments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: TBSpacing.sm),
          padding: const EdgeInsets.all(TBSpacing.md),
          decoration: BoxDecoration(
            color: TBColors.grey100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TBColors.grey300.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getDocumentIcon(doc['documentType']),
                color: TBColors.primary,
              ),
              const SizedBox(width: TBSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDocumentTypeLabel(doc['documentType']),
                      style: TBTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      doc['fileName'] ?? 'Documento',
                      style: TBTypography.bodySmall.copyWith(
                        color: TBColors.grey600,
                      ),
                    ),
                    if (doc['uploadedAt'] != null)
                      Text(
                        'Subido: ${UserService.formatDate(doc['uploadedAt'])}',
                        style: TBTypography.labelSmall.copyWith(
                          color: TBColors.grey500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getDocStatusColor(doc['status']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getDocumentStatusLabel(doc['status']),
                  style: TBTypography.labelSmall.copyWith(
                    color: TBColors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getDocumentIcon(String? type) {
    if (type == null) return Icons.description;
    
    switch (type.toUpperCase()) {
      case 'ID':
      case 'IDENTIFICATION':
        return Icons.badge;
      case 'PROOF_OF_ADDRESS':
      case 'ADDRESS':
        return Icons.home;
      case 'INCOME_PROOF':
      case 'INCOME':
        return Icons.receipt_long;
      case 'BANK_STATEMENT':
      case 'STATEMENT':
        return Icons.account_balance;
      default:
        return Icons.description;
    }
  }

  String _getDocumentTypeLabel(String? type) {
    if (type == null) return 'Documento';
    
    switch (type.toUpperCase()) {
      case 'ID':
      case 'IDENTIFICATION':
        return 'Cédula/Pasaporte';
      case 'PROOF_OF_ADDRESS':
      case 'ADDRESS':
        return 'Comprobante de domicilio';
      case 'INCOME_PROOF':
      case 'INCOME':
        return 'Comprobante de ingresos';
      case 'BANK_STATEMENT':
      case 'STATEMENT':
        return 'Estado de cuenta';
      default:
        return type;
    }
  }

  String _getDocumentStatusLabel(String? status) {
    if (status == null) return 'Desconocido';
    
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'Aprobado';
      case 'PENDING':
        return 'Pendiente';
      case 'REJECTED':
        return 'Rechazado';
      default:
        return status;
    }
  }

  Color _getDocStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return TBColors.success;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return TBColors.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildImagesSection() {
    final imageCount = _getImageCount();
    return Container(
      padding: const EdgeInsets.all(TBSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Documentos con Imágenes',
                style: TBTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TBColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$imageCount/3',
                  style: TBTypography.labelMedium.copyWith(
                    color: TBColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TBSpacing.sm),
          Row(
            children: [
              Expanded(child: _buildImageCard('Frontal', localImages['documentFront'], imageStatuses['documentFront'], Icons.credit_card)),
              const SizedBox(width: TBSpacing.sm),
              Expanded(child: _buildImageCard('Reverso', localImages['documentBack'], imageStatuses['documentBack'], Icons.flip_to_back)),
              const SizedBox(width: TBSpacing.sm),
              Expanded(child: _buildImageCard('Foto', localImages['clientPhoto'], imageStatuses['clientPhoto'], Icons.person)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String title, Uint8List? imageBytes, String? status, IconData icon) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: TBColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusBorderColor(status)),
      ),
      child: Stack(
        children: [
          imageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : _buildPlaceholder(title, icon),
          if (imageBytes != null && status != null)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TBTypography.labelSmall.copyWith(
                    color: TBColors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: TBColors.grey500, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: TBTypography.labelSmall.copyWith(color: TBColors.grey600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  bool _hasNoImages() {
    return localImages['documentFront'] == null && 
           localImages['documentBack'] == null && 
           localImages['clientPhoto'] == null;
  }

  int _getImageCount() {
    int count = 0;
    if (localImages['documentFront'] != null) count++;
    if (localImages['documentBack'] != null) count++;
    if (localImages['clientPhoto'] != null) count++;
    return count;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return TBColors.success;
      case 'REJECTED':
        return TBColors.error;
      default:
        return Colors.orange;
    }
  }

  Color _getStatusBorderColor(String? status) {
    if (status == null) return TBColors.grey300;
    switch (status) {
      case 'APPROVED':
        return TBColors.success;
      case 'REJECTED':
        return TBColors.error;
      default:
        return Colors.orange;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'APPROVED':
        return 'OK';
      case 'REJECTED':
        return 'X';
      default:
        return '?';
    }
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UploadDocumentImagesDialog(),
    ).then((_) => _loadUserImages());
  }
}