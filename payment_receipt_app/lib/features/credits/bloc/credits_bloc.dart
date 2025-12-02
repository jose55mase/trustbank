import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../models/credit_application.dart';
import 'credits_event.dart';
import 'credits_state.dart';

class CreditsBloc extends Bloc<CreditsEvent, CreditsState> {
  CreditsBloc() : super(CreditsInitial()) {
    on<LoadCreditApplications>(_onLoadCreditApplications);
    on<SubmitCreditApplication>(_onSubmitCreditApplication);
    on<CheckApplicationStatus>(_onCheckApplicationStatus);
  }

  Future<void> _onLoadCreditApplications(
    LoadCreditApplications event,
    Emitter<CreditsState> emit,
  ) async {
    emit(CreditsLoading());
    try {
      final userId = await AuthService.getCurrentUserId() ?? 1;
      
      // Obtener solicitudes de crédito desde AdminRequest
      final response = await ApiService.getAllAdminRequests();
      
      if (response['status'] == 200) {
        final allRequests = response['data'] as List;
        
        // Filtrar solo las solicitudes de crédito del usuario actual
        final creditRequests = allRequests
            .where((request) => 
                request['requestType'] == 'CREDIT' && 
                (request['userId'] as int) == userId)
            .toList();
        
        // Convertir AdminRequest a CreditApplication
        final applications = creditRequests.map((request) {
          return _mapAdminRequestToCreditApplication(request);
        }).toList();
        
        // Ordenar por fecha descendente
        applications.sort((a, b) => b.applicationDate.compareTo(a.applicationDate));
        
        emit(CreditsLoaded(applications: applications));
      } else {
        emit(CreditsError(message: response['message'] ?? 'Error al cargar solicitudes'));
      }
    } catch (e) {
      emit(CreditsError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
  
  CreditApplication _mapAdminRequestToCreditApplication(Map<String, dynamic> request) {
    // Parsear detalles de la solicitud
    final details = request['details'] ?? '';
    
    // Extraer información del campo details
    String creditType = 'Crédito Personal';
    int termMonths = 12;
    double interestRate = 12.5;
    double monthlyPayment = 0.0;
    
    if (details.contains('Crédito Personal')) creditType = 'Crédito Personal';
    else if (details.contains('Crédito Vehicular')) creditType = 'Crédito Vehicular';
    else if (details.contains('Crédito Hipotecario')) creditType = 'Crédito Hipotecario';
    
    // Intentar extraer valores numéricos de los detalles
    final monthsMatch = RegExp(r'(\d+) meses').firstMatch(details);
    if (monthsMatch != null) {
      termMonths = int.tryParse(monthsMatch.group(1) ?? '12') ?? 12;
    }
    
    final paymentMatch = RegExp(r'Cuota mensual: ([\d.]+)').firstMatch(details);
    if (paymentMatch != null) {
      monthlyPayment = double.tryParse(paymentMatch.group(1) ?? '0') ?? 0.0;
    }
    
    final rateMatch = RegExp(r'Tasa: ([\d.]+)%').firstMatch(details);
    if (rateMatch != null) {
      interestRate = double.tryParse(rateMatch.group(1) ?? '12.5') ?? 12.5;
    }
    
    // Mapear estado de AdminRequest a CreditStatus
    CreditStatus status;
    switch (request['status']) {
      case 'PENDING':
        status = CreditStatus.pending;
        break;
      case 'APPROVED':
        status = CreditStatus.approved;
        break;
      case 'REJECTED':
        status = CreditStatus.rejected;
        break;
      default:
        status = CreditStatus.pending;
    }
    
    return CreditApplication(
      id: (request['id'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      userId: (request['userId'] as int?) ?? 1,
      creditType: creditType,
      amount: (request['amount'] ?? 0.0).toDouble(),
      termMonths: termMonths,
      interestRate: interestRate,
      monthlyPayment: monthlyPayment,
      status: status,
      applicationDate: DateTime.parse(request['createdAt'] ?? DateTime.now().toIso8601String()),
      reviewDate: request['processedAt'] != null ? DateTime.parse(request['processedAt']) : null,
      rejectionReason: request['adminNotes'],
      approvalComments: status == CreditStatus.approved ? request['adminNotes'] : null,
    );
  }

  Future<void> _onSubmitCreditApplication(
    SubmitCreditApplication event,
    Emitter<CreditsState> emit,
  ) async {
    emit(CreditsSubmitting());
    try {
      final userId = await AuthService.getCurrentUserId() ?? 1;
      
      // Crear detalles de la solicitud de crédito
      // Crear detalles de la solicitud de crédito (no se usa directamente)
      // final creditDetails = {
      //   'creditType': event.creditType,
      //   'amount': event.amount,
      //   'termMonths': event.termMonths,
      //   'interestRate': event.interestRate,
      //   'monthlyPayment': event.monthlyPayment,
      //   'applicationDate': DateTime.now().toIso8601String(),
      // };
      
      // Enviar como AdminRequest
      final response = await ApiService.createAdminRequest({
        'requestType': 'CREDIT',
        'userId': userId,
        'amount': event.amount,
        'details': 'Solicitud de ${event.creditType} por ${event.amount} USD a ${event.termMonths} meses. Cuota mensual: ${event.monthlyPayment} USD. Tasa: ${event.interestRate}%',
        'description': 'Solicitud de crédito ${event.creditType}',
      });
      
      if (response['status'] == 201 || response['status'] == 200) {
        // Crear aplicación local basada en la respuesta del AdminRequest
        final adminRequest = response['data'];
        final application = CreditApplication(
          id: (adminRequest['id'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
          userId: userId,
          creditType: event.creditType,
          amount: event.amount,
          termMonths: event.termMonths,
          interestRate: event.interestRate,
          monthlyPayment: event.monthlyPayment,
          status: CreditStatus.pending, // Siempre inicia como pending
          applicationDate: DateTime.now(),
        );
        emit(CreditApplicationSubmitted(application: application));
      } else {
        emit(CreditsError(message: response['message'] ?? 'Error al enviar solicitud'));
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Personalizar mensajes de error comunes
      if (errorMessage.contains('conexión')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'La solicitud tomó demasiado tiempo. Inténtalo nuevamente.';
      } else if (errorMessage.contains('server')) {
        errorMessage = 'Error del servidor. Inténtalo más tarde.';
      }
      
      emit(CreditsError(message: errorMessage));
    }
  }

  Future<void> _onCheckApplicationStatus(
    CheckApplicationStatus event,
    Emitter<CreditsState> emit,
  ) async {
    try {
      // Obtener todas las solicitudes y buscar la específica
      final response = await ApiService.getAllAdminRequests();
      
      if (response['status'] == 200) {
        final allRequests = response['data'] as List;
        
        // Buscar la solicitud específica
        final requestData = allRequests.cast<Map<String, dynamic>>().firstWhere(
          (request) => (request['id'] as int) == event.applicationId,
          orElse: () => <String, dynamic>{},
        );
        
        if (requestData.isNotEmpty && requestData['requestType'] == 'CREDIT') {
          final application = _mapAdminRequestToCreditApplication(requestData);
          emit(CreditStatusUpdated(application: application));
        } else {
          emit(CreditsError(message: 'Solicitud no encontrada'));
        }
      } else {
        emit(CreditsError(message: response['message'] ?? 'Error al verificar estado'));
      }
    } catch (e) {
      emit(CreditsError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}