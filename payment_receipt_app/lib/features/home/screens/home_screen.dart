import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../screens/receipt_list_screen.dart';
import '../../send_money/screens/send_money_screen.dart';
import '../../recharge/screens/recharge_screen.dart';
import '../../qr_pay/screens/qr_pay_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../credits/screens/credits_screen.dart';
import '../../../design_system/components/molecules/custom_header_painter.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/bloc/notifications_bloc.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../account/screens/account_screen.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_role.dart';

import '../../admin/screens/role_management_screen.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/loading_home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeBloc _homeBloc;

  @override
  void initState() {
    super.initState();
    _homeBloc = HomeBloc();
    _homeBloc.add(LoadUserData());
    
    // Refrescar datos cada 30 segundos para capturar cambios de saldo
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _homeBloc.add(RefreshData());
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _homeBloc.close();
    super.dispose();
  }

  bool _showBalance = true;
  int _notificationCount = NotificationsBloc.unreadCount;

  void _updateNotificationCount() {
    setState(() {
      _notificationCount = NotificationsBloc.unreadCount;
    });
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TBColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
            ),
            child: Icon(icon, color: TBColors.primary, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TBTypography.labelMedium.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, IconData icon, bool isIncome) {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.sm),
      decoration: BoxDecoration(
        color: TBColors.surface,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: TBColors.grey300.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isIncome ? TBColors.success.withOpacity(0.1) : TBColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isIncome ? TBColors.success : TBColors.grey600, size: 16),
          ),
          const SizedBox(width: TBSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TBTypography.labelMedium.copyWith(color: TBColors.grey600)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}\$${amount}',
            style: TBTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isIncome ? TBColors.success : TBColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSend() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SendMoneyScreen()));
  }

  void _navigateToRecharge() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const RechargeScreen()));
  }

  void _navigateToReceipts() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiptListScreen()));
  }

  void _navigateToQR() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const QRPayScreen()));
  }

  void _navigateToCredits() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreditsScreen()));
    _updateNotificationCount();
    _homeBloc.add(RefreshData());
  }

  void _navigateToAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
    );
  }

  void _navigateToRoles() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RoleManagementScreen()),
    );
  }

  Future<List<PopupMenuEntry<String>>> _buildMenuItems() async {
    final hasAdminAccess = await AuthService.hasPermission(Permission.viewAdminPanel);
    final hasRoleManagement = await AuthService.hasPermission(Permission.manageRoles);
    
    List<PopupMenuEntry<String>> items = [];
    
    if (hasAdminAccess) {
      items.add(const PopupMenuItem(
        value: 'admin',
        child: Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 20),
            SizedBox(width: 8),
            Text('Panel Admin'),
          ],
        ),
      ));
    }
    
    if (hasRoleManagement) {
      items.add(const PopupMenuItem(
        value: 'roles',
        child: Row(
          children: [
            Icon(Icons.people, size: 20),
            SizedBox(width: 8),
            Text('Gestión de Roles'),
          ],
        ),
      ));
    }
    
    items.addAll([
      const PopupMenuItem(
        value: 'account',
        child: Row(
          children: [
            Icon(Icons.person, size: 20),
            SizedBox(width: 8),
            Text('Mi Cuenta'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text('Cerrar sesión'),
          ],
        ),
      ),
    ]);
    
    return items;
  }

  void _navigateToAccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountScreen()),
    );
    _homeBloc.add(RefreshData());
  }

  void _logout() async {
    await AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeBloc,
      child: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          backgroundColor: TBColors.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: CustomPaint(
              painter: CustomHeaderPainter(),
              child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TBSpacing.screenPadding,
                  vertical: TBSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BlocBuilder<HomeBloc, HomeState>(
                          builder: (context, state) {
                            String userName = 'Usuario';
                            if (state is HomeLoaded) {
                              userName = state.user['firstName'] ?? 
                                        state.user['name'] ?? 
                                        state.user['username'] ?? 
                                        'Usuario';
                            }
                            return Text(
                              'Hola, $userName',
                              style: TBTypography.headlineMedium.copyWith(
                                color: TBColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                        Text(
                          'Bienvenido a TrustBank',
                          style: TBTypography.bodyMedium.copyWith(
                            color: TBColors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: TBColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: TBColors.white,
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationsScreen(),
                                    ),
                                  );
                                  _updateNotificationCount();
                                },
                              ),
                              if (_notificationCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '$_notificationCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: TBSpacing.sm),
                        Container(
                          decoration: BoxDecoration(
                            color: TBColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FutureBuilder<List<PopupMenuEntry<String>>>(
                            future: _buildMenuItems(),
                            builder: (context, snapshot) {
                              return PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.person_outline,
                                  color: TBColors.white,
                                ),
                                onSelected: (value) {
                                  if (value == 'logout') {
                                    _logout();
                                  } else if (value == 'admin') {
                                    _navigateToAdmin();
                                  } else if (value == 'roles') {
                                    _navigateToRoles();
                                  } else if (value == 'account') {
                                    _navigateToAccount();
                                  }
                                },
                                itemBuilder: (context) => snapshot.data ?? [],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
            ),
          ),
          body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(TBSpacing.screenPadding),
              child: LoadingHome(),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(TBSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Balance Card compacta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(TBSpacing.md),
              decoration: BoxDecoration(
                gradient: TBColors.primaryGradient,
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: TBColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo disponible',
                        style: TBTypography.labelMedium.copyWith(
                          color: TBColors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'USD ',
                            style: TBTypography.titleLarge.copyWith(
                              color: TBColors.white.withOpacity(0.9),
                            ),
                          ),
                          BlocBuilder<HomeBloc, HomeState>(
                            builder: (context, state) {
                              String balance = '0.00';
                              if (state is HomeLoaded) {
                                balance = state.balance.toStringAsFixed(2);
                              }
                              return Text(
                                _showBalance ? balance : '••••••',
                                style: TBTypography.headlineMedium.copyWith(
                                  color: TBColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _homeBloc.add(RefreshData());
                        },
                        icon: Icon(
                          Icons.refresh,
                          color: TBColors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showBalance = !_showBalance;
                          });
                        },
                        icon: Icon(
                          _showBalance ? Icons.visibility : Icons.visibility_off,
                          color: TBColors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: TBSpacing.lg),
            // Grid de acciones compacto
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              crossAxisSpacing: TBSpacing.xs,
              mainAxisSpacing: TBSpacing.sm,
              childAspectRatio: 0.7,
              children: [
                _buildActionItem(Icons.send, 'Enviar', _navigateToSend),
                _buildActionItem(Icons.add, 'Recargar', _navigateToRecharge),
                _buildActionItem(Icons.credit_card, 'Créditos', _navigateToCredits),
                _buildActionItem(Icons.qr_code, 'QR', _navigateToQR),
                _buildActionItem(Icons.receipt_long, 'Recibos', _navigateToReceipts),
              ],
            ),
            const SizedBox(height: TBSpacing.lg),
            // Header de transacciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Movimientos recientes',
                  style: TBTypography.titleLarge,
                ),
                TextButton(
                  onPressed: _navigateToReceipts,
                  child: Text(
                    'Ver todos',
                    style: TBTypography.labelMedium.copyWith(
                      color: TBColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TBSpacing.sm),
            // Transacciones reales del usuario
            BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoaded && state.transactions.isNotEmpty) {
                  final recentTransactions = state.transactions.take(3).toList();
                  return Column(
                    children: recentTransactions.map((transaction) {
                      final isIncome = transaction['type'] == 'INCOME';
                      final amount = (transaction['amount'] ?? 0.0).toDouble();
                      final description = transaction['description'] ?? 'Transacción';
                      
                      // Formatear fecha
                      String dateStr = 'Hoy';
                      try {
                        if (transaction['date'] != null) {
                          final date = DateTime.parse(transaction['date']);
                          final now = DateTime.now();
                          final diff = now.difference(date).inDays;
                          
                          if (diff == 0) {
                            dateStr = 'Hoy';
                          } else if (diff == 1) {
                            dateStr = 'Ayer';
                          } else if (diff < 7) {
                            dateStr = 'Hace $diff días';
                          } else {
                            dateStr = '${date.day}/${date.month}/${date.year}';
                          }
                        }
                      } catch (e) {
                        dateStr = 'Hoy';
                      }
                      
                      // Determinar icono y título según tipo de transacción
                      IconData icon = Icons.swap_horiz;
                      String title = description;
                      
                      if (description.toLowerCase().contains('recarga') || description.toLowerCase().contains('aprobada por administrador')) {
                        if (isIncome) {
                          icon = Icons.add_circle;
                          title = 'Recarga aprobada';
                        } else {
                          icon = Icons.send;
                          title = 'Envío de dinero';
                        }
                      } else if (description.toLowerCase().contains('envío')) {
                        icon = Icons.send;
                        title = 'Envío de dinero';
                      } else if (description.toLowerCase().contains('pago')) {
                        icon = Icons.payment;
                      } else {
                        icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: TBSpacing.sm),
                        child: _buildTransactionItem(
                          title,
                          dateStr,
                          amount.toStringAsFixed(2),
                          icon,
                          isIncome,
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  return Column(
                    children: [
                      _buildTransactionItem(
                        'Sin transacciones', 
                        'No hay movimientos recientes', 
                        '0.00', 
                        Icons.info_outline, 
                        false
                      ),
                    ],
                  );
                }
              },
            ),
              ],
            ),
          );
        },
      ),
        ),
      ),
    );
  }
}