import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../atoms/app_button.dart';
import '../../data/services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> _login() async {
    if (usernameController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final success = await ApiService.login(
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (mounted && success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Inversiones Olaya IO',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w200,
                    fontFamily: 'Dancing Script',
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                    letterSpacing: 3.0,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        offset: Offset(1.5, 1.5),
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Logo/Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 230,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Inicia sesión para continuar',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Username field
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Password field
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Login button
                AppButton(
                  text: isLoading ? 'Iniciando sesión...' : 'Iniciar Sesión',
                  onPressed: isLoading ? null : _login,
                ),
                
                const SizedBox(height: 24),
                
                // Default credentials info
                /*Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Credenciales por defecto:',
                        style: AppTextStyles.caption,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Usuario: admin (Administrador)',
                        style: AppTextStyles.body,
                      ),
                      Text(
                        'Contraseña: password123',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Usuario: viewer (Solo lectura)',
                        style: AppTextStyles.body,
                      ),
                      Text(
                        'Contraseña: password123',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),*/
              ],
            ),
          ),
        ),
      ),
    );
  }
}