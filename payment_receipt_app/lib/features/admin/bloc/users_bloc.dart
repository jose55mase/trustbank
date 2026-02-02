import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../../../services/user_management_service.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  int _currentPage = 0;
  final int _pageSize = 20;
  List<AdminUser> _allUsers = [];
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  UsersBloc() : super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<LoadMoreUsers>(_onLoadMoreUsers);
    on<UpdateUserStatus>(_onUpdateUserStatus);
    on<FilterUsers>(_onFilterUsers);
    on<RefreshUsers>(_onRefreshUsers);
  }

  void _onLoadUsers(LoadUsers event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      _currentPage = 0;
      _allUsers.clear();
      _hasMoreData = true;
      
      final response = await UserManagementService.getUsersPaginated(
        page: _currentPage,
        size: _pageSize,
      );
      
      _allUsers = response['users'];
      _hasMoreData = response['hasNext'];
      
      emit(UsersLoaded(
        users: _allUsers,
        hasMoreData: _hasMoreData,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  void _onLoadMoreUsers(LoadMoreUsers event, Emitter<UsersState> emit) async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    try {
      _isLoadingMore = true;
      emit(UsersLoaded(
        users: _allUsers,
        hasMoreData: _hasMoreData,
        isLoadingMore: true,
      ));
      
      _currentPage++;
      final response = await UserManagementService.getUsersPaginated(
        page: _currentPage,
        size: _pageSize,
      );
      
      _allUsers.addAll(response['users']);
      _hasMoreData = response['hasNext'];
      _isLoadingMore = false;
      
      emit(UsersLoaded(
        users: _allUsers,
        hasMoreData: _hasMoreData,
        isLoadingMore: false,
      ));
    } catch (e) {
      _isLoadingMore = false;
      emit(UsersError(e.toString()));
    }
  }

  void _onRefreshUsers(RefreshUsers event, Emitter<UsersState> emit) async {
    add(LoadUsers());
  }

  void _onUpdateUserStatus(UpdateUserStatus event, Emitter<UsersState> emit) async {
    try {
      final statusString = event.status.name.toUpperCase();
      await UserManagementService.updateUserStatus(event.userId, statusString);
      add(LoadUsers()); // Recargar usuarios
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  void _onFilterUsers(FilterUsers event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final statusString = event.status?.name.toUpperCase();
      final users = await UserManagementService.filterUsers(
        status: statusString,
        searchQuery: event.searchQuery,
      );
      
      // Ordenar por fecha de creación descendente
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
}