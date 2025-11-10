import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/account_model.dart';
import '../../../services/api_service.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  static UserAccount _mockAccount = UserAccount(
    userId: 'user1',
    userName: 'Juan Pérez',
    email: 'juan@email.com',
    status: AccountStatus.pending,
    documents: [
      UserDocument(
        id: '1',
        type: DocumentType.id,
        fileName: 'cedula.pdf',
        filePath: '/documents/cedula.pdf',
        status: DocumentStatus.approved,
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        processedAt: DateTime.now().subtract(const Duration(days: 1)),
        adminNotes: 'Documento válido',
      ),
      UserDocument(
        id: '2',
        type: DocumentType.proofOfAddress,
        fileName: 'recibo_luz.pdf',
        filePath: '/documents/recibo_luz.pdf',
        status: DocumentStatus.pending,
        uploadedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ],
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  AccountBloc() : super(AccountInitial()) {
    on<LoadAccount>(_onLoadAccount);
    on<UploadDocument>(_onUploadDocument);
  }

  void _onLoadAccount(LoadAccount event, Emitter<AccountState> emit) {
    emit(AccountLoaded(account: _mockAccount));
  }

  void _onUploadDocument(UploadDocument event, Emitter<AccountState> emit) async {
    try {
      // Simular subida de archivo (en producción usar file_picker)
      final response = await ApiService.createAdminRequest({
        'requestType': 'DOCUMENT_UPLOAD',
        'userId': 1, // ID del usuario actual
        'amount': 0.0,
        'details': '${event.type.name}: ${event.fileName}',
      });

      final newDocument = UserDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: event.type,
        fileName: event.fileName,
        filePath: '/documents/${event.fileName}',
        status: DocumentStatus.pending,
        uploadedAt: DateTime.now(),
      );

      final updatedDocuments = [..._mockAccount.documents, newDocument];
      _mockAccount = _mockAccount.copyWith(documents: updatedDocuments);
      
      emit(AccountLoaded(account: _mockAccount));
    } catch (e) {
      // Manejar error
      emit(AccountLoaded(account: _mockAccount));
    }
  }

  static void updateDocumentStatus(String documentId, DocumentStatus status, String? notes) {
    final docIndex = _mockAccount.documents.indexWhere((d) => d.id == documentId);
    if (docIndex != -1) {
      final updatedDocuments = [..._mockAccount.documents];
      updatedDocuments[docIndex] = updatedDocuments[docIndex].copyWith(
        status: status,
        processedAt: DateTime.now(),
        adminNotes: notes,
      );
      _mockAccount = _mockAccount.copyWith(documents: updatedDocuments);
    }
  }
}