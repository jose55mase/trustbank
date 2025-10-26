import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../organisms/navbar.dart';
import '../../molecules/dashboard_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc()..add(LoadDashboardData()),
      child: Scaffold(
        appBar: const Navbar(title: 'Dashboard'),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is DashboardError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            
            if (state is DashboardLoaded) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8,
                      children: [
                        DashboardCard(
                          title: 'Used Space',
                          value: '49/50 GB',
                          icon: Icons.storage,
                          color: Colors.orange,
                          subtitle: 'Get more space',
                        ),
                        DashboardCard(
                          title: 'Revenue',
                          value: '\$${state.stats.revenue.toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                          subtitle: 'Last 24 Hours',
                        ),
                        DashboardCard(
                          title: 'Fixed Issues',
                          value: '75',
                          icon: Icons.bug_report,
                          color: Colors.red,
                          subtitle: 'Tracked from Github',
                        ),
                        DashboardCard(
                          title: 'Followers',
                          value: '+245',
                          icon: Icons.people,
                          color: Colors.blue,
                          subtitle: 'Just Updated',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
            
            return const SizedBox();
          },
        ),
      ),
    );
  }
}