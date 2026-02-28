import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'General',
            items: [
              _SettingsItem(
                icon: Icons.store,
                title: 'Información de la Tienda',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.receipt,
                title: 'Configuración de Recibos',
                onTap: () {},
              ),
            ],
          ),
          _SettingsSection(
            title: 'Cuenta',
            items: [
              _SettingsItem(
                icon: Icons.person,
                title: 'Perfil',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.lock,
                title: 'Cambiar Contraseña',
                onTap: () {},
              ),
            ],
          ),
          _SettingsSection(
            title: 'Datos',
            items: [
              _SettingsItem(
                icon: Icons.backup,
                title: 'Respaldo',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.restore,
                title: 'Restaurar',
                onTap: () {},
              ),
            ],
          ),
          _SettingsSection(
            title: 'Acerca de',
            items: [
              _SettingsItem(
                icon: Icons.info,
                title: 'Versión',
                trailing: Text('1.0.0', style: AppTextStyles.caption),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        ),
        ...items,
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.body),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
