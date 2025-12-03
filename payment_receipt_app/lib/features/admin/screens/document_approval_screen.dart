import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../services/api_service.dart';

class DocumentApprovalScreen extends StatefulWidget {
  const DocumentApprovalScreen({super.key});

  @override
  State<DocumentApprovalScreen> createState() => _DocumentApprovalScreenState();
}

class _DocumentApprovalScreenState extends State<DocumentApprovalScreen> {
  List<Map<String, dynamic>> pendingUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingDocuments();
  }

  Future<void> _loadPendingDocuments() async {
    try {
      final response = await ApiService.getAllUsers();
      setState(() {
        pendingUsers = response
            .cast<Map<String, dynamic>>()
            .where((user) => _hasDocumentsToReview(user))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _hasDocumentsToReview(Map<String, dynamic> user) {
    return (user['foto'] != null && user['foto'].toString().isNotEmpty) ||
           (user['documentFrom'] != null && user['documentFrom'].toString().isNotEmpty) ||
           (user['documentBack'] != null && user['documentBack'].toString().isNotEmpty);
  }

  Future<void> _approveDocument(int userId, String documentType, String status) async {
    try {
      final response = await ApiService.put('/admin/documents/approve/$userId', {
        'documentType': documentType,
        'status': status,
      });

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: status == 'APPROVED' ? Colors.green : Colors.red,
          ),
        );
        _loadPendingDocuments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar la solicitud'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprobación de Documentos'),
        backgroundColor: TBColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingUsers.isEmpty
              ? const Center(
                  child: Text(
                    'No hay documentos pendientes de aprobación',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = pendingUsers[index];
                    return _buildUserCard(user);
                  },
                ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: TBColors.primary,
                  child: Text(
                    (user['fistName'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user['fistName'] ?? ''} ${user['lastName'] ?? ''}',
                        style: TBTypography.titleMedium,
                      ),
                      Text(
                        user['email'] ?? '',
                        style: TBTypography.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Documentos del usuario:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (user['foto'] != null && user['foto'].toString().isNotEmpty)
              _buildDocumentRow('Foto de perfil', 'foto', user),
            if (user['documentFrom'] != null && user['documentFrom'].toString().isNotEmpty)
              _buildDocumentRow('Documento frontal', 'documentFrom', user),
            if (user['documentBack'] != null && user['documentBack'].toString().isNotEmpty)
              _buildDocumentRow('Documento trasero', 'documentBack', user),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(String title, String documentType, Map<String, dynamic> user) {
    final status = _getDocumentStatus(user, documentType);
    final statusColor = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: statusColor.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showDocumentDialog(user, documentType, title),
            child: const Text('Ver'),
          ),
          ElevatedButton(
            onPressed: () => _approveDocument(user['id'], documentType, 'APPROVED'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 32),
            ),
            child: const Text('Aprobar'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _approveDocument(user['id'], documentType, 'REJECTED'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 32),
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  String _getDocumentStatus(Map<String, dynamic> user, String documentType) {
    switch (documentType) {
      case 'foto':
        return user['fotoStatus'] ?? 'PENDING';
      case 'documentFrom':
        return user['documentFromStatus'] ?? 'PENDING';
      case 'documentBack':
        return user['documentBackStatus'] ?? 'PENDING';
      default:
        return 'PENDING';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'APROBADO ✓';
      case 'REJECTED':
        return 'RECHAZADO ✗';
      case 'PENDING':
        return 'PENDIENTE ⏳';
      default:
        return status;
    }
  }

  void _showDocumentDialog(Map<String, dynamic> user, String documentType, String title) {
    String? imageUrl;
    switch (documentType) {
      case 'foto':
        imageUrl = user['foto'];
        break;
      case 'documentFrom':
        imageUrl = user['documentFrom'];
        break;
      case 'documentBack':
        imageUrl = user['documentBack'];
        break;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TBTypography.titleLarge),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: imageUrl != null
                    ? InteractiveViewer(
                        child: Image.network(
                          'http://localhost:8081/api/user/uploads/img/$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Error al cargar la imagen: $imageUrl'),
                              const SizedBox(height: 8),
                              Text('URL: http://localhost:8081/api/user/uploads/img/$imageUrl',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay imagen disponible'),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _approveDocument(user['id'], documentType, 'APPROVED');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Aprobar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _approveDocument(user['id'], documentType, 'REJECTED');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Rechazar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}