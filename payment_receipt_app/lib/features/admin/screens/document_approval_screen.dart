import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../services/api_service.dart';

class DocumentApprovalScreen extends StatefulWidget {
  const DocumentApprovalScreen({Key? key}) : super(key: key);

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
      final response = await ApiService.get('/admin/documents/pending');
      if (response['success']) {
        setState(() {
          pendingUsers = (response['data'] as List)
              .cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
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
                    style: TBTypography.bodyLarge,
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
              'Documentos pendientes:',
              style: TBTypography.titleSmall,
            ),
            const SizedBox(height: 8),
            if (user['fotoStatus'] == 'PENDING')
              _buildDocumentRow('Foto de perfil', 'foto', user),
            if (user['documentFromStatus'] == 'PENDING')
              _buildDocumentRow('Documento frontal', 'documentFrom', user),
            if (user['documentBackStatus'] == 'PENDING')
              _buildDocumentRow('Documento trasero', 'documentBack', user),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(String title, String documentType, Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TBTypography.bodyMedium),
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
      builder: (context) => AlertDialog(
        title: Text(title),
        content: imageUrl != null
            ? Image.network(
                'https://guardianstrustbank.com:8081/api/user/uploads/img/$imageUrl',
                errorBuilder: (context, error, stackTrace) =>
                    const Text('Error al cargar la imagen'),
              )
            : const Text('No hay imagen disponible'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
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
    );
  }
}