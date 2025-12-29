import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_text_styles.dart';

import '../../domain/models/user.dart';
import '../molecules/user_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/new_user_modal.dart';
import 'user_detail_screen.dart';
import '../../data/services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String searchQuery = '';
  DateTimeRange? dateRange;
  List<User> users = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    try {
      final fetchedUsers = await ApiService.getUsers();
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        debugPrint('Error: ${e.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _deleteUser(User user) async {
    try {
      await ApiService.deleteUser(user.id);
      setState(() {
        users.removeWhere((u) => u.id == user.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario ${user.name} eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar usuario: ${e.toString()}')),
        );
      }
    }
  }

  List<User> get filteredUsers {
    var filteredList = users;

    if (searchQuery.isNotEmpty) {
      filteredList = filteredList.where((user) {
        return user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
               user.userCode.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (dateRange != null) {
      filteredList = filteredList.where((user) {
        return user.registrationDate.isAfter(dateRange!.start.subtract(const Duration(days: 1))) &&
               user.registrationDate.isBefore(dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Usuarios Registrados'),
        ),
        drawer: const AppDrawer(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final filteredUsersList = filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios Registrados'),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o código',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: dateRange,
                    );
                    if (picked != null) {
                      setState(() => dateRange = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    dateRange == null
                        ? 'Filtrar por fecha de registro'
                        : '${DateFormat('dd/MM/yy').format(dateRange!.start)} - ${DateFormat('dd/MM/yy').format(dateRange!.end)}',
                  ),
                ),
                if (dateRange != null)
                  TextButton.icon(
                    onPressed: () => setState(() => dateRange = null),
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar filtro de fecha'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredUsersList.length} usuario${filteredUsersList.length != 1 ? 's' : ''} encontrado${filteredUsersList.length != 1 ? 's' : ''}',
                      style: AppTextStyles.h2,
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await NewUserModal.show(context);
                            if (result == true) {
                              _loadUsers();
                            }
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Usuario Nuevo'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadUsers,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...filteredUsersList.map((user) {
                  return FutureBuilder<List<dynamic>>(
                    future: ApiService.getLoansByUserId(user.id),
                    builder: (context, snapshot) {
                      final userLoans = snapshot.data ?? [];
                      final totalLent = userLoans.fold<double>(0, (sum, loan) => sum + (loan['amount'] ?? 0));
                      
                      return UserCard(
                        user: user,
                        activeLoans: userLoans.length,
                        totalLent: totalLent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailScreen(user: user),
                      ),
                    ),
                        onDelete: () => _deleteUser(user),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
