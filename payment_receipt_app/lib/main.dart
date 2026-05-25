import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_system/colors/tb_colors.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/supervisor/screens/supervisor_panel_screen.dart';
import 'features/admin/leads/screens/leads_list_screen.dart';
import 'features/admin/leads/screens/leads_upload_screen.dart';
import 'features/admin/leads/screens/lead_detail_screen.dart';
import 'services/auth_service.dart';
import 'models/user_role.dart';
import 'core/utils/error_handler.dart';
import 'widgets/module_guard.dart';
import 'models/lead_model.dart';
import 'features/supervisor/widgets/lead_edit_form.dart';
import 'features/supervisor/bloc/supervisor_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  // Desactivar descarga de fuentes por HTTP (usar fuentes del sistema como fallback)
  GoogleFonts.config.allowRuntimeFetching = false;

  if (kIsWeb) {
    FlutterError.onError = ErrorHandler.handleFlutterError;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrustBank',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: TBColors.primary,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.data == true) {
            // Check user role to route supervisors to their panel
            return FutureBuilder<UserRole>(
              future: AuthService.getCurrentUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (roleSnapshot.data == UserRole.supervisor) {
                  return const SupervisorPanelScreen();
                }
                return const HomeScreen();
              },
            );
          } else {
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin/leads': (context) => const ModuleGuard(
          requiredModule: 'LEADS',
          child: LeadsListScreen(),
        ),
        '/admin/leads/upload': (context) => const ModuleGuard(
          requiredModule: 'LEADS',
          child: LeadsUploadScreen(),
        ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/admin/leads/detail') {
          final leadId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => ModuleGuard(
              requiredModule: 'LEADS',
              child: LeadDetailScreen(leadId: leadId),
            ),
          );
        }
        if (settings.name == '/supervisor/lead/edit') {
          final lead = settings.arguments as LeadModel;
          return MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => SupervisorBloc(),
              child: LeadEditForm(lead: lead),
            ),
          );
        }
        return null;
      },
    );
  }
}