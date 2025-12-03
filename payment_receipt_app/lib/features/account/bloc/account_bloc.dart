import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/account_model.dart';
import '../../../services/api_service.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  static UserAccount _mockAccount = UserAccount(
    id: 1,
    username: 'juan_perez',
    email: 'juan@email.com',
    firstName: 'Juan',
    lastName: 'Pérez',
    accountStatus: 'ACTIVE',
    fotoStatus: 'APPROVED',
    documentFromStatus: 'PENDING',
    documentBackStatus: 'PENDING',
    balance: 150000,
    status: true,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
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
      // Simular subida de archivo
      await ApiService.createAdminRequest({
        'requestType': 'DOCUMENT_UPLOAD',
        'userId': 1,
        'amount': 0.0,
        'details': 'Documento subido: ${event.fileName}',
      });
      
      emit(AccountLoaded(account: _mockAccount));
    } catch (e) {
      emit(AccountLoaded(account: _mockAccount));
    }
  }

  static void updateDocumentStatus(String documentType, String status) {
    switch (documentType) {
      case 'foto':
        _mockAccount = _mockAccount.copyWith(fotoStatus: status);
        break;
      case 'documentFrom':
        _mockAccount = _mockAccount.copyWith(documentFromStatus: status);
        break;
      case 'documentBack':
        _mockAccount = _mockAccount.copyWith(documentBackStatus: status);
        break;
    }
  }
}