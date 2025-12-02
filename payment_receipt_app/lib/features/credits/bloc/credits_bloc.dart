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
      final response = await ApiService.getUserCreditApplications(userId);
      
      if (response['status'] == 200) {
        final applications = (response['data'] as List)
            .map((json) => CreditApplication.fromJson(json))
            .toList();
        emit(CreditsLoaded(applications: applications));
      } else {
        emit(CreditsError(message: response['message'] ?? 'Error al cargar solicitudes'));
      }
    } catch (e) {
      emit(CreditsError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSubmitCreditApplication(
    SubmitCreditApplication event,
    Emitter<CreditsState> emit,
  ) async {
    emit(CreditsSubmitting());
    try {
      final userId = await AuthService.getCurrentUserId() ?? 1;
      final response = await ApiService.applyForCredit({
        'userId': userId,
        'creditType': event.creditType,
        'amount': event.amount,
        'termMonths': event.termMonths,
        'interestRate': event.interestRate,
        'monthlyPayment': event.monthlyPayment,
      });
      
      if (response['status'] == 201) {
        final application = CreditApplication.fromJson(response['data']);
        emit(CreditApplicationSubmitted(application: application));
      } else {
        emit(CreditsError(message: response['message'] ?? 'Error al enviar solicitud'));
      }
    } catch (e) {
      emit(CreditsError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCheckApplicationStatus(
    CheckApplicationStatus event,
    Emitter<CreditsState> emit,
  ) async {
    try {
      final response = await ApiService.getCreditApplicationStatus(event.applicationId);
      
      if (response['status'] == 200) {
        final application = CreditApplication.fromJson(response['data']);
        emit(CreditStatusUpdated(application: application));
      } else {
        emit(CreditsError(message: response['message'] ?? 'Error al verificar estado'));
      }
    } catch (e) {
      emit(CreditsError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}