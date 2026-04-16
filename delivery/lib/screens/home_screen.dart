import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';

/// Pantalla de inicio de la app.
/// Permite al usuario navegar a las diferentes secciones:
/// solicitar pedido, seguir pedido, ver historial, o iniciar sesión.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _telefonoController = TextEditingController();

  @override
  void dispose() {
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo / Header
              const Icon(
                Icons.delivery_dining,
                size: 80,
                color: AppTheme.accent,
              ),
              const SizedBox(height: 16),
              Text(
                'Domicilios',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu entrega, rápida y segura',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),

              // Solicitar pedido
              _HomeButton(
                icon: Icons.add_shopping_cart,
                label: 'Solicitar Pedido',
                subtitle: 'Sin registro, rápido y fácil',
                color: AppTheme.primary,
                onTap: () => context.go('/pedido'),
              ),
              const SizedBox(height: 16),

              // Teléfono para seguimiento/historial
              Card(
                color: AppTheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ya tienes un pedido?',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          hintText: 'Ingresa tu teléfono',
                          prefixIcon: Icon(Icons.phone),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.map, size: 18),
                              label: const Text('Seguimiento'),
                              onPressed: () {
                                final tel = _telefonoController.text.trim();
                                if (tel.isNotEmpty) {
                                  context.go('/seguimiento?telefono=$tel');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.history, size: 18),
                              label: const Text('Historial'),
                              onPressed: () {
                                final tel = _telefonoController.text.trim();
                                if (tel.isNotEmpty) {
                                  context.go('/historial?telefono=$tel');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Divider
              const Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.divider)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Repartidor o Admin',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.divider)),
                ],
              ),
              const SizedBox(height: 16),

              // Login
              _HomeButton(
                icon: Icons.login,
                label: 'Iniciar Sesión',
                subtitle: 'Repartidor o Administrador',
                color: AppTheme.surfaceVariant,
                onTap: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 36, color: AppTheme.textPrimary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppTheme.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
