import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/dummy_data.dart';
import '../../domain/models/user.dart';
import '../molecules/user_card.dart';
import '../widgets/app_drawer.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String searchQuery = '';
  DateTimeRange? dateRange;

  List<User> get filteredUsers {
    var users = DummyData.users;

    if (searchQuery.isNotEmpty) {
      users = users.where((user) {
        return user.name.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (dateRange != null) {
      users = users.where((user) {
        return user.registrationDate.isAfter(dateRange!.start.subtract(const Duration(days: 1))) &&
               user.registrationDate.isBefore(dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return users;
  }

  @override
  Widget build(BuildContext context) {
    final users = filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios Registrados'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                    hintText: 'Buscar por nombre',
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
                Text(
                  '${users.length} usuario${users.length != 1 ? 's' : ''} encontrado${users.length != 1 ? 's' : ''}',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 16),
                ...users.map((user) {
                  final userLoans = DummyData.getLoansByUserId(user.id);
                  final totalLent = userLoans.fold<double>(0, (sum, loan) => sum + loan.amount);

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
